namespace Vala.Time {
    /**
     * Immutable value object for date-time operations.
     */
    public class DateTime : GLib.Object {
        private GLib.DateTime _dt;

        private DateTime.from_glib (GLib.DateTime dt) {
            _dt = dt;
        }

        /**
         * Returns current local date-time.
         *
         * @return current date-time.
         */
        public static DateTime now () {
            return new DateTime.from_glib (new GLib.DateTime.now_local ());
        }

        /**
         * Creates a date-time from components.
         *
         * @param year year value.
         * @param month month value (1-12).
         * @param day day value (1-31).
         * @param hour hour value (0-23).
         * @param min minute value (0-59).
         * @param sec second value (0-59).
         * @return created date-time.
         */
        public static DateTime of (int year,
                                   int month,
                                   int day,
                                   int hour,
                                   int min,
                                   int sec) {
            GLib.DateTime ? dt = new GLib.DateTime.local (year,
                                                          month,
                                                          day,
                                                          hour,
                                                          min,
                                                          (double) sec);
            if (dt == null) {
                error ("Invalid date-time components");
            }
            return new DateTime.from_glib (dt);
        }

        /**
         * Parses text into DateTime.
         *
         * Supported formats are "%Y-%m-%d %H:%M:%S" and "%Y-%m-%dT%H:%M:%S".
         * Returns null for unsupported format or invalid text.
         *
         * @param s input text.
         * @param format format text.
         * @return parsed date-time or null.
         */
        public static DateTime ? parse (string s, string format) {
            string iso_text;
            if (format == "%Y-%m-%d %H:%M:%S") {
                iso_text = s.replace (" ", "T");
            } else if (format == "%Y-%m-%dT%H:%M:%S") {
                iso_text = s;
            } else {
                return null;
            }

            GLib.DateTime ? dt = new GLib.DateTime.from_iso8601 (
                iso_text,
                new GLib.TimeZone.local ()
            );
            if (dt == null) {
                return null;
            }
            return new DateTime.from_glib (dt.to_local ());
        }

        /**
         * Formats date-time with strftime format.
         *
         * @param format format text.
         * @return formatted string.
         */
        public string format (string format) {
            return _dt.format (format);
        }

        /**
         * Returns year.
         *
         * @return year value.
         */
        public int year () {
            return _dt.get_year ();
        }

        /**
         * Returns month.
         *
         * @return month value.
         */
        public int month () {
            return _dt.get_month ();
        }

        /**
         * Returns day.
         *
         * @return day value.
         */
        public int day () {
            return _dt.get_day_of_month ();
        }

        /**
         * Returns hour.
         *
         * @return hour value.
         */
        public int hour () {
            return _dt.get_hour ();
        }

        /**
         * Returns minute.
         *
         * @return minute value.
         */
        public int minute () {
            return _dt.get_minute ();
        }

        /**
         * Returns second.
         *
         * @return second value.
         */
        public int second () {
            return _dt.get_second ();
        }

        /**
         * Returns day of week.
         *
         * Monday is 1 and Sunday is 7.
         *
         * @return day-of-week value.
         */
        public int dayOfWeek () {
            return _dt.get_day_of_week ();
        }

        /**
         * Returns a new date-time plus days.
         *
         * @param days days to add.
         * @return shifted date-time.
         */
        public DateTime plusDays (int days) {
            return new DateTime.from_glib (_dt.add_days (days));
        }

        /**
         * Returns a new date-time plus hours.
         *
         * @param hours hours to add.
         * @return shifted date-time.
         */
        public DateTime plusHours (int hours) {
            return new DateTime.from_glib (_dt.add_hours (hours));
        }

        /**
         * Returns a new date-time minus days.
         *
         * @param days days to subtract.
         * @return shifted date-time.
         */
        public DateTime minusDays (int days) {
            return new DateTime.from_glib (_dt.add_days (-days));
        }

        /**
         * Returns whether this is before other.
         *
         * @param other other date-time.
         * @return true if this is before other.
         */
        public bool isBefore (DateTime other) {
            return _dt.compare (other._dt) < 0;
        }

        /**
         * Returns whether this is after other.
         *
         * @param other other date-time.
         * @return true if this is after other.
         */
        public bool isAfter (DateTime other) {
            return _dt.compare (other._dt) > 0;
        }

        /**
         * Returns UNIX timestamp in seconds.
         *
         * @return UNIX timestamp.
         */
        public int64 toUnixTimestamp () {
            return _dt.to_unix ();
        }

        /**
         * Creates DateTime from UNIX timestamp.
         *
         * @param ts UNIX timestamp in seconds.
         * @return created date-time.
         */
        public static DateTime fromUnixTimestamp (int64 ts) {
            return new DateTime.from_glib (new GLib.DateTime.from_unix_local (ts));
        }

        /**
         * Returns difference from other as Duration.
         *
         * Positive value means this is later than other.
         *
         * @param other baseline date-time.
         * @return difference duration (second precision).
         */
        public Duration diff (DateTime other) {
            int64 diff_secs = _dt.difference (other._dt) / GLib.TimeSpan.SECOND;
            return Duration.ofSeconds (diff_secs);
        }
    }
}
