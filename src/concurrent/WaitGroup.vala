namespace Vala.Concurrent {
    /**
     * Waits for a collection of tasks to complete.
     */
    public class WaitGroup : GLib.Object {
        private GLib.Mutex _mutex;
        private GLib.Cond _cond;
        private int _count = 0;

        /**
         * Adds delta to the internal counter.
         *
         * @param delta counter delta.
         */
        public void add (int delta) {
            _mutex.lock ();

            int next = _count + delta;
            if (next < 0) {
                _mutex.unlock ();
                error ("WaitGroup counter cannot be negative");
            }

            _count = next;
            if (_count == 0) {
                _cond.broadcast ();
            }

            _mutex.unlock ();
        }

        /**
         * Decrements the counter by one.
         */
        public void done () {
            add (-1);
        }

        /**
         * Blocks until the counter reaches zero.
         */
        public void wait () {
            _mutex.lock ();
            while (_count > 0) {
                _cond.wait (_mutex);
            }
            _mutex.unlock ();
        }
    }
}
