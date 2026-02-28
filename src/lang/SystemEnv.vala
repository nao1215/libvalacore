namespace Vala.Lang {
    /**
     * Environment variable helper methods.
     *
     * SystemEnv wraps GLib environment APIs with lightweight input
     * validation and nullable semantics. Use this class when application
     * behavior depends on runtime environment variables.
     *
     * Example:
     * {{{
     *     string? home = SystemEnv.get ("HOME");
     *     SystemEnv.set ("APP_MODE", "dev");
     * }}}
     */
    public class SystemEnv : GLib.Object {
        /**
         * Returns environment variable value.
         *
         * @param key variable key.
         * @return value, or null when missing.
         */
        public new static string ? get (string key) {
            if (key.length == 0) {
                return null;
            }
            return Environment.get_variable (key);
        }

        /**
         * Sets environment variable value.
         *
         * @param key variable key.
         * @param value variable value.
         * @return true on success.
         */
        public new static bool set (string key, string value) {
            if (key.length == 0) {
                return false;
            }
            return Environment.set_variable (key, value, true);
        }
    }
}
