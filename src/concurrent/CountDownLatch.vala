namespace Vala.Concurrent {
    /**
     * Countdown latch for one-shot synchronization.
     */
    public class CountDownLatch : GLib.Object {
        private GLib.Mutex _mutex;
        private GLib.Cond _cond;
        private int _count;

        /**
         * Creates latch with initial count.
         *
         * @param count initial count.
         */
        public CountDownLatch (int count) {
            if (count < 0) {
                error ("count must be non-negative");
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
