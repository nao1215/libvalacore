namespace Vala.Io {
    /**
     * Console utility methods.
     *
     * Console provides simple terminal-aware input behavior such as TTY
     * detection and password prompt handling without echo.
     *
     * Example:
     * {{{
     *     if (Console.isTTY ()) {
     *         string? password = Console.readPassword ();
     *     }
     * }}}
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

            Posix.termios old_termios = {};
            if (Posix.tcgetattr (Posix.STDIN_FILENO, out old_termios) != 0) {
                return null;
            }

            Posix.termios new_termios = old_termios;
            new_termios.c_lflag &= ~Posix.ECHO;
            if (Posix.tcsetattr (Posix.STDIN_FILENO, Posix.TCSANOW, new_termios) != 0) {
                return null;
            }

            string ? line = stdin.read_line ();

            Posix.tcsetattr (Posix.STDIN_FILENO, Posix.TCSANOW, old_termios);

            return line;
        }
    }
}
