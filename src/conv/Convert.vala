using Vala.Collections;

namespace Vala.Conv {
    /**
     * Recoverable conversion errors.
     */
    public errordomain ConvertError {
        PARSE
    }

    /**
     * Type conversion utility methods.
     */
    public class Convert : GLib.Object {
        /**
         * Converts string to int.
         *
         * @param s source text.
         * @return Result.ok(parsed integer), or
         *         Result.error(ConvertError.PARSE) when parsing fails.
         */
        public static Result<int ?, GLib.Error> toInt (string s) {
            int value = 0;
            if (int.try_parse (s, out value)) {
                return Result.ok<int ?, GLib.Error> (value);
            }
            return Result.error<int ?, GLib.Error> (
                new ConvertError.PARSE ("failed to parse int: %s".printf (s))
            );
        }

        /**
         * Converts string to int64.
         *
         * @param s source text.
         * @return Result.ok(parsed int64), or
         *         Result.error(ConvertError.PARSE) when parsing fails.
         */
        public static Result<int64 ?, GLib.Error> toInt64 (string s) {
            int64 value = 0;
            if (int64.try_parse (s, out value)) {
                return Result.ok<int64 ?, GLib.Error> (value);
            }
            return Result.error<int64 ?, GLib.Error> (
                new ConvertError.PARSE ("failed to parse int64: %s".printf (s))
            );
        }

        /**
         * Converts string to double.
         *
         * @param s source text.
         * @return Result.ok(parsed double), or
         *         Result.error(ConvertError.PARSE) when parsing fails.
         */
        public static Result<double ?, GLib.Error> toDouble (string s) {
            double value = 0.0;
            if (double.try_parse (s, out value)) {
                return Result.ok<double ?, GLib.Error> (value);
            }
            return Result.error<double ?, GLib.Error> (
                new ConvertError.PARSE ("failed to parse double: %s".printf (s))
            );
        }

        /**
         * Converts string to bool.
         *
         * Accepted values: "true", "false", "1", "0" (case-insensitive).
         *
         * @param s source text.
         * @return Result.ok(parsed bool), or
         *         Result.error(ConvertError.PARSE) when parsing fails.
         */
        public static Result<bool ?, GLib.Error> toBool (string s) {
            string normalized = s.strip ().down ();
            if (normalized == "true" || normalized == "1") {
                return Result.ok<bool ?, GLib.Error> (true);
            }
            if (normalized == "false" || normalized == "0") {
                return Result.ok<bool ?, GLib.Error> (false);
            }
            return Result.error<bool ?, GLib.Error> (
                new ConvertError.PARSE ("failed to parse bool: %s".printf (s))
            );
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
            uint64 value = negative ? (uint64) (-(int64) n) : (uint64) n; // vala-lint=space-before-paren
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
