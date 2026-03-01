using Vala.Lang;

namespace Vala.Net {
    /**
     * Recoverable rate limiter operation errors.
     */
    public errordomain RateLimiterError {
        INVALID_ARGUMENT
    }

    /**
     * Thread-safe token-bucket rate limiter.
     *
     * RateLimiter is useful for protecting downstream services or local
     * resources from request spikes. It provides both non-blocking
     * (allow/allowN) and blocking (wait/waitN) acquisition APIs.
     *
     * Example:
     * {{{
     *     var limiter = new RateLimiter (100).withBurst (200);
     *
     *     if (limiter.allow ()) {
     *         send_request ();
     *     }
     * }}}
     */
    public class RateLimiter : GLib.Object {
        private int _permits_per_second;
        private int _burst;
        private double _tokens;
        private int64 _last_refill_micros;
        private GLib.Mutex _mutex;

        /**
         * Creates a new rate limiter.
         *
         * Initial burst capacity equals permitsPerSecond.
         *
         * @param permitsPerSecond permits generated per second.
         * @throws RateLimiterError.INVALID_ARGUMENT when permitsPerSecond is not positive.
         */
        public RateLimiter (int permitsPerSecond) throws RateLimiterError {
            if (permitsPerSecond <= 0) {
                throw new RateLimiterError.INVALID_ARGUMENT (
                          "permitsPerSecond must be positive, got %d".printf (permitsPerSecond)
                );
            }

            _permits_per_second = permitsPerSecond;
            _burst = permitsPerSecond;
            _tokens = _burst;
            _last_refill_micros = nowMicros ();
        }

        /**
         * Sets burst capacity.
         *
         * Burst controls how many permits may be consumed instantly after an
         * idle period.
         *
         * @param permits burst capacity.
         * @return this limiter.
         * @throws RateLimiterError.INVALID_ARGUMENT when permits is not positive.
         */
        public RateLimiter withBurst (int permits) throws RateLimiterError {
            if (permits <= 0) {
                throw new RateLimiterError.INVALID_ARGUMENT (
                          "permits must be positive, got %d".printf (permits)
                );
            }

            _mutex.lock ();
            refillLocked ();
            _burst = permits;
            if (_tokens > _burst) {
                _tokens = _burst;
            }
            _mutex.unlock ();
            return this;
        }

        /**
         * Tries to acquire one permit immediately.
         *
         * This method never blocks.
         *
         * @return true if permit acquired.
         */
        public bool allow () {
            _mutex.lock ();
            refillLocked ();
            if (_tokens >= 1) {
                _tokens -= 1;
                _mutex.unlock ();
                return true;
            }
            _mutex.unlock ();
            return false;
        }

        /**
         * Tries to acquire n permits immediately.
         *
         * This method never blocks.
         *
         * @param permits number of permits.
         * @return true if permits acquired.
         * @throws RateLimiterError.INVALID_ARGUMENT when permits is not positive.
         */
        public bool allowN (int permits) throws RateLimiterError {
            if (permits <= 0) {
                throw new RateLimiterError.INVALID_ARGUMENT (
                          "permits must be positive, got %d".printf (permits)
                );
            }

            _mutex.lock ();
            refillLocked ();
            if (_tokens >= permits) {
                _tokens -= permits;
                _mutex.unlock ();
                return true;
            }
            _mutex.unlock ();
            return false;
        }

        /**
         * Waits until one permit is available and acquires it.
         *
         * Use this when work must eventually run and short waiting is
         * acceptable.
         */
        public void wait () {
            while (true) {
                int64 delay = 0;

                _mutex.lock ();
                refillLocked ();
                if (_tokens >= 1) {
                    _tokens -= 1;
                    _mutex.unlock ();
                    return;
                }

                delay = waitMillisLocked (1);
                _mutex.unlock ();

                if (delay > 0) {
                    int sleep_millis = delay > int.MAX ? int.MAX : (int) delay;
                    Threads.sleepMillis (sleep_millis);
                }
            }
        }

        /**
         * Waits until n permits are available and acquires them.
         *
         * This method blocks the caller thread until enough permits are
         * available.
         *
         * @param permits number of permits.
         * @throws RateLimiterError.INVALID_ARGUMENT when permits is not positive.
         */
        public void waitN (int permits) throws RateLimiterError {
            if (permits <= 0) {
                throw new RateLimiterError.INVALID_ARGUMENT (
                          "permits must be positive, got %d".printf (permits)
                );
            }

            while (true) {
                int64 delay = 0;

                _mutex.lock ();
                refillLocked ();
                if (_tokens >= permits) {
                    _tokens -= permits;
                    _mutex.unlock ();
                    return;
                }

                delay = waitMillisLocked (permits);
                _mutex.unlock ();

                if (delay > 0) {
                    int sleep_millis = delay > int.MAX ? int.MAX : (int) delay;
                    Threads.sleepMillis (sleep_millis);
                }
            }
        }

        /**
         * Returns estimated wait milliseconds until one permit becomes available.
         *
         * reserve() does not consume permits.
         *
         * @return estimated wait time in milliseconds.
         */
        public int64 reserve () {
            _mutex.lock ();
            refillLocked ();
            int64 wait = waitMillisLocked (1);
            _mutex.unlock ();
            return wait;
        }

        /**
         * Returns currently available permits (floored).
         *
         * The value is an instantaneous snapshot and may change immediately in
         * concurrent environments.
         *
         * @return available permit count.
         */
        public int availableTokens () {
            _mutex.lock ();
            refillLocked ();
            int available = (int) _tokens;
            _mutex.unlock ();
            return available;
        }

        /**
         * Updates rate.
         *
         * Existing token balance is preserved and clamped by burst rules.
         * When the new rate is higher than current burst, burst is raised to
         * the new rate. setRate() never decreases burst; use withBurst() when
         * explicitly lowering burst capacity is required.
         *
         * @param permitsPerSecond permits generated per second.
         * @throws RateLimiterError.INVALID_ARGUMENT when permitsPerSecond is not positive.
         */
        public void setRate (int permitsPerSecond) throws RateLimiterError {
            if (permitsPerSecond <= 0) {
                throw new RateLimiterError.INVALID_ARGUMENT (
                          "permitsPerSecond must be positive, got %d".printf (permitsPerSecond)
                );
            }

            _mutex.lock ();
            refillLocked ();
            _permits_per_second = permitsPerSecond;
            if (_burst < permitsPerSecond) {
                _burst = permitsPerSecond;
            }
            _mutex.unlock ();
        }

        /**
         * Resets current tokens to burst capacity.
         *
         * reset() is useful in tests and controlled maintenance operations.
         */
        public void reset () {
            _mutex.lock ();
            _tokens = _burst;
            _last_refill_micros = nowMicros ();
            _mutex.unlock ();
        }

        private void refillLocked () {
            int64 now = nowMicros ();
            if (now <= _last_refill_micros) {
                return;
            }

            int64 elapsed = now - _last_refill_micros;
            double gained = ((double) elapsed / 1000000.0) * _permits_per_second;
            _tokens += gained;
            if (_tokens > _burst) {
                _tokens = _burst;
            }
            _last_refill_micros = now;
        }

        private int64 waitMillisLocked (int permits) {
            if (_tokens >= permits) {
                return 0;
            }

            double missing = permits - _tokens;
            double wait_millis = (missing / _permits_per_second) * 1000.0;
            int64 millis = (int64) GLib.Math.ceil (wait_millis);
            if (millis < 1) {
                return 1;
            }
            return millis;
        }

        private static int64 nowMicros () {
            return GLib.get_monotonic_time ();
        }
    }
}
