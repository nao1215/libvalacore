namespace Vala.Concurrent {
    /**
     * Recoverable countdown latch configuration errors.
     */
    public errordomain CountDownLatchError {
        INVALID_ARGUMENT
    }

    /**
     * Countdown latch for one-shot synchronization.
     *
     * CountDownLatch starts with a fixed counter. Worker threads call
     * countDown(), and waiting thread(s) block in await() until the counter
     * reaches zero.
     *
     * Example:
     * {{{
     *     var latch = new CountDownLatch (2);
     *     // Two workers call latch.countDown()
     *     latch.@await ();
     * }}}
     */
    public class CountDownLatch : GLib.Object {
        private GLib.Mutex _mutex;
        private GLib.Cond _cond;
        private int _count;

        /**
         * Creates latch with initial count.
         *
         * @param count initial count.
         * @throws CountDownLatchError.INVALID_ARGUMENT when count is negative.
         */
        public CountDownLatch (int count) throws CountDownLatchError {
            if (count < 0) {
                throw new CountDownLatchError.INVALID_ARGUMENT ("count must be non-negative");
            }
            _count = count;
        }

        /**
         * Decrements count by one.
         */
        public void countDown () {
            _mutex.lock ();

            if (_count > 0) {
                _count--;
                if (_count == 0) {
                    _cond.broadcast ();
                }
            }

            _mutex.unlock ();
        }

        /**
         * Blocks until count reaches zero.
         */
        public void @await () {
            _mutex.lock ();
            while (_count > 0) {
                _cond.wait (_mutex);
            }
            _mutex.unlock ();
        }

        /**
         * Blocks until count reaches zero or timeout.
         *
         * @param timeout timeout duration.
         * @return true if reached zero, false on timeout.
         */
        public bool awaitTimeout (Vala.Time.Duration timeout) {
            int64 deadline = GLib.get_monotonic_time () + timeout.toMillis () * 1000;

            _mutex.lock ();
            while (_count > 0) {
                if (!_cond.wait_until (_mutex, deadline)) {
                    _mutex.unlock ();
                    return false;
                }
            }
            _mutex.unlock ();
            return true;
        }

        /**
         * Returns current count.
         *
         * @return count value.
         */
        public int getCount () {
            _mutex.lock ();
            int count = _count;
            _mutex.unlock ();
            return count;
        }
    }
}
