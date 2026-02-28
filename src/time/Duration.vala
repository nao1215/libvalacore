namespace Vala.Time {
    /**
     * Immutable value object that represents a duration.
     */
    public class Duration : GLib.Object {
        private const int64 MILLIS_PER_SECOND = 1000;
        private const int64 MILLIS_PER_MINUTE = 60 * MILLIS_PER_SECOND;
        private const int64 MILLIS_PER_HOUR = 60 * MILLIS_PER_MINUTE;
        private const int64 MILLIS_PER_DAY = 24 * MILLIS_PER_HOUR;

        private int64 _millis;

        private Duration (int64 millis) {
            _millis = millis;
        }

        /**
         * Creates a duration from seconds.
         *
         * @param secs seconds.
         * @return duration.
         */
        public static Duration ofSeconds (int64 secs) {
            return new Duration (secs * MILLIS_PER_SECOND);
        }

        /**
         * Creates a duration from minutes.
         *
         * @param mins minutes.
         * @return duration.
         */
        public static Duration ofMinutes (int64 mins) {
            return new Duration (mins * MILLIS_PER_MINUTE);
        }

        /**
         * Creates a duration from hours.
         *
         * @param hours hours.
         * @return duration.
         */
        public static Duration ofHours (int64 hours) {
            return new Duration (hours * MILLIS_PER_HOUR);
        }

        /**
         * Creates a duration from days.
         *
         * @param days days.
         * @return duration.
         */
        public static Duration ofDays (int64 days) {
            return new Duration (days * MILLIS_PER_DAY);
        }

        /**
         * Returns duration in seconds.
         *
         * @return seconds.
         */
        public int64 toSeconds () {
            return _millis / MILLIS_PER_SECOND;
        }

        /**
         * Returns duration in milliseconds.
         *
         * @return milliseconds.
         */
        public int64 toMillis () {
            return _millis;
        }

        /**
         * Returns the sum of this and another duration.
         *
         * @param other duration to add.
         * @return added duration.
         */
        public Duration plus (Duration other) {
            return new Duration (_millis + other._millis);
        }

        /**
         * Returns the difference of this and another duration.
         *
         * @param other duration to subtract.
         * @return subtracted duration.
         */
        public Duration minus (Duration other) {
            return new Duration (_millis - other._millis);
        }

        /**
         * Returns a human-readable string such as "2h30m".
         *
         * @return duration string.
         */
        public string toString () {
            if (_millis == 0) {
                return "0ms";
            }

            bool negative = _millis < 0;
            int64 remain = negative ? -_millis : _millis;

            int64 days = remain / MILLIS_PER_DAY;
            remain %= MILLIS_PER_DAY;

            int64 hours = remain / MILLIS_PER_HOUR;
            remain %= MILLIS_PER_HOUR;

            int64 minutes = remain / MILLIS_PER_MINUTE;
            remain %= MILLIS_PER_MINUTE;

            int64 seconds = remain / MILLIS_PER_SECOND;
            remain %= MILLIS_PER_SECOND;

            int64 millis = remain;

            GLib.StringBuilder sb = new GLib.StringBuilder ();
            if (negative) {
                sb.append ("-");
            }
            if (days > 0) {
                sb.append (days.to_string ());
                sb.append ("d");
            }
            if (hours > 0) {
                sb.append (hours.to_string ());
                sb.append ("h");
            }
            if (minutes > 0) {
                sb.append (minutes.to_string ());
                sb.append ("m");
            }
            if (seconds > 0) {
                sb.append (seconds.to_string ());
                sb.append ("s");
            }
            if (millis > 0) {
                sb.append (millis.to_string ());
                sb.append ("ms");
            }

            return sb.str;
        }
    }
}
