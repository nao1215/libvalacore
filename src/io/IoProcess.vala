namespace Vala.Io {
    /**
     * Process execution utility methods.
     */
    public class Process : GLib.Object {
        private static bool hasCommand (string cmd) {
            return cmd.strip ().length > 0;
        }

        private static string[] buildArgv (string cmd, string[] args) {
            string[] argv = new string[args.length + 2];
            argv[0] = cmd;
            for (int i = 0; i < args.length; i++) {
                argv[i + 1] = args[i];
            }
            argv[args.length + 1] = null;
            return argv;
        }

        /**
         * Executes an external command and waits for completion.
         *
         * Example:
         * {{{
         *     bool ok = Process.exec ("sh", { "-c", "exit 0" });
         *     assert (ok == true);
         * }}}
         *
         * @param cmd command path or executable name.
         * @param args command arguments.
         * @return true when the process exits with status 0.
         */
        public static bool exec (string cmd, string[] args) {
            if (!hasCommand (cmd)) {
                return false;
            }

            string[] argv = buildArgv (cmd, args);
            try {
                GLib.Subprocess process = new GLib.Subprocess.newv (
                    argv,
                    GLib.SubprocessFlags.NONE
                );
                return process.wait_check ();
            } catch (GLib.Error e) {
                return false;
            }
        }

        /**
         * Executes an external command and returns stdout on success.
         *
         * Example:
         * {{{
         *     string? out = Process.execWithOutput ("sh", { "-c", "printf 'hello'" });
         *     assert (out == "hello");
         * }}}
         *
         * @param cmd command path or executable name.
         * @param args command arguments.
         * @return captured stdout when exit status is 0, otherwise null.
         */
        public static string ? execWithOutput (string cmd, string[] args) {
            if (!hasCommand (cmd)) {
                return null;
            }

            string[] argv = buildArgv (cmd, args);
            try {
                GLib.Subprocess process = new GLib.Subprocess.newv (
                    argv,
                    GLib.SubprocessFlags.STDOUT_PIPE | GLib.SubprocessFlags.STDERR_PIPE
                );
                string ? stdoutText = null;
                string ? stderrText = null;
                process.communicate_utf8 (null, null, out stdoutText, out stderrText);
                if (!process.get_successful ()) {
                    return null;
                }
                return stdoutText ?? "";
            } catch (GLib.Error e) {
                return null;
            }
        }

        /**
         * Sends SIGKILL to the target process ID.
         *
         * Example:
         * {{{
         *     bool ok = Process.kill (12345);
         * }}}
         *
         * @param pid process ID.
         * @return true when signal delivery succeeds.
         */
        public static bool kill (int pid) {
            if (pid <= 0) {
                return false;
            }
            return Posix.kill ((Posix.pid_t) pid, Posix.Signal.KILL) == 0;
        }
    }
}
