namespace Vala.Text {
    /**
     * Static utility methods for regular expressions.
     */
    public class Regex : GLib.Object {
        /**
         * Returns true when the pattern matches the input string.
         *
         * Invalid patterns return false.
         *
         * @param s input string.
         * @param pattern regular expression pattern.
         * @return true if matched.
         */
        public static bool matches (string s, string pattern) {
            try {
                GLib.Regex regex = new GLib.Regex (pattern);
                return regex.match (s);
            } catch (GLib.RegexError e) {
                return false;
            }
        }

        /**
         * Replaces all regex matches with replacement text.
         *
         * Invalid patterns return the original string.
         *
         * @param s input string.
         * @param pattern regular expression pattern.
         * @param repl replacement text.
         * @return replaced string.
         */
        public static string replaceAll (string s, string pattern, string repl) {
            try {
                GLib.Regex regex = new GLib.Regex (pattern);
                return regex.replace (s, s.length, 0, repl);
            } catch (GLib.RegexError e) {
                return s;
            }
        }

        /**
         * Splits a string by a regex pattern.
         *
         * Invalid patterns return an empty array.
         *
         * @param s input string.
         * @param pattern regular expression pattern.
         * @return split tokens.
         */
        public static string[] split (string s, string pattern) {
            try {
                GLib.Regex regex = new GLib.Regex (pattern);
                return regex.split (s);
            } catch (GLib.RegexError e) {
                string[] empty = {};
                return empty;
            }
        }
    }
}
