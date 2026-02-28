namespace Vala.Format {
    /**
     * Number formatting utilities.
     */
    public class NumberFormat : GLib.Object {
        /**
         * Formats integer with thousand separators.
         *
         * @param n source value.
         * @return formatted text.
         */
        public static string formatInt (int64 n) {
            string raw = n.to_string ();
            bool negative = raw.has_prefix ("-");
            string digits = negative ? raw.substring (1) : raw;
            string formatted = addThousandsSeparators (digits);
            return negative ? "-" + formatted : formatted;
        }

        /**
         * Formats double with thousand separators and precision.
         *
         * @param d source value.
         * @param precision decimal places.
         * @return formatted text.
         */
        public static string formatDouble (double d, int precision) {
            int p = precision;
            if (p < 0) {
                p = 0;
            }

            string raw = "%.*f".printf (p, d);
            int dot = raw.index_of_char ('.');
            if (dot < 0) {
                return formatIntString (raw);
            }

            string intPart = raw.substring (0, dot);
            string fracPart = raw.substring (dot + 1);
            return formatIntString (intPart) + "." + fracPart;
        }

        /**
         * Formats ratio as percent text.
         *
         * @param d ratio (e.g. 0.25 = 25%).
         * @return percent text.
         */
        public static string formatPercent (double d) {
            return formatDouble (d * 100.0, 2) + "%";
        }

        /**
         * Formats value as currency.
         *
         * @param d source value.
         * @param symbol currency symbol.
         * @return currency text.
         */
        public static string formatCurrency (double d, string symbol) {
            double absValue = GLib.Math.fabs (d);
            string amount = formatDouble (absValue, 2);
            if (d < 0) {
                return "-" + symbol + amount;
            }
            return symbol + amount;
        }

        /**
         * Formats byte size into human readable units.
         *
         * @param bytes byte size.
         * @return formatted text.
         */
        public static string formatBytes (int64 bytes) {
            string[] units = { "B", "KB", "MB", "GB", "TB", "PB", "EB" };
            bool negative = bytes < 0;
            uint64 absBytes = negative ? ((uint64) (~bytes) + 1) : (uint64) bytes;

            double value = (double) absBytes;
            int index = 0;

            while (value >= 1024.0 && index < units.length - 1) {
                value /= 1024.0;
                index++;
            }

            string text;
            if (index == 0) {
                text = absBytes.to_string () + " " + units[index];
                return negative ? "-" + text : text;
            }

            string formatted = "%.1f".printf (value);
            if (formatted.has_suffix (".0")) {
                formatted = formatted.substring (0, formatted.length - 2);
            }
            text = "%s %s".printf (formatted, units[index]);
            return negative ? "-" + text : text;
        }

        /**
         * Formats duration for display.
         *
         * @param d duration.
         * @return human readable duration.
         */
        public static string formatDuration (Vala.Time.Duration d) {
            return d.toString ();
        }

        /**
         * Returns English ordinal text.
         *
         * @param n source number.
         * @return ordinal text (e.g. 1st, 2nd).
         */
        public static string ordinal (int n) {
            int64 absValue = n < 0 ? -((int64) n) : (int64) n;
            int lastTwo = (int) (absValue % 100);
            string suffix = "th";

            if (lastTwo < 11 || lastTwo > 13) {
                switch ((int) (absValue % 10)) {
                    case 1:
                        suffix = "st";
                        break;
                    case 2:
                        suffix = "nd";
                        break;
                    case 3:
                        suffix = "rd";
                        break;
                    default:
                        suffix = "th";
                        break;
                }
            }

            return n.to_string () + suffix;
        }

        private static string formatIntString (string intText) {
            bool negative = intText.has_prefix ("-");
            string digits = negative ? intText.substring (1) : intText;
            string formatted = addThousandsSeparators (digits);
            return negative ? "-" + formatted : formatted;
        }

        private static string addThousandsSeparators (string digits) {
            if (digits.length <= 3) {
                return digits;
            }

            GLib.StringBuilder builder = new GLib.StringBuilder ();
            int first = digits.length % 3;
            if (first == 0) {
                first = 3;
            }

            builder.append (digits.substring (0, first));
            for (int i = first; i < digits.length; i += 3) {
                builder.append_c (',');
                builder.append (digits.substring (i, 3));
            }
            return builder.str;
        }
    }
}
