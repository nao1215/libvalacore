namespace Vala.Lang {
    /**
     * System information helper methods.
     *
     * This class collects host-level process context such as OS name, home
     * directory, temporary directory, and current directory.
     *
     * Example:
     * {{{
     *     print ("os=%s\n", SystemInfo.osName ());
     *     print ("home=%s\n", SystemInfo.userHome ());
     * }}}
     */
    public class SystemInfo : GLib.Object {
        /**
         * Returns OS name.
         *
         * @return OS name string.
         */
        public static string osName () {
            Posix.utsname unameInfo = Posix.utsname ();
            string sysname = unameInfo.sysname.strip ();
            if (sysname.length > 0) {
                return sysname;
            }
            return "unknown";
        }

        /**
         * Returns user home directory.
         *
         * @return home directory path.
         */
        public static string userHome () {
            return Environment.get_home_dir ();
        }

        /**
         * Returns temporary directory path.
         *
         * @return temp directory path.
         */
        public static string tmpDir () {
            return Environment.get_tmp_dir ();
        }

        /**
         * Returns current working directory.
         *
         * @return current directory path.
         */
        public static string currentDir () {
            return Environment.get_current_dir ();
        }
    }
}
