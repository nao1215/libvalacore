using Vala.Lang;
using Vala.Time;

namespace Vala.Io {
    /**
     * Result of shell command execution.
     */
    public class ShellResult : GLib.Object {
        private int _exit_code;
        private string _stdout;
        private string _stderr;
        private int64 _duration_millis;

        internal ShellResult (int exitCode, string stdout, string stderr, int64 durationMillis) {
            _exit_code = exitCode;
            _stdout = stdout;
            _stderr = stderr;
            _duration_millis = durationMillis;
        }

        /**
         * Returns process exit code.
         *
         * @return exit code.
         */
        public int exitCode () {
            return _exit_code;
        }

        /**
         * Returns captured standard output.
         *
         * @return stdout text.
         */
        public string stdout () {
            return _stdout;
        }

        /**
         * Returns captured standard error.
         *
         * @return stderr text.
         */
        public string stderr () {
            return _stderr;
        }

        /**
         * Returns true when exit code is zero.
         *
         * @return true on successful command execution.
         */
        public bool isSuccess () {
            return _exit_code == 0;
        }

        /**
         * Returns stdout split into non-empty lines.
         *
         * @return stdout lines.
         */
        public GLib.List<string> stdoutLines () {
            return toLines (_stdout);
        }

        /**
         * Returns stderr split into non-empty lines.
         *
         * @return stderr lines.
         */
        public GLib.List<string> stderrLines () {
            return toLines (_stderr);
        }

        /**
         * Returns command duration in milliseconds.
         *
         * @return duration in milliseconds.
         */
        public int64 durationMillis () {
            return _duration_millis;
        }

        private static GLib.List<string> toLines (string text) {
            var lines = new GLib.List<string> ();
            foreach (string line in text.split ("\n")) {
                if (line.length > 0) {
                    lines.append (line);
                }
            }
            return lines;
        }
    }

    /**
     * Shell command helper for quick command execution and output capture.
     *
     * Example:
     * {{{
     *     ShellResult res = Shell.exec ("git status --short");
     *     if (res.isSuccess ()) {
     *         print ("%s\n", res.stdout ());
     *     }
     * }}}
     */
    public class Shell : GLib.Object {
        private const int SPAWN_ERROR_EXIT_CODE = 127;

        /**
         * Executes a command and captures stdout/stderr.
         *
         * @param command shell command.
         * @return execution result.
         */
        public static ShellResult exec (string command) {
            return run (command, false);
        }

        /**
         * Executes a command and discards captured output in the result object.
         *
         * @param command shell command.
         * @return execution result.
         */
        public static ShellResult execQuiet (string command) {
            return run (command, true);
        }

        /**
         * Executes a command with timeout.
         *
         * This method uses coreutils `timeout` command on POSIX environments.
         *
         * @param command shell command.
         * @param timeout timeout duration.
         * @return execution result.
         */
        public static ShellResult execWithTimeout (string command, Duration timeout) {
            int64 timeoutMillis = timeout.toMillis ();
            if (timeoutMillis < 0) {
                error ("timeout must be non-negative, got %" + int64.FORMAT, timeoutMillis);
            }

            if (timeoutMillis == 0) {
                return run (command, false);
            }

            int64 seconds = (timeoutMillis + 999) / 1000;
            string wrapped = "timeout --preserve-status %" + int64.FORMAT + "s /bin/sh -c %s";
            return run (wrapped.printf (seconds, GLib.Shell.quote (command)), false);
        }

        /**
         * Executes multiple commands as a shell pipeline.
         *
         * @param commands command array where each element is one pipeline stage.
         * @return execution result.
         */
        public static ShellResult pipe (string[] commands) {
            if (commands.length == 0) {
                return new ShellResult (SPAWN_ERROR_EXIT_CODE, "", "no commands", 0);
            }

            var builder = new GLib.StringBuilder ();
            for (int i = 0; i < commands.length; i++) {
                if (i > 0) {
                    builder.append (" | ");
                }
                builder.append (commands[i]);
            }
            return run (builder.str, false);
        }

        /**
         * Resolves command path from current PATH.
         *
         * @param binary binary name to resolve.
         * @return resolved path, or null when not found.
         */
        public static Path ? which (string binary) {
            if (binary.length == 0) {
                return null;
            }

            ShellResult result = run ("command -v " + GLib.Shell.quote (binary), false);
            if (!result.isSuccess ()) {
                return null;
            }

            string value = result.stdout ().strip ();
            if (value.length == 0) {
                return null;
            }
            return new Path (value);
        }

        private static ShellResult run (string command, bool quiet) {
            int64 startMicros = GLib.get_monotonic_time ();
            Vala.Lang.Process ? proc = Vala.Lang.Process.exec (command);
            int64 durationMillis = (GLib.get_monotonic_time () - startMicros) / 1000;

            if (proc == null) {
                return new ShellResult (
                    SPAWN_ERROR_EXIT_CODE,
                    "",
                    "failed to spawn process",
                    durationMillis
                );
            }

            if (quiet) {
                return new ShellResult (proc.exitCode (), "", "", durationMillis);
            }

            return new ShellResult (
                proc.exitCode (),
                proc.stdout (),
                proc.stderr (),
                durationMillis
            );
        }
    }
}
