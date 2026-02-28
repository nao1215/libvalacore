namespace Vala.Lang {
    /**
     * Callback delegate for shutdown hook handlers.
     *
     * This delegate uses [CCode (has_target = false)] for Posix.atexit
     * compatibility. Closures that capture local variables are not supported;
     * use module-level variables or static state instead.
     */
    [CCode (has_target = false)]
    public delegate void ShutdownHookFunc ();

    /**
     * Utilities for registering callbacks executed at process shutdown.
     */
    public class ShutdownHooks : GLib.Object {
        private static GLib.Mutex _mutex;
        private static bool _registered = false;
        private static bool _executed = false;
        private static GLib.Queue<ShutdownHookFunc> ? _hooks = null;

        /**
         * Registers a callback executed when the process exits normally.
         *
         * Example:
         * {{{
         *     ShutdownHooks.addHook (() => {
         *         print ("cleanup\n");
         *     });
         * }}}
         *
         * @param func callback to execute at process shutdown.
         */
        public static void addHook (ShutdownHookFunc func) {
            _mutex.lock ();
            if (_executed) {
                _mutex.unlock ();
                return;
            }

            if (!_registered) {
                Posix.atexit (runHooks);
                _registered = true;
            }

            if (_hooks == null) {
                _hooks = new GLib.Queue<ShutdownHookFunc> ();
            }
            _hooks.push_head (func);
            _mutex.unlock ();
        }

        private static void runHooks () {
            _mutex.lock ();
            if (_executed) {
                _mutex.unlock ();
                return;
            }
            _executed = true;
            _mutex.unlock ();

            while (true) {
                ShutdownHookFunc ? hook = null;

                _mutex.lock ();
                if (_hooks == null || _hooks.is_empty ()) {
                    _mutex.unlock ();
                    break;
                }
                hook = _hooks.pop_head ();
                _mutex.unlock ();

                if (hook != null) {
                    hook ();
                }
            }
        }
    }
}
