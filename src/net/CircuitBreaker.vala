using Vala.Time;
using Vala.Collections;

namespace Vala.Net {
    /**
     * Recoverable circuit breaker configuration errors.
     */
    public errordomain CircuitBreakerError {
        INVALID_ARGUMENT
    }

    /**
     * Circuit breaker state.
     *
     * - CLOSED: requests pass through normally.
     * - OPEN: requests are short-circuited.
     * - HALF_OPEN: limited trial period before returning to CLOSED.
     */
    public enum CircuitState {
        CLOSED,
        OPEN,
        HALF_OPEN
    }

    /**
     * Callback invoked when breaker state changes.
     *
     * @param from previous state.
     * @param to next state.
     */
    public delegate void StateChangeCallback (CircuitState from, CircuitState to);

    /**
     * Callback executed through circuit breaker.
     *
     * Return Result.ok(...) to indicate success, Result.error(...) to
     * indicate failure.
     */
    public delegate Result<T, string> CircuitFunc<T> ();

    /**
     * Circuit breaker for protecting unstable dependencies.
     *
     * CircuitBreaker guards expensive or unreliable calls and prevents
     * cascading failures. After enough failures, it opens and rejects calls
     * immediately until timeout elapses.
     *
     * Example:
     * {{{
     *     var breaker = new CircuitBreaker ("payments")
     *         .withFailureThreshold (3)
     *         .withOpenTimeout (Duration.ofSeconds (10));
     *
     *     Result<string, string> result = breaker.call<string> (() => {
     *         string? payload = fetch_from_remote ();
     *         if (payload == null) {
     *             return Result.error<string, string> ("remote returned empty payload");
     *         }
     *         return Result.ok<string, string> (payload);
     *     });
     * }}}
     */
    public class CircuitBreaker : GLib.Object {
        private class Transition : GLib.Object {
            public CircuitState from;
            public CircuitState to;

            public Transition (CircuitState from, CircuitState to) {
                this.from = from;
                this.to = to;
            }
        }

        private string _name;
        private int _failure_threshold = 5;
        private int _success_threshold = 1;
        private int64 _open_timeout_millis = 30 * 1000;

        private CircuitState _state = CircuitState.CLOSED;
        private int _failure_count = 0;
        private int _half_open_success_count = 0;
        private int64 _opened_at_micros = 0;

        private StateChangeCallback ? _on_state_change = null;
        private GLib.Mutex _mutex;

        /**
         * Creates a circuit breaker.
         *
         * @param name breaker name.
         * @throws CircuitBreakerError.INVALID_ARGUMENT when name is empty.
         */
        public CircuitBreaker (string name) throws CircuitBreakerError {
            if (name.length == 0) {
                throw new CircuitBreakerError.INVALID_ARGUMENT ("name must not be empty");
            }
            _name = name;
        }

        /**
         * Sets consecutive failure threshold.
         *
         * Breaker transitions from CLOSED to OPEN when this threshold is
         * reached.
         *
         * @param n failure threshold.
         * @return this breaker.
         * @throws CircuitBreakerError.INVALID_ARGUMENT when n is not positive.
         */
        public CircuitBreaker withFailureThreshold (int n) throws CircuitBreakerError {
            if (n <= 0) {
                throw new CircuitBreakerError.INVALID_ARGUMENT ("n must be positive, got %d".printf (n));
            }
            _failure_threshold = n;
            return this;
        }

        /**
         * Sets success threshold needed to close from HALF_OPEN.
         *
         * In HALF_OPEN, this many consecutive successes are required to return
         * to CLOSED state.
         *
         * @param n success threshold.
         * @return this breaker.
         * @throws CircuitBreakerError.INVALID_ARGUMENT when n is not positive.
         */
        public CircuitBreaker withSuccessThreshold (int n) throws CircuitBreakerError {
            if (n <= 0) {
                throw new CircuitBreakerError.INVALID_ARGUMENT ("n must be positive, got %d".printf (n));
            }
            _success_threshold = n;
            return this;
        }

        /**
         * Sets OPEN-state timeout.
         *
         * If timeout is zero, OPEN transitions to HALF_OPEN on next state
         * check.
         *
         * @param timeout open timeout.
         * @return this breaker.
         * @throws CircuitBreakerError.INVALID_ARGUMENT when timeout is negative.
         */
        public CircuitBreaker withOpenTimeout (Duration timeout) throws CircuitBreakerError {
            int64 millis = timeout.toMillis ();
            if (millis < 0) {
                throw new CircuitBreakerError.INVALID_ARGUMENT (
                          "timeout must be non-negative, got " + millis.to_string ()
                );
            }
            _open_timeout_millis = millis;
            return this;
        }

        /**
         * Registers state change callback.
         *
         * This hook is useful for metrics and operational logs.
         *
         * @param fn callback.
         * @return this breaker.
         */
        public CircuitBreaker onStateChange (owned StateChangeCallback fn) {
            _on_state_change = (owned) fn;
            return this;
        }

        /**
         * Executes callback through circuit breaker.
         *
         * If breaker is OPEN, callback is not executed and Result.error(...)
         * is returned. Callback must explicitly return Result.ok(...) or
         * Result.error(...), and breaker updates counters based on result
         * state.
         *
         * @param fn callback to execute.
         * @return callback Result, or error Result when short-circuited.
         */
        public Result<T, string> call<T> (owned CircuitFunc<T> fn) {
            var transitions = new GLib.Queue<Transition> ();
            _mutex.lock ();
            refreshStateLocked (transitions);
            if (_state == CircuitState.OPEN) {
                _mutex.unlock ();
                notifyTransitions (transitions);
                return Result.error<T, string> ("circuit breaker is open: " + _name);
            }
            _mutex.unlock ();
            notifyTransitions (transitions);

            Result<T, string> result = fn ();
            if (result == null) {
                recordFailure ();
                return Result.error<T, string> ("circuit callback returned null Result");
            }

            if (result.isError ()) {
                recordFailure ();
                return result;
            }

            recordSuccess ();
            return result;
        }

        /**
         * Records one failure.
         *
         * This API can be used when call execution is handled externally and
         * only outcome needs to be reported to breaker.
         */
        public void recordFailure () {
            var transitions = new GLib.Queue<Transition> ();
            _mutex.lock ();
            refreshStateLocked (transitions);

            if (_state == CircuitState.HALF_OPEN) {
                transitionLocked (CircuitState.OPEN, transitions);
                _failure_count = 0;
                _half_open_success_count = 0;
                _opened_at_micros = nowMicros ();
                _mutex.unlock ();
                notifyTransitions (transitions);
                return;
            }

            if (_state == CircuitState.OPEN) {
                _mutex.unlock ();
                notifyTransitions (transitions);
                return;
            }

            _failure_count++;
            if (_failure_count >= _failure_threshold) {
                transitionLocked (CircuitState.OPEN, transitions);
                _failure_count = 0;
                _half_open_success_count = 0;
                _opened_at_micros = nowMicros ();
            }
            _mutex.unlock ();
            notifyTransitions (transitions);
        }

        /**
         * Records one success.
         *
         * This API can be used when call execution is handled externally and
         * only outcome needs to be reported to breaker.
         */
        public void recordSuccess () {
            var transitions = new GLib.Queue<Transition> ();
            _mutex.lock ();
            refreshStateLocked (transitions);

            if (_state == CircuitState.HALF_OPEN) {
                _half_open_success_count++;
                if (_half_open_success_count >= _success_threshold) {
                    transitionLocked (CircuitState.CLOSED, transitions);
                    _failure_count = 0;
                    _half_open_success_count = 0;
                    _opened_at_micros = 0;
                }
                _mutex.unlock ();
                notifyTransitions (transitions);
                return;
            }

            if (_state == CircuitState.CLOSED) {
                _failure_count = 0;
            }
            _mutex.unlock ();
            notifyTransitions (transitions);
        }

        /**
         * Returns current state.
         *
         * state() refreshes timeout-based transitions before returning.
         *
         * @return current state.
         */
        public CircuitState state () {
            var transitions = new GLib.Queue<Transition> ();
            _mutex.lock ();
            refreshStateLocked (transitions);
            CircuitState current = _state;
            _mutex.unlock ();
            notifyTransitions (transitions);
            return current;
        }

        /**
         * Returns recent failure count in CLOSED state.
         *
         * The counter is reset on successful calls in CLOSED state.
         *
         * @return failure count.
         */
        public int failureCount () {
            _mutex.lock ();
            int count = _failure_count;
            _mutex.unlock ();
            return count;
        }

        /**
         * Resets breaker state and counters.
         *
         * After reset, state is CLOSED and all counters are zero.
         */
        public void reset () {
            var transitions = new GLib.Queue<Transition> ();
            _mutex.lock ();
            transitionLocked (CircuitState.CLOSED, transitions);
            _failure_count = 0;
            _half_open_success_count = 0;
            _opened_at_micros = 0;
            _mutex.unlock ();
            notifyTransitions (transitions);
        }

        /**
         * Returns breaker name.
         *
         * @return breaker name.
         */
        public string name () {
            return _name;
        }

        private void refreshStateLocked (GLib.Queue<Transition> transitions) {
            if (_state != CircuitState.OPEN) {
                return;
            }

            if (_open_timeout_millis == 0) {
                transitionLocked (CircuitState.HALF_OPEN, transitions);
                _half_open_success_count = 0;
                return;
            }

            int64 elapsed_millis = (nowMicros () - _opened_at_micros) / 1000;
            if (elapsed_millis >= _open_timeout_millis) {
                transitionLocked (CircuitState.HALF_OPEN, transitions);
                _half_open_success_count = 0;
            }
        }

        private void transitionLocked (CircuitState next, GLib.Queue<Transition> transitions) {
            if (_state == next) {
                return;
            }

            CircuitState previous = _state;
            _state = next;
            transitions.push_tail (new Transition (previous, next));
        }

        private void notifyTransitions (GLib.Queue<Transition> transitions) {
            if (_on_state_change == null) {
                return;
            }

            while (!transitions.is_empty ()) {
                Transition transition = transitions.pop_head ();
                _on_state_change (transition.from, transition.to);
            }
        }

        private static int64 nowMicros () {
            return GLib.get_monotonic_time ();
        }
    }
}
