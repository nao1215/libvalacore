using Vala.Collections;

namespace Vala.Io {
    /**
     * Recoverable console I/O errors.
     */
    public errordomain ConsoleError {
        NOT_TTY,
        IO
    }

    /**
     * Console utility methods.
     *
     * Console provides simple terminal-aware input behavior such as TTY
     * detection and password prompt handling without echo.
     *
     * Example:
     * {{{
     *     if (Console.isTTY ()) {
     *         var result = Console.readPassword ();
     *         if (result.isOk ()) {
     *             string password = result.unwrap ();
     *         } else {
     *             stderr.printf ("%s\n", result.unwrapError ().message);
     *         }
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
         * @return Result.ok(password text), or
         *         Result.error(ConsoleError.NOT_TTY/IO).
         */
        public static Result<string, GLib.Error> readPassword () {
            if (!isTTY ()) {
                return Result.error<string, GLib.Error> (
                    new ConsoleError.NOT_TTY ("stdin is not a tty")
                );
            }

            Posix.termios old_termios = {};
            if (Posix.tcgetattr (Posix.STDIN_FILENO, out old_termios) != 0) {
                return Result.error<string, GLib.Error> (
                    new ConsoleError.IO ("failed to read terminal attributes")
                );
            }

            Posix.termios new_termios = old_termios;
            new_termios.c_lflag &= ~Posix.ECHO;
            if (Posix.tcsetattr (Posix.STDIN_FILENO, Posix.TCSANOW, new_termios) != 0) {
                return Result.error<string, GLib.Error> (
                    new ConsoleError.IO ("failed to disable terminal echo")
                );
            }

            string ? line = stdin.read_line ();

            if (Posix.tcsetattr (Posix.STDIN_FILENO, Posix.TCSANOW, old_termios) != 0) {
                return Result.error<string, GLib.Error> (
                    new ConsoleError.IO ("failed to restore terminal attributes")
                );
            }

            if (line == null) {
                return Result.error<string, GLib.Error> (
                    new ConsoleError.IO ("failed to read password line")
                );
            }

            return Result.ok<string, GLib.Error> (line);
        }
    }
}
