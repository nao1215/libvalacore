using Vala.Collections;
namespace Vala.Concurrent {
    /**
     * Recoverable countdown latch configuration errors.
     */
    public errordomain CountDownLatchError {
        INVALID_ARGUMENT,
        TIMEOUT
    }

    /**
     * Countdown latch for one-shot synchronization.
     *
     * CountDownLatch starts with a fixed counter. Worker threads call
     * countDown(), and waiting thread(s) block in await() until the counter
     * reaches zero.
     *
     * Thread-safety: THREAD_SAFE
     *
     * Example:
     * {{{
     *     var created = CountDownLatch.of (2);
     *     if (created.isError ()) {
     *         return;
     *     }
     *     var latch = created.unwrap ();
     *     // Two workers call latch.countDown()
     *     latch.@await ();
     * }}}
     */
    public class CountDownLatch : GLib.Object {
        private GLib.Mutex _mutex;
        private GLib.Cond _cond;
        private int _count;

        /**
         * Creates latch with initial count.
         *
         * @param count initial count.
         */
        private CountDownLatch (int count) {
            _count = count;
        }

        /**
         * Creates latch with initial count.
         *
         * @param count initial count.
         * @return Result.ok(latch), or
         *         Result.error(CountDownLatchError.INVALID_ARGUMENT) when count is negative.
         */
        public static Vala.Collections.Result<CountDownLatch, GLib.Error> of (int count) {
            if (count < 0) {
                return Vala.Collections.Result.error<CountDownLatch, GLib.Error> (
                    new CountDownLatchError.INVALID_ARGUMENT ("count must be non-negative")
                );
            }
            return Vala.Collections.Result.ok<CountDownLatch, GLib.Error> (new CountDownLatch (count));
        }

        /**
         * Decrements count by one.
         */
        public void countDown () {
            _mutex.lock ();

            if (_count > 0) {
                _count--;
                if (_count == 0) {
                    _cond.broadcast ();
                }
            }

            _mutex.unlock ();
        }

        /**
         * Blocks until count reaches zero.
         */
        public void @await () {
            var waited = awaitTimeout (Vala.Time.Duration.ofSeconds (-1));
            if (waited.isError ()) {
                // Defensive fallback: infinite wait should not timeout.
                warning ("%s", waited.unwrapError ().message);
            }
        }

        /**
         * Blocks until count reaches zero or timeout.
         *
         * Timeout semantics:
         * - `0`: non-blocking check
         * - `>0`: wait up to N milliseconds
         * - `<0`: wait forever (explicit infinite wait)
         *
         * @param timeout timeout duration.
         * @return Result.ok(true) when reached zero, or
         *         Result.error(CountDownLatchError.TIMEOUT) on timeout.
         */
        public Vala.Collections.Result<bool, GLib.Error> awaitTimeout (Vala.Time.Duration timeout) {
            int64 timeout_millis = timeout.toMillis ();
            _mutex.lock ();

            if (timeout_millis == 0) {
                bool completed = _count == 0;
                int remaining = _count;
                _mutex.unlock ();
                if (completed) {
                    return Vala.Collections.Result.ok<bool, GLib.Error> (true);
                }
                return Vala.Collections.Result.error<bool, GLib.Error> (
                    new CountDownLatchError.TIMEOUT (
                        "countdown latch timed out: timeout=0ms remaining=%d".printf (remaining)
                    )
                );
            }

            if (timeout_millis < 0) {
                while (_count > 0) {
                    _cond.wait (_mutex);
                }
                _mutex.unlock ();
                return Vala.Collections.Result.ok<bool, GLib.Error> (true);
            }

            int64 deadline = GLib.get_monotonic_time () + timeout_millis * 1000;
            while (_count > 0) {
                if (!_cond.wait_until (_mutex, deadline)) {
                    int remaining = _count;
                    _mutex.unlock ();
                    return Vala.Collections.Result.error<bool, GLib.Error> (
                        new CountDownLatchError.TIMEOUT (
                            "countdown latch timed out: timeout=%sms remaining=%d".printf (
                                timeout_millis.to_string (),
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
         * Returns current count.
         *
         * @return count value.
         */
        public int getCount () {
            _mutex.lock ();
            int count = _count;
            _mutex.unlock ();
            return count;
        }
    }
}
