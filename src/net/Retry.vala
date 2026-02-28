using Vala.Time;
using Vala.Lang;
using Vala.Collections;

namespace Vala.Net {
    /**
     * Callback invoked by retry loop and interpreted as success/failure.
     *
     * Return true to stop retrying immediately.
     */
    public delegate bool RetryFunc ();

    /**
     * Callback invoked by retry loop and interpreted as nullable result.
     *
     * Return a non-null value to stop retrying and use it as final result.
     */
    public delegate T ? RetryResultFunc<T> ();

    /**
     * Callback invoked by retry loop that may throw recoverable GLib.Error.
     *
     * Throwing an error is treated as a retryable failure unless predicate
     * configured by withRetryOn() rejects it.
     */
    public delegate void RetryVoidFunc () throws GLib.Error;

    /**
     * Predicate used to decide whether retry should continue.
     *
     * @param reason textual failure reason captured by Retry.
     * @return true to continue retrying, false to stop immediately.
     */
    public delegate bool RetryOnFunc (string reason);

    /**
     * Callback invoked before sleeping for the next retry attempt.
     *
     * @param attempt current attempt number (1-based).
     * @param reason failure reason observed at this attempt.
     * @param delayMillis delay before next attempt in milliseconds.
     */
    public delegate void RetryCallback (int attempt, string reason, int64 delayMillis);

    private enum RetryBackoffMode {
        FIXED,
        EXPONENTIAL
    }

    /**
     * Retry policy for resilient operations such as HTTP calls or lock
     * acquisition.
     *
     * This class encapsulates:
     * - maximum attempts
     * - delay strategy (fixed or exponential backoff)
     * - optional jitter
     * - retry predicate and callback hooks
     *
     * Example:
     * {{{
     *     Retry retry = Retry.networkDefault ()
     *         .withMaxAttempts (3)
     *         .onRetry ((attempt, reason, delay) => {
     *             print ("retry %d: %s (%" + int64.FORMAT + "ms)\n", attempt, reason, delay);
     *         });
     *
     *     bool ok = retry.retry (() => {
     *         return call_external_service ();
     *     });
     * }}}
     */
    public class Retry : GLib.Object {
        private const int DEFAULT_MAX_ATTEMPTS = 3;
        private const int64 DEFAULT_DELAY_MILLIS = 1000;
        private const int64 DEFAULT_MAX_DELAY_MILLIS = 30 * 1000;

        private int _max_attempts = DEFAULT_MAX_ATTEMPTS;
        private int64 _initial_delay_millis = DEFAULT_DELAY_MILLIS;
        private int64 _max_delay_millis = DEFAULT_MAX_DELAY_MILLIS;
        private bool _jitter_enabled = false;
        private RetryBackoffMode _backoff_mode = RetryBackoffMode.EXPONENTIAL;

        private RetryOnFunc _retry_on = (reason) => {
            return true;
        };

        private RetryCallback ? _on_retry = null;

        /**
         * Creates retry policy with conservative default settings.
         *
         * Defaults:
         * - max attempts: 3
         * - backoff: exponential
         * - initial delay: 1000ms
         * - max delay: 30000ms
         * - jitter: disabled
         */
        public Retry () {
        }

        /**
         * Creates recommended retry policy for network operations.
         *
         * This preset is tuned for transient network failures and rate-limit
         * responses. It uses exponential backoff and jitter to reduce
         * synchronized retries.
         *
         * Example:
         * {{{
         *     Retry retry = Retry.networkDefault ();
         * }}}
         *
         * @return configured retry policy.
         */
        public static Retry networkDefault () {
            return new Retry ().withMaxAttempts (5)
                    .withBackoff (Duration.ofSeconds (1), Duration.ofSeconds (30))
                    .withJitter (true);
        }

        /**
         * Creates recommended retry policy for short I/O lock/contention cases.
         *
         * Example:
         * {{{
         *     Retry retry = Retry.ioDefault ();
         * }}}
         *
         * @return configured retry policy.
         */
        public static Retry ioDefault () {
            return new Retry ().withMaxAttempts (6)
                    .withFixedDelay (Duration.ofSeconds (1));
        }

        /**
         * Sets maximum attempts.
         *
         * The first execution counts as attempt 1.
         *
         * @param n maximum attempts (must be positive).
         * @return this retry instance.
         */
        public Retry withMaxAttempts (int n) {
            if (n <= 0) {
                error ("n must be positive, got %d", n);
            }
            _max_attempts = n;
            return this;
        }

        /**
         * Sets exponential backoff strategy.
         *
         * Delay sequence grows as initial, 2*initial, 4*initial, ... and is
         * capped by max.
         *
         * @param initial initial delay.
         * @param max maximum delay cap.
         * @return this retry instance.
         */
        public Retry withBackoff (Duration initial, Duration max) {
            int64 initial_millis = initial.toMillis ();
            int64 max_millis = max.toMillis ();

            if (initial_millis < 0) {
                error ("initial must be non-negative, got %" + int64.FORMAT, initial_millis);
            }
            if (max_millis < 0) {
                error ("max must be non-negative, got %" + int64.FORMAT, max_millis);
            }
            if (max_millis < initial_millis) {
                error ("max must be greater than or equal to initial");
            }

            _backoff_mode = RetryBackoffMode.EXPONENTIAL;
            _initial_delay_millis = initial_millis;
            _max_delay_millis = max_millis;
            return this;
        }

        /**
         * Sets fixed delay strategy.
         *
         * All retries use the same sleep duration.
         *
         * @param delay fixed delay between attempts.
         * @return this retry instance.
         */
        public Retry withFixedDelay (Duration delay) {
            int64 delay_millis = delay.toMillis ();
            if (delay_millis < 0) {
                error ("delay must be non-negative, got %" + int64.FORMAT, delay_millis);
            }

            _backoff_mode = RetryBackoffMode.FIXED;
            _initial_delay_millis = delay_millis;
            _max_delay_millis = delay_millis;
            return this;
        }

        /**
         * Enables or disables random jitter.
         *
         * When enabled, actual delay is randomized between 0 and calculated
         * delay (inclusive), reducing retry bursts under high concurrency.
         *
         * @param enabled true to enable jitter.
         * @return this retry instance.
         */
        public Retry withJitter (bool enabled) {
            _jitter_enabled = enabled;
            return this;
        }

        /**
         * Sets retry predicate for failure reason text.
         *
         * If predicate returns false, retry loop ends immediately.
         *
         * @param shouldRetry predicate to decide whether retry continues.
         * @return this retry instance.
         */
        public Retry withRetryOn (owned RetryOnFunc shouldRetry) {
            _retry_on = (owned) shouldRetry;
            return this;
        }

        /**
         * Registers callback called before sleeping for next attempt.
         *
         * This callback is useful for metrics, structured logs, and tracing.
         *
         * @param fn callback with attempt number, reason, and next delay millis.
         * @return this retry instance.
         */
        public Retry onRetry (owned RetryCallback fn) {
            _on_retry = (owned) fn;
            return this;
        }

        /**
         * Configures retry predicate from HTTP status code list.
         *
         * The failure reason passed to retry operations is scanned for 3-digit
         * HTTP status code patterns and retried only when matched.
         *
         * @param statusCodes retryable status codes.
         * @return this retry instance.
         */
        public Retry httpStatusRetry (ArrayList<int> statusCodes) {
            _retry_on = (reason) => {
                int code = extractHttpStatusCode (reason);
                if (code < 0) {
                    return false;
                }
                for (int i = 0; i < statusCodes.size (); i++) {
                    if (statusCodes.get (i) == code) {
                        return true;
                    }
                }
                return false;
            };
            return this;
        }

        /**
         * Retries bool callback until success or attempts exhausted.
         *
         * Example:
         * {{{
         *     bool ok = retry.retry (() => {
         *         return attempt_io_operation ();
         *     });
         * }}}
         *
         * @param fn callback to run.
         * @return true if callback succeeded.
         */
        public bool retry (owned RetryFunc fn) {
            for (int attempt = 1; attempt <= _max_attempts; attempt++) {
                if (fn ()) {
                    return true;
                }

                if (!shouldContinue (attempt, "false")) {
                    return false;
                }
            }
            return false;
        }

        /**
         * Retries nullable callback until non-null value or attempts exhausted.
         *
         * Example:
         * {{{
         *     string? token = retry.retryResult<string?> (() => {
         *         return maybe_fetch_token ();
         *     });
         * }}}
         *
         * @param fn callback to run.
         * @return non-null value on success, null on failure.
         */
        public T ? retryResult<T> (owned RetryResultFunc<T> fn) {
            for (int attempt = 1; attempt <= _max_attempts; attempt++) {
                T ? result = fn ();
                if (result != null) {
                    return result;
                }

                if (!shouldContinue (attempt, "null")) {
                    return null;
                }
            }
            return null;
        }

        /**
         * Retries callback that may throw GLib.Error.
         *
         * Example:
         * {{{
         *     bool ok = retry.retryVoid (() => {
         *         do_operation_that_may_throw ();
         *     });
         * }}}
         *
         * @param fn callback to run.
         * @return true if callback finished without error.
         */
        public bool retryVoid (owned RetryVoidFunc fn) {
            for (int attempt = 1; attempt <= _max_attempts; attempt++) {
                try {
                    fn ();
                    return true;
                } catch (GLib.Error e) {
                    if (!shouldContinue (attempt, e.message)) {
                        return false;
                    }
                }
            }
            return false;
        }

        private bool shouldContinue (int attempt, string reason) {
            if (attempt >= _max_attempts) {
                return false;
            }
            if (!_retry_on (reason)) {
                return false;
            }

            int64 delay = nextDelayMillis (attempt);
            if (_on_retry != null) {
                _on_retry (attempt, reason, delay);
            }
            sleepMillis (delay);
            return true;
        }

        private int64 nextDelayMillis (int attempt) {
            int64 delay = _initial_delay_millis;

            if (_backoff_mode == RetryBackoffMode.EXPONENTIAL && attempt > 1) {
                for (int i = 1; i < attempt; i++) {
                    if (delay > int64.MAX / 2) {
                        delay = int64.MAX;
                        break;
                    }
                    delay *= 2;
                }
            }

            if (_max_delay_millis > 0 && delay > _max_delay_millis) {
                delay = _max_delay_millis;
            }

            if (_jitter_enabled && delay > 1) {
                int upper = delay > int.MAX ? int.MAX : (int) delay;
                delay = GLib.Random.int_range (0, upper + 1);
            }

            return delay;
        }

        private static void sleepMillis (int64 millis) {
            if (millis <= 0) {
                return;
            }
            int sleep_millis = millis > int.MAX ? int.MAX : (int) millis;
            Threads.sleepMillis (sleep_millis);
        }

        private static int extractHttpStatusCode (string reason) {
            for (int i = 0; i + 2 < reason.length; i++) {
                if (!isDigit (reason.get_char (i)) ||
                    !isDigit (reason.get_char (i + 1)) ||
                    !isDigit (reason.get_char (i + 2))) {
                    continue;
                }

                int code = 0;
                for (int j = 0; j < 3; j++) {
                    code *= 10;
                    code += (int) (reason.get_char (i + j) - '0');
                }

                if (code >= 100 && code <= 599) {
                    return code;
                }
            }
            return -1;
        }

        private static bool isDigit (unichar c) {
            return c >= '0' && c <= '9';
        }
    }
}
