namespace Vala.Time {
    /**
     * Static utility methods for DateTime operations.
     */
    public class Dates : GLib.Object {
        /**
         * Returns current local date-time.
         *
         * Example:
         * {{{
         *     Vala.Time.DateTime now = Dates.now ();
         *     assert (now.toUnixTimestamp () > 0);
         * }}}
         *
         * @return current date-time.
         */
        public static DateTime now () {
            return DateTime.now ();
        }

        /**
         * Parses date-time text with the given format.
         *
         * Example:
         * {{{
         *     Vala.Time.DateTime? dt = Dates.parse ("2024-05-10 08:30:45", "%Y-%m-%d %H:%M:%S");
         *     assert (dt != null);
         * }}}
         *
         * @param s date-time text.
         * @param fmt format text.
         * @return parsed date-time, or null when parsing fails.
         */
        public static DateTime ? parse (string s, string fmt) {
            if (s.length == 0 || fmt.length == 0) {
                return null;
            }
            return DateTime.parse (s, fmt);
        }

        /**
         * Formats date-time using strftime-style format text.
         *
         * Example:
         * {{{
         *     Vala.Time.DateTime dt = DateTime.of (2024, 5, 10, 8, 30, 45);
         *     assert (Dates.format (dt, "%Y-%m-%d") == "2024-05-10");
         * }}}
         *
         * @param t date-time value.
         * @param fmt format text.
         * @return formatted date-time text.
         */
        public static string format (DateTime t, string fmt) {
            if (fmt.length == 0) {
                return "";
            }
            return t.format (fmt);
        }

        /**
         * Adds days to a date-time.
         *
         * Example:
         * {{{
         *     Vala.Time.DateTime dt = DateTime.of (2024, 2, 28, 0, 0, 0);
         *     assert (Dates.addDays (dt, 1).format ("%Y-%m-%d") == "2024-02-29");
         * }}}
         *
         * @param t date-time value.
         * @param days days to add.
         * @return shifted date-time.
         */
        public static DateTime addDays (DateTime t, int days) {
            return t.plusDays (days);
        }

        /**
         * Returns whether the given year is a leap year.
         *
         * Example:
         * {{{
         *     assert (Dates.isLeapYear (2024) == true);
         *     assert (Dates.isLeapYear (1900) == false);
         * }}}
         *
         * @param year target year.
         * @return true when leap year.
         */
        public static bool isLeapYear (int year) {
            if (year % 400 == 0) {
                return true;
            }
            if (year % 100 == 0) {
                return false;
            }
            return year % 4 == 0;
        }
    }
}
