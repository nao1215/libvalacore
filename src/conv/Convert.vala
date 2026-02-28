namespace Vala.Conv {
    /**
     * Type conversion utility methods.
     */
    public class Convert : GLib.Object {
        /**
         * Converts string to int.
         *
         * @param s source text.
         * @return parsed integer, or null on failure.
         */
        public static int ? toInt (string s) {
            int value = 0;
            if (int.try_parse (s, out value)) {
                return value;
            }
            return null;
        }

        /**
         * Converts string to int64.
         *
         * @param s source text.
         * @return parsed int64, or null on failure.
         */
        public static int64 ? toInt64 (string s) {
            int64 value = 0;
            if (int64.try_parse (s, out value)) {
                return value;
            }
            return null;
        }

        /**
         * Converts string to double.
         *
         * @param s source text.
         * @return parsed double, or null on failure.
         */
        public static double ? toDouble (string s) {
            double value = 0.0;
            if (double.try_parse (s, out value)) {
                return value;
            }
            return null;
        }

        /**
         * Converts string to bool.
         *
         * Accepted values: "true", "false", "1", "0" (case-insensitive).
         *
         * @param s source text.
         * @return parsed bool, or null on failure.
         */
        public static bool ? toBool (string s) {
            string normalized = s.strip ().down ();
            if (normalized == "true" || normalized == "1") {
                return true;
            }
            if (normalized == "false" || normalized == "0") {
                return false;
            }
            return null;
        }

        /**
         * Converts int to string.
         *
         * @param n source value.
         * @return string representation.
         */
        public static string intToString (int n) {
            return n.to_string ();
        }

        /**
         * Converts double to string with precision.
         *
         * @param d source value.
         * @param precision decimal places. Negative values are treated as 0.
         * @return string representation.
         */
        public static string doubleToString (double d, int precision) {
            int p = precision;
            if (p < 0) {
                p = 0;
            }
            return "%.*f".printf (p, d);
        }

        /**
         * Converts bool to string.
         *
         * @param b source value.
         * @return "true" or "false".
         */
        public static string boolToString (bool b) {
            return b.to_string ();
        }

        /**
         * Converts int to hexadecimal string.
         *
         * @param n source value.
         * @return lowercase hexadecimal string (signed for negative values).
         */
        public static string intToHex (int n) {
            return intToBase (n, 16, "0123456789abcdef");
        }

        /**
         * Converts int to octal string.
         *
         * @param n source value.
         * @return octal string (signed for negative values).
         */
        public static string intToOctal (int n) {
            return intToBase (n, 8, "01234567");
        }

        /**
         * Converts int to binary string.
         *
         * @param n source value.
         * @return binary string.
         */
        public static string intToBinary (int n) {
            return intToBase (n, 2, "01");
        }

        private static string intToBase (int n, uint64 radix, string digits) {
            if (n == 0) {
                return "0";
            }

            bool negative = n < 0;
            uint64 value = negative ? (uint64) (-(int64) n) : (uint64) n;
            GLib.StringBuilder builder = new GLib.StringBuilder ();

            while (value > 0) {
                builder.prepend_c ((char) digits[(int) (value % radix)]);
                value /= radix;
            }

            if (negative) {
                builder.prepend_c ('-');
            }

            return builder.str;
        }
    }
}
