namespace Vala.Concurrent {
    /**
     * Recoverable semaphore configuration errors.
     */
    public errordomain SemaphoreError {
        INVALID_ARGUMENT
    }

    /**
     * Counting semaphore.
     *
     * Semaphore controls concurrent access with permit counters. acquire()
     * blocks when no permits are available; release() returns a permit.
     *
     * Example:
     * {{{
     *     var created = Semaphore.of (3);
     *     if (created.isError ()) {
     *         return;
     *     }
     *     var sem = created.unwrap ();
     *     sem.acquire ();
     *     try {
     *         // bounded concurrency section
     *     } finally {
     *         sem.release ();
     *     }
     * }}}
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
        private Semaphore (int permits) {
            _permits = permits;
        }

        /**
         * Creates semaphore with initial permits.
         *
         * @param permits initial permit count.
         * @return Result.ok(semaphore), or
         *         Result.error(SemaphoreError.INVALID_ARGUMENT) when permits is negative.
         */
        public static Vala.Collections.Result<Semaphore, GLib.Error> of (int permits) {
            if (permits < 0) {
                return Vala.Collections.Result.error<Semaphore, GLib.Error> (
                    new SemaphoreError.INVALID_ARGUMENT ("permits must be non-negative")
                );
            }
            return Vala.Collections.Result.ok<Semaphore, GLib.Error> (new Semaphore (permits));
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
