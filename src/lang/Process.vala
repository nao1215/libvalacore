namespace Vala.Lang {
    /**
     * Wrapper for external process execution.
     */
    public class Process : GLib.Object {
        private GLib.Subprocess? _process;
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
         * @return process result object or null on spawn error.
         */
        public static Process? exec (string command) {
            Process? proc = execAsync (command);
            if (proc == null) {
                return null;
            }
            if (!proc.waitFor ()) {
                return null;
            }
            return proc;
        }

        /**
         * Starts command asynchronously.
         *
         * @param command command line.
         * @return process object or null on spawn error.
         */
        public static Process? execAsync (string command) {
            if (command.length == 0) {
                return null;
            }

            try {
                string[] argv = { "/bin/sh", "-c", command, null };
                GLib.Subprocess process = new GLib.Subprocess.newv (
                                                                     argv,
                                                                     GLib.SubprocessFlags.STDOUT_PIPE
                                                                     | GLib.SubprocessFlags.STDERR_PIPE
                                                                    );

                Process wrapper = new Process ();
                wrapper._process = process;
                return wrapper;
            } catch (GLib.Error e) {
                return null;
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
         * @return true on success.
         */
        public bool waitFor () {
            if (_process == null) {
                return false;
            }
            if (_completed) {
                return true;
            }

            try {
                string? out_text = null;
                string? err_text = null;
                _process.communicate_utf8 (null, null, out out_text, out err_text);

                _stdout = out_text ?? "";
                _stderr = err_text ?? "";

                if (_process.get_if_exited ()) {
                    _exit_code = _process.get_exit_status ();
                }
                _completed = true;
                return true;
            } catch (GLib.Error e) {
                return false;
            }
        }

        /**
         * Kills the running process.
         *
         * @return true when process exists.
         */
        public bool kill () {
            if (_process == null) {
                return false;
            }
            _process.force_exit ();
            return true;
        }
    }
}
