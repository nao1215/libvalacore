using Posix;
using Vala.Time;
using Vala.Lang;

namespace Vala.Io {
    /**
     * Callback executed while lock is held.
     */
    public delegate bool WithFileLockFunc ();

    /**
     * File-based inter-process lock.
     *
     * FileLock uses exclusive lock-file creation to coordinate critical
     * sections across multiple processes.
     *
     * Example:
     * {{{
     *     var lock = new FileLock (new Path ("/tmp/myjob.lock"));
     *     if (lock.acquireTimeout (Duration.ofSeconds (5))) {
     *         try {
     *             run_critical_job ();
     *         } finally {
     *             lock.release ();
     *         }
     *     }
     * }}}
     */
    public class FileLock : GLib.Object {
        private const int RETRY_SLEEP_MILLIS = 10;

        private Path _path;
        private bool _held = false;

        /**
         * Creates a FileLock for the target lock file path.
         *
         * @param path lock file path.
         */
        public FileLock (Path path) {
            _path = path;
        }

        /**
         * Acquires lock, blocking until success.
         *
         * @return true when lock is acquired.
         */
        public bool acquire () {
            while (true) {
                if (tryAcquire ()) {
                    return true;
                }
                Threads.sleepMillis (RETRY_SLEEP_MILLIS);
            }
        }

        /**
         * Attempts to acquire lock within timeout.
         *
         * @param timeout maximum wait duration.
         * @return true when lock is acquired before timeout.
         */
        public bool acquireTimeout (Duration timeout) {
            int64 timeoutMillis = timeout.toMillis ();
            if (timeoutMillis < 0) {
                error ("timeout must be non-negative, got %" + int64.FORMAT, timeoutMillis);
            }

            int64 deadlineMicros = GLib.get_monotonic_time () + (timeoutMillis * 1000);
            while (GLib.get_monotonic_time () <= deadlineMicros) {
                if (tryAcquire ()) {
                    return true;
                }
                Threads.sleepMillis (RETRY_SLEEP_MILLIS);
            }
            return false;
        }

        /**
         * Attempts lock acquisition without blocking.
         *
         * @return true if lock is acquired.
         */
        public bool tryAcquire () {
            if (_held) {
                return true;
            }

            int fd = Posix.open (_path.toString (), Posix.O_CREAT | Posix.O_EXCL | Posix.O_WRONLY, 0644);
            if (fd < 0) {
                return false;
            }

            string pidText = "%d\n".printf ((int) Posix.getpid ());
            Posix.write (fd, pidText, pidText.length);
            Posix.close (fd);

            _held = true;
            return true;
        }

        /**
         * Releases lock.
         *
         * @return true on successful release.
         */
        public bool release () {
            if (!_held) {
                return false;
            }

            bool removed = Files.remove (_path);
            _held = false;
            return removed;
        }

        /**
         * Returns whether this instance currently holds the lock.
         *
         * @return true when lock is currently held by this instance.
         */
        public bool isHeld () {
            return _held;
        }

        /**
         * Executes callback while lock is held.
         *
         * @param fn callback executed under lock.
         * @return callback result when lock acquisition succeeds.
         */
        public bool withLock (owned WithFileLockFunc fn) {
            if (!acquire ()) {
                return false;
            }

            try {
                return fn ();
            } finally {
                release ();
            }
        }

        /**
         * Returns owner process ID from lock-file content.
         *
         * @return owner PID, or null when unavailable.
         */
        public int ? ownerPid () {
            if (!Files.isFile (_path)) {
                return null;
            }

            string ? text = Files.readAllText (_path);
            if (text == null) {
                return null;
            }

            int pid;
            if (!int.try_parse (text.strip (), out pid)) {
                return null;
            }
            if (pid <= 0) {
                return null;
            }
            return pid;
        }
    }
}
