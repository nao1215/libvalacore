using Posix;
namespace Vala.Lang {
    /**
     * Operating-system utility methods.
     *
     * Os provides simple wrappers for frequently used environment and working
     * directory operations. These helpers are convenient in CLI tools and
     * scripts where process context must be inspected or changed.
     *
     * Example:
     * {{{
     *     string? oldCwd = Os.cwd ();
     *     Os.chdir ("/tmp");
     *     string? path = Os.get_env ("PATH");
     * }}}
     */
    public class Os : GLib.Object {
        /**
         * Returns the value of the environment variable.
         * @param env string of environment variable
         * @return If the environment variable env is set, its value is returned.
         * If not set, returns null.
         */
        public static string ? get_env (string env) {
            if (Objects.isNull (env)) {
                return null;
            }
            return Environment.get_variable (env).dup ();
        }

        /**
         * Returns current working directory.
         * @return If the environment variable "PWD" is set to a value, that value is returned.
         * Returns null if the value is not set.
         */
        public static string ? cwd () {
            return Environment.get_current_dir ();
        }

        /**
         * Change current directory.
         * @param path string containing the new current directory
         * @return true: change directory is success, false: change directory is fail.
         */
        public static bool chdir (string path) {
            if (Objects.isNull (path)) {
                return false;
            }
            return Posix.chdir (path) == 0 ? true : false;
        }
    }
}
