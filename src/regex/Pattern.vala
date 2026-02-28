namespace Vala.Regex {
    /**
     * Compiled regular expression wrapper.
     */
    public class Pattern : GLib.Object {
        private GLib.Regex _regex;

        private Pattern (GLib.Regex regex) {
            _regex = regex;
        }

        /**
         * Compiles regular expression.
         *
         * @param pattern regex pattern.
         * @return compiled pattern, or null when invalid.
         */
        public static Pattern ? compile (string pattern) {
            if (pattern.length == 0) {
                return null;
            }

            try {
                GLib.Regex regex = new GLib.Regex (pattern);
                return new Pattern (regex);
            } catch (GLib.RegexError e) {
                return null;
            }
        }

        /**
         * Returns true when entire input matches.
         *
         * @param input source text.
         * @return true when full match.
         */
        public bool matches (string input) {
            GLib.MatchInfo info;
            if (!_regex.match (input, 0, out info)) {
                return false;
            }

            int start = -1;
            int end = -1;
            if (!info.fetch_pos (0, out start, out end)) {
                return false;
            }
            return start == 0 && end == input.length;
        }

        /**
         * Returns whether any match exists.
         *
         * @param input source text.
         * @return true when at least one match exists.
         */
        public bool find (string input) {
            GLib.MatchInfo info;
            return _regex.match (input, 0, out info);
        }

        /**
         * Returns all matched substrings.
         *
         * @param input source text.
         * @return all matches in appearance order.
         */
        public string[] findAll (string input) {
            string[] results = {};

            GLib.MatchInfo info;
            if (!_regex.match (input, 0, out info)) {
                return results;
            }

            do {
                string ? match = info.fetch (0);
                if (match != null) {
                    results += match;
                }

                try {
                    if (!info.next ()) {
                        break;
                    }
                } catch (GLib.RegexError e) {
                    break;
                }
            } while (true);

            return results;
        }

        /**
         * Replaces first match only.
         *
         * @param input source text.
         * @param replacement replacement text.
         * @return replaced text.
         */
        public string replaceFirst (string input, string replacement) {
            GLib.MatchInfo info;
            if (!_regex.match (input, 0, out info)) {
                return input;
            }

            int start = -1;
            int end = -1;
            if (!info.fetch_pos (0, out start, out end)) {
                return input;
            }

            return input.substring (0, start) + replacement + input.substring (end);
        }

        /**
         * Replaces all matches.
         *
         * @param input source text.
         * @param replacement replacement text.
         * @return replaced text.
         */
        public string replaceAll (string input, string replacement) {
            try {
                return _regex.replace_literal (input, input.length, 0, replacement, 0);
            } catch (GLib.RegexError e) {
                return input;
            }
        }

        /**
         * Splits input by this pattern.
         *
         * @param input source text.
         * @return split segments.
         */
        public string[] split (string input) {
            return _regex.split (input, 0);
        }

        /**
         * Returns capture groups from first match.
         *
         * @param input source text.
         * @return capture groups (group 1..N), empty when no match.
         */
        public string[] groups (string input) {
            string[] result = {};

            GLib.MatchInfo info;
            if (!_regex.match (input, 0, out info)) {
                return result;
            }

            int count = info.get_match_count ();
            if (count <= 1) {
                return result;
            }

            for (int i = 1; i < count; i++) {
                string ? group = info.fetch (i);
                result += group ?? "";
            }
            return result;
        }
    }
}
