using Vala.Time;

namespace Vala.Net {
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
     * Return null to indicate failure, non-null to indicate success.
     */
    public delegate T ? CircuitFunc<T> ();

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
     *     string? result = breaker.call<string> (() => {
     *         return fetch_from_remote ();
     *     });
     * }}}
     */
    public class CircuitBreaker : GLib.Object {
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
         */
        public CircuitBreaker (string name) {
            if (name.length == 0) {
                error ("name must not be empty");
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
         */
        public CircuitBreaker withFailureThreshold (int n) {
            if (n <= 0) {
                error ("n must be positive, got %d", n);
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
         */
        public CircuitBreaker withSuccessThreshold (int n) {
            if (n <= 0) {
                error ("n must be positive, got %d", n);
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
         */
        public CircuitBreaker withOpenTimeout (Duration timeout) {
            int64 millis = timeout.toMillis ();
            if (millis < 0) {
                error ("timeout must be non-negative, got %" + int64.FORMAT, millis);
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
         * If breaker is OPEN, callback is not executed and null is returned.
         * On non-null callback result, breaker records success; on null
         * callback result, breaker records failure.
         *
         * @param fn callback to execute.
         * @return callback result or null when short-circuited/failed.
         */
        public T ? call<T> (owned CircuitFunc<T> fn) {
            _mutex.lock ();
            refreshStateLocked ();
            if (_state == CircuitState.OPEN) {
                _mutex.unlock ();
                return null;
            }
            _mutex.unlock ();

            T ? result = fn ();
            if (result == null) {
                recordFailure ();
                return null;
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
            _mutex.lock ();
            refreshStateLocked ();

            if (_state == CircuitState.HALF_OPEN) {
                transitionLocked (CircuitState.OPEN);
                _failure_count = 0;
                _half_open_success_count = 0;
                _opened_at_micros = nowMicros ();
                _mutex.unlock ();
                return;
            }

            if (_state == CircuitState.OPEN) {
                _mutex.unlock ();
                return;
            }

            _failure_count++;
            if (_failure_count >= _failure_threshold) {
                transitionLocked (CircuitState.OPEN);
                _failure_count = 0;
                _half_open_success_count = 0;
                _opened_at_micros = nowMicros ();
            }
            _mutex.unlock ();
        }

        /**
         * Records one success.
         *
         * This API can be used when call execution is handled externally and
         * only outcome needs to be reported to breaker.
         */
        public void recordSuccess () {
            _mutex.lock ();
            refreshStateLocked ();

            if (_state == CircuitState.HALF_OPEN) {
                _half_open_success_count++;
                if (_half_open_success_count >= _success_threshold) {
                    transitionLocked (CircuitState.CLOSED);
                    _failure_count = 0;
                    _half_open_success_count = 0;
                    _opened_at_micros = 0;
                }
                _mutex.unlock ();
                return;
            }

            if (_state == CircuitState.CLOSED) {
                _failure_count = 0;
            }
            _mutex.unlock ();
        }

        /**
         * Returns current state.
         *
         * state() refreshes timeout-based transitions before returning.
         *
         * @return current state.
         */
        public CircuitState state () {
            _mutex.lock ();
            refreshStateLocked ();
            CircuitState current = _state;
            _mutex.unlock ();
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
            _mutex.lock ();
            transitionLocked (CircuitState.CLOSED);
            _failure_count = 0;
            _half_open_success_count = 0;
            _opened_at_micros = 0;
            _mutex.unlock ();
        }

        /**
         * Returns breaker name.
         *
         * @return breaker name.
         */
        public string name () {
            return _name;
        }

        private void refreshStateLocked () {
            if (_state != CircuitState.OPEN) {
                return;
            }

            if (_open_timeout_millis == 0) {
                transitionLocked (CircuitState.HALF_OPEN);
                _half_open_success_count = 0;
                return;
            }

            int64 elapsed_millis = (nowMicros () - _opened_at_micros) / 1000;
            if (elapsed_millis >= _open_timeout_millis) {
                transitionLocked (CircuitState.HALF_OPEN);
                _half_open_success_count = 0;
            }
        }

        private void transitionLocked (CircuitState next) {
            if (_state == next) {
                return;
            }

            CircuitState previous = _state;
            _state = next;
            if (_on_state_change != null) {
                _on_state_change (previous, next);
            }
        }

        private static int64 nowMicros () {
            return GLib.get_monotonic_time ();
        }
    }
}
