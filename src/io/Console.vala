namespace Vala.Io {
    /**
     * Console utility methods.
     */
    public class Console : GLib.Object {
        /**
         * Returns whether standard input is a terminal.
         *
         * @return true when stdin is a TTY.
         */
        public static bool isTTY () {
            return Posix.isatty (Posix.STDIN_FILENO);
        }

        /**
         * Reads a password from terminal input without echo.
         *
         * @return password text, or null when stdin is not a TTY.
         */
        public static string ? readPassword () {
            if (!isTTY ()) {
                return null;
            }

            unowned string ? password = Posix.getpass ("");
            if (password == null) {
                return null;
            }

            return "%s".printf (password);
        }
    }
}
