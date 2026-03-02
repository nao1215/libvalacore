namespace Vala.Concurrent {
    /**
     * Recoverable countdown latch configuration errors.
     */
    public errordomain CountDownLatchError {
        INVALID_ARGUMENT
    }

    /**
     * Countdown latch for one-shot synchronization.
     *
     * CountDownLatch starts with a fixed counter. Worker threads call
     * countDown(), and waiting thread(s) block in await() until the counter
     * reaches zero.
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
            _mutex.lock ();
            while (_count > 0) {
                _cond.wait (_mutex);
            }
            _mutex.unlock ();
        }

        /**
         * Blocks until count reaches zero or timeout.
         *
         * @param timeout timeout duration.
         * @return true if reached zero, false on timeout.
         */
        public bool awaitTimeout (Vala.Time.Duration timeout) {
            int64 deadline = GLib.get_monotonic_time () + timeout.toMillis () * 1000;

            _mutex.lock ();
            while (_count > 0) {
                if (!_cond.wait_until (_mutex, deadline)) {
                    _mutex.unlock ();
                    return false;
                }
            }
            _mutex.unlock ();
            return true;
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
