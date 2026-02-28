using Vala.Time;
using Vala.Lang;
using Vala.Collections;

namespace Vala.Net {
    /**
     * Callback for retry loop that returns success/failure.
     */
    public delegate bool RetryFunc ();

    /**
     * Callback for retry loop that returns nullable result.
     */
    public delegate T ? RetryResultFunc<T> ();

    /**
     * Callback for retry loop that may throw recoverable GLib.Error.
     */
    public delegate void RetryVoidFunc () throws GLib.Error;

    /**
     * Predicate to decide whether retry should continue for a failure reason.
     */
    public delegate bool RetryOnFunc (string reason);

    /**
     * Callback invoked before waiting for next retry.
     */
    public delegate void RetryCallback (int attempt, string reason, int64 delayMillis);

    private enum RetryBackoffMode {
        FIXED,
        EXPONENTIAL
    }

    /**
     * Retry policy with configurable attempts, delay strategy, and retry predicate.
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
         * Creates retry policy with default settings.
         */
        public Retry () {
        }

        /**
         * Creates recommended retry policy for network operations.
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
         * @return configured retry policy.
         */
        public static Retry ioDefault () {
            return new Retry ().withMaxAttempts (6)
                    .withFixedDelay (Duration.ofSeconds (1));
        }

        /**
         * Sets maximum attempts.
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
