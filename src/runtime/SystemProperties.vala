namespace Vala.Runtime {
    /**
     * System property helper methods.
     */
    public class SystemProperties : GLib.Object {
        /**
         * Returns a system property by key.
         *
         * Supported keys:
         * - line.separator
         * - file.separator
         * - path.separator
         * - user.home
         * - user.dir
         * - java.io.tmpdir
         * - os.name
         *
         * @param key property key.
         * @return property value, or null if unknown.
         */
        public new static string ? get (string key) {
            switch (key) {
            case "line.separator":
                return lineSeparator ();
            case "file.separator":
                return fileSeparator ();
            case "path.separator":
                return pathSeparator ();
            case "user.home":
                return Environment.get_home_dir ();
            case "user.dir":
                return Environment.get_current_dir ();
            case "java.io.tmpdir":
                return Environment.get_tmp_dir ();
            case "os.name":
                return osName ();
            default:
                return Environment.get_variable (key);
            }
        }

        /**
         * Returns line separator.
         *
         * @return line separator text.
         */
        public static string lineSeparator () {
            return "\n";
        }

        /**
         * Returns file separator.
         *
         * @return file separator text.
         */
        public static string fileSeparator () {
            return "/";
        }

        /**
         * Returns path list separator.
         *
         * @return separator text.
         */
        public static string pathSeparator () {
            return ":";
        }

        /**
         * Returns monotonic clock in nanoseconds.
         *
         * @return monotonic nanoseconds.
         */
        public static int64 nanoTime () {
            return GLib.get_monotonic_time () * 1000;
        }

        /**
         * Returns current UNIX time in milliseconds.
         *
         * @return current milliseconds.
         */
        public static int64 currentTimeMillis () {
            return GLib.get_real_time () / 1000;
        }

        private static string osName () {
            string? output = null;
            int exitStatus = 0;
            try {
                GLib.Process.spawn_command_line_sync ("uname -s", out output, null, out exitStatus);
                if (exitStatus == 0 && output != null) {
                    string trimmed = output.strip ();
                    if (trimmed.length > 0) {
                        return trimmed;
                    }
                }
            } catch (GLib.SpawnError e) {
            }
            return "unknown";
        }
    }
}
