namespace Vala.Io {
    /**
     * Recoverable process execution errors.
     */
    public errordomain ProcessError {
        INVALID_ARGUMENT,
        SPAWN_FAILED,
        EXIT_NON_ZERO
    }

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
         *     var result = Process.exec ("sh", { "-c", "exit 0" });
         *     assert (result.isOk () == true);
         * }}}
         *
         * @param cmd command path or executable name.
         * @param args command arguments.
         * @return Result.ok(true) when the process exits with status 0,
         *         Result.error(ProcessError.*) on failure.
         */
        public static Vala.Collections.Result<bool, GLib.Error> exec (string cmd, string[] args) {
            if (!hasCommand (cmd)) {
                return Vala.Collections.Result.error<bool, GLib.Error> (
                    new ProcessError.INVALID_ARGUMENT ("command must not be empty")
                );
            }

            string[] argv = buildArgv (cmd, args);
            try {
                GLib.Subprocess process = new GLib.Subprocess.newv (
                    argv,
                    GLib.SubprocessFlags.NONE
                );
                process.wait (null);
                if (process.get_successful ()) {
                    return Vala.Collections.Result.ok<bool, GLib.Error> (true);
                }
                return Vala.Collections.Result.error<bool, GLib.Error> (
                    new ProcessError.EXIT_NON_ZERO (
                        "command exited with non-zero status: %s".printf (cmd)
                    )
                );
            } catch (GLib.Error e) {
                return Vala.Collections.Result.error<bool, GLib.Error> (
                    new ProcessError.SPAWN_FAILED (
                        "failed to execute command '%s': %s".printf (cmd, e.message)
                    )
                );
            }
        }

        /**
         * Executes an external command and returns stdout on success.
         *
         * Example:
         * {{{
         *     var out = Process.execWithOutput ("sh", { "-c", "printf 'hello'" });
         *     assert (out.isOk () == true);
         * }}}
         *
         * @param cmd command path or executable name.
         * @param args command arguments.
         * @return Result.ok(stdout text) when exit status is 0,
         *         Result.error(ProcessError.*) on failure.
         */
        public static Vala.Collections.Result<string, GLib.Error> execWithOutput (string cmd,
                                                                                  string[] args) {
            if (!hasCommand (cmd)) {
                return Vala.Collections.Result.error<string, GLib.Error> (
                    new ProcessError.INVALID_ARGUMENT ("command must not be empty")
                );
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
                    return Vala.Collections.Result.error<string, GLib.Error> (
                        new ProcessError.EXIT_NON_ZERO (
                            "command exited with non-zero status: %s stderr=%s".printf (
                                cmd,
                                (stderrText ?? "").strip ()
                            )
                        )
                    );
                }
                return Vala.Collections.Result.ok<string, GLib.Error> (stdoutText ?? "");
            } catch (GLib.Error e) {
                return Vala.Collections.Result.error<string, GLib.Error> (
                    new ProcessError.SPAWN_FAILED (
                        "failed to execute command '%s': %s".printf (cmd, e.message)
                    )
                );
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
