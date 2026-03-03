namespace Vala.Lang {
    /**
     * Recoverable process lifecycle errors.
     */
    public errordomain LangProcessError {
        INVALID_ARGUMENT,
        INVALID_STATE,
        SPAWN_FAILED,
        WAIT_FAILED
    }

    /**
     * Wrapper for external process execution.
     */
    public class Process : GLib.Object {
        private GLib.Subprocess ? _process;
        private string _stdout = "";
        private string _stderr = "";
        private int _exit_code = 0;
        private bool _completed = false;

        private Process () {
        }

        /**
         * Executes command synchronously.
         *
         * @param command command line.
         * @return Result.ok(process wrapper) on success,
         *         Result.error(LangProcessError.*) on failure.
         */
        public static Vala.Collections.Result<Process, GLib.Error> exec (string command) {
            var started = execAsync (command);
            if (started.isError ()) {
                return Vala.Collections.Result.error<Process, GLib.Error> (started.unwrapError ());
            }

            Process proc = started.unwrap ();
            var waited = proc.waitFor ();
            if (waited.isError ()) {
                return Vala.Collections.Result.error<Process, GLib.Error> (waited.unwrapError ());
            }
            return Vala.Collections.Result.ok<Process, GLib.Error> (proc);
        }

        /**
         * Starts command asynchronously.
         *
         * @param command command line.
         * @return Result.ok(process wrapper) on success,
         *         Result.error(LangProcessError.*) on failure.
         */
        public static Vala.Collections.Result<Process, GLib.Error> execAsync (string command) {
            if (command.length == 0) {
                return Vala.Collections.Result.error<Process, GLib.Error> (
                    new LangProcessError.INVALID_ARGUMENT ("command must not be empty")
                );
            }

            try {
                string shell = Environment.get_variable ("SHELL") ?? "sh";
                if (shell.length == 0) {
                    shell = "sh";
                }
                string[] argv = { shell, "-c", command, null };
                GLib.Subprocess process = new GLib.Subprocess.newv (
                    argv,
                    GLib.SubprocessFlags.STDOUT_PIPE
                    | GLib.SubprocessFlags.STDERR_PIPE
                );

                Process wrapper = new Process ();
                wrapper._process = process;
                return Vala.Collections.Result.ok<Process, GLib.Error> (wrapper);
            } catch (GLib.Error e) {
                return Vala.Collections.Result.error<Process, GLib.Error> (
                    new LangProcessError.SPAWN_FAILED (
                        "failed to spawn command '%s': %s".printf (command, e.message)
                    )
                );
            }
        }

        /**
         * Returns exit code.
         *
         * @return process exit code.
         */
        public int exitCode () {
            return _exit_code;
        }

        /**
         * Returns captured stdout.
         *
         * @return stdout text.
         */
        public string stdout () {
            return _stdout;
        }

        /**
         * Returns captured stderr.
         *
         * @return stderr text.
         */
        public string stderr () {
            return _stderr;
        }

        /**
         * Waits for process completion and captures output.
         *
         * @return Result.ok(true) on success,
         *         Result.error(LangProcessError.INVALID_STATE / WAIT_FAILED) on failure.
         */
        public Vala.Collections.Result<bool, GLib.Error> waitFor () {
            if (_process == null) {
                return Vala.Collections.Result.error<bool, GLib.Error> (
                    new LangProcessError.INVALID_STATE ("process is not started")
                );
            }
            if (_completed) {
                return Vala.Collections.Result.ok<bool, GLib.Error> (true);
            }

            try {
                string ? out_text = null;
                string ? err_text = null;
                _process.communicate_utf8 (null, null, out out_text, out err_text);

                _stdout = out_text ?? "";
                _stderr = err_text ?? "";

                if (_process.get_if_exited ()) {
                    _exit_code = _process.get_exit_status ();
                } else if (_process.get_if_signaled ()) {
                    _exit_code = -_process.get_term_sig ();
                }
                _completed = true;
                return Vala.Collections.Result.ok<bool, GLib.Error> (true);
            } catch (GLib.Error e) {
                return Vala.Collections.Result.error<bool, GLib.Error> (
                    new LangProcessError.WAIT_FAILED (
                        "failed waiting process completion: %s".printf (e.message)
                    )
                );
            }
        }

        /**
         * Kills the running process.
         *
         * @return Result.ok(true) on success,
         *         Result.error(LangProcessError.INVALID_STATE) when process is missing.
         */
        public Vala.Collections.Result<bool, GLib.Error> kill () {
            if (_process == null) {
                return Vala.Collections.Result.error<bool, GLib.Error> (
                    new LangProcessError.INVALID_STATE ("process is not started")
                );
            }
            _process.force_exit ();
            return Vala.Collections.Result.ok<bool, GLib.Error> (true);
        }
    }
}
