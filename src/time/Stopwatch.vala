namespace Vala.Time {
    /**
     * Mutable stopwatch for elapsed-time measurement.
     *
     * Stopwatch measures elapsed monotonic time across start/stop intervals.
     * Repeated start/stop calls accumulate elapsed duration until reset().
     *
     * Example:
     * {{{
     *     var sw = new Stopwatch ();
     *     sw.start ();
     *     Posix.usleep (50000);
     *     sw.stop ();
     *     print ("elapsed=%" + int64.FORMAT + "ms\n", sw.elapsedMillis ());
     * }}}
     */
    public class Stopwatch : GLib.Object {
        private int64 _start_us;
        private int64 _elapsed_us;
        private bool _running;

        /**
         * Starts the stopwatch.
         *
         * Calling start on an already running stopwatch does nothing.
         */
        public void start () {
            if (_running) {
                return;
            }
            _start_us = GLib.get_monotonic_time ();
            _running = true;
        }

        /**
         * Stops the stopwatch.
         *
         * Calling stop on a non-running stopwatch does nothing.
         */
        public void stop () {
            if (!_running) {
                return;
            }

            int64 now_us = GLib.get_monotonic_time ();
            _elapsed_us += (now_us - _start_us);
            _running = false;
        }

        /**
         * Resets elapsed time to zero and stops measurement.
         */
        public void reset () {
            _elapsed_us = 0;
            _start_us = 0;
            _running = false;
        }

        /**
         * Returns elapsed time as a Duration.
         *
         * @return elapsed duration.
         */
        public Duration elapsed () {
            return Duration.ofSeconds (elapsedMillis () / 1000);
        }

        /**
         * Returns elapsed time in milliseconds.
         *
         * @return elapsed milliseconds.
         */
        public int64 elapsedMillis () {
            int64 elapsed_us = _elapsed_us;
            if (_running) {
                elapsed_us += (GLib.get_monotonic_time () - _start_us);
            }
            return elapsed_us / 1000;
        }
    }
}
