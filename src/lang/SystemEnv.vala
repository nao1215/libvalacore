namespace Vala.Lang {
    /**
     * Environment variable helper methods.
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
