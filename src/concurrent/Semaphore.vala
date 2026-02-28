namespace Vala.Concurrent {
    /**
     * Counting semaphore.
     */
    public class Semaphore : GLib.Object {
        private GLib.Mutex _mutex;
        private GLib.Cond _cond;
        private int _permits;

        /**
         * Creates semaphore with initial permits.
         *
         * @param permits initial permit count.
         */
        public Semaphore (int permits) {
            if (permits < 0) {
                error ("permits must be non-negative");
            }
            _permits = permits;
        }

        /**
         * Acquires a permit, blocking until available.
         */
        public void acquire () {
            _mutex.lock ();
            while (_permits == 0) {
                _cond.wait (_mutex);
            }
            _permits--;
            _mutex.unlock ();
        }

        /**
         * Tries to acquire permit without blocking.
         *
         * @return true if acquired.
         */
        public bool tryAcquire () {
            _mutex.lock ();
            if (_permits == 0) {
                _mutex.unlock ();
                return false;
            }

            _permits--;
            _mutex.unlock ();
            return true;
        }

        /**
         * Releases a permit.
         */
        public void release () {
            _mutex.lock ();
            _permits++;
            _cond.signal ();
            _mutex.unlock ();
        }

        /**
         * Returns currently available permits.
         *
         * @return available permit count.
         */
        public int availablePermits () {
            _mutex.lock ();
            int permits = _permits;
            _mutex.unlock ();
            return permits;
        }
    }
}
