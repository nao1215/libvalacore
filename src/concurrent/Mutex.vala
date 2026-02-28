namespace Vala.Concurrent {
    /**
     * Function delegate for withLock blocks.
     */
    public delegate void WithLockFunc ();

    /**
     * Mutex wrapper with utility methods.
     */
    public class Mutex : GLib.Object {
        private GLib.Mutex _mutex;

        /**
         * Acquires the mutex lock.
         */
        public void lock () {
            _mutex.lock ();
        }

        /**
         * Releases the mutex lock.
         */
        public void unlock () {
            _mutex.unlock ();
        }

        /**
         * Attempts to acquire the lock without blocking.
         *
         * @return true if lock is acquired.
         */
        public bool tryLock () {
            return _mutex.trylock ();
        }

        /**
         * Executes a function while holding the lock.
         *
         * @param func function to execute.
         */
        public void withLock (WithLockFunc func) {
            @lock ();
            try {
                func ();
            } finally {
                @unlock ();
            }
        }
    }
}
