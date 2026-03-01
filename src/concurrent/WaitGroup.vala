namespace Vala.Concurrent {
    /**
     * Waits for a collection of tasks to complete.
     *
     * WaitGroup tracks in-flight task count via add()/done() and blocks with
     * wait() until all tasks complete.
     *
     * Example:
     * {{{
     *     var wg = new WaitGroup ();
     *     wg.add (2);
     *     // workers call wg.done ()
     *     wg.wait ();
     * }}}
     */
    public class WaitGroup : GLib.Object {
        private GLib.Mutex _mutex;
        private GLib.Cond _cond;
        private int _count = 0;

        /**
         * Adds delta to the internal counter.
         *
         * If applying delta would make the counter negative, the update is
         * ignored and a warning is logged.
         *
         * @param delta counter delta.
         */
        public void add (int delta) {
            _mutex.lock ();

            int next = _count + delta;
            if (next < 0) {
                _mutex.unlock ();
                warning ("WaitGroup counter cannot be negative (attempted next=%d)", next);
                return;
            }

            _count = next;
            if (_count == 0) {
                _cond.broadcast ();
            }

            _mutex.unlock ();
        }

        /**
         * Decrements the counter by one.
         *
         * If the counter is already zero, done() is a no-op.
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
