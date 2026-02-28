namespace Vala.Concurrent {
    /**
     * Reader-writer mutex.
     */
    public class RWMutex : GLib.Object {
        private GLib.RWLock _lock;

        /**
         * Acquires read lock.
         */
        public void readLock () {
            _lock.reader_lock ();
        }

        /**
         * Releases read lock.
         */
        public void readUnlock () {
            _lock.reader_unlock ();
        }

        /**
         * Acquires write lock.
         */
        public void writeLock () {
            _lock.writer_lock ();
        }

        /**
         * Releases write lock.
         */
        public void writeUnlock () {
            _lock.writer_unlock ();
        }
    }
}
