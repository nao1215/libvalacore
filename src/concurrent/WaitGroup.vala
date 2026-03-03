namespace Vala.Concurrent {
    /**
     * Recoverable wait-group errors.
     */
    public errordomain WaitGroupError {
        TIMEOUT
    }

    /**
     * Waits for a collection of tasks to complete.
     *
     * WaitGroup tracks in-flight task count via add()/done() and blocks with
     * wait() until all tasks complete.
     *
     * Thread-safety: THREAD_SAFE
     *
     * Example:
     * {{{
     *     var wg = new WaitGroup ();
     *     wg.add (2);
     *     // workers call wg.done ()
     *     wg.wait ();
     * }}}
     */
    public class WaitGroup : GLib.Object {
        private GLib.Mutex _mutex;
        private GLib.Cond _cond;
        private int _count = 0;

        /**
         * Adds delta to the internal counter.
         *
         * If applying delta would make the counter negative, the update is
         * ignored and a warning is logged.
         *
         * @param delta counter delta.
         */
        public void add (int delta) {
            _mutex.lock ();

            int next = _count + delta;
            if (next < 0) {
                _mutex.unlock ();
                warning ("WaitGroup counter cannot be negative (attempted next=%d)", next);
                return;
            }

            _count = next;
            if (_count == 0) {
                _cond.broadcast ();
            }

            _mutex.unlock ();
        }

        /**
         * Decrements the counter by one.
         *
         * If the counter is already zero, done() is a no-op.
         */
        public void done () {
            add (-1);
        }

        /**
         * Waits until the counter reaches zero, with timeout contract.
         *
         * Timeout semantics:
         * - `0`: non-blocking check
         * - `>0`: wait up to N milliseconds
         * - `<0`: wait forever (explicit infinite wait)
         *
         * @param timeoutMillis timeout in milliseconds.
         * @return Result.ok(true) when all tasks are done, or
         *         Result.error(WaitGroupError.TIMEOUT) on timeout.
         */
        public Vala.Collections.Result<bool, GLib.Error> waitFor (int timeoutMillis) {
            _mutex.lock ();

            if (timeoutMillis == 0) {
                bool completed = _count == 0;
                int remaining = _count;
                _mutex.unlock ();
                if (completed) {
                    return Vala.Collections.Result.ok<bool, GLib.Error> (true);
                }
                return Vala.Collections.Result.error<bool, GLib.Error> (
                    new WaitGroupError.TIMEOUT (
                        "waitgroup wait timed out: timeout=0ms remaining=%d".printf (remaining)
                    )
                );
            }

            if (timeoutMillis < 0) {
                while (_count > 0) {
                    _cond.wait (_mutex);
                }
                _mutex.unlock ();
                return Vala.Collections.Result.ok<bool, GLib.Error> (true);
            }

            int64 deadline = GLib.get_monotonic_time () + (int64) timeoutMillis * 1000;
            while (_count > 0) {
                if (!_cond.wait_until (_mutex, deadline)) {
                    int remaining = _count;
                    _mutex.unlock ();
                    return Vala.Collections.Result.error<bool, GLib.Error> (
                        new WaitGroupError.TIMEOUT (
                            "waitgroup wait timed out: timeout=%dms remaining=%d".printf (
                                timeoutMillis,
                                remaining
                            )
                        )
                    );
                }
            }

            _mutex.unlock ();
            return Vala.Collections.Result.ok<bool, GLib.Error> (true);
        }

        /**
         * Blocks until the counter reaches zero.
         *
         * This is equivalent to `waitFor(-1)` (explicit infinite wait).
         */
        public void wait () {
            var result = waitFor (-1);
            if (result.isError ()) {
                // Defensive fallback: waitFor(-1) should not timeout.
                warning ("%s", result.unwrapError ().message);
            }
        }
    }
}
