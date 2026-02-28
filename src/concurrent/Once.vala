namespace Vala.Concurrent {
    /**
     * Function delegate for Once execution.
     */
    public delegate void OnceFunc ();

    /**
     * Executes a function at most once.
     */
    public class Once : GLib.Object {
        private GLib.Mutex _mutex;
        private bool _done = false;

        /**
         * Executes the function only once.
         *
         * @param func function to execute once.
         */
        public void doOnce (OnceFunc func) {
            bool should_run = false;

            _mutex.lock ();
            if (!_done) {
                _done = true;
                should_run = true;
            }
            _mutex.unlock ();

            if (should_run) {
                func ();
            }
        }
    }
}
