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

            Posix.termios old_termios = {};
            Posix.tcgetattr (Posix.STDIN_FILENO, out old_termios);

            Posix.termios new_termios = old_termios;
            new_termios.c_lflag &= ~Posix.ECHO;
            Posix.tcsetattr (Posix.STDIN_FILENO, Posix.TCSANOW, new_termios);

            string ? line = stdin.read_line ();

            Posix.tcsetattr (Posix.STDIN_FILENO, Posix.TCSANOW, old_termios);

            return line;
        }
    }
}
