using Vala.Lang;
/**
 * Vala.Io namespace provides file I/O, path manipulation, and string utility APIs.
 */
namespace Vala.Io {
    /**
     * Strings class is a collection of static APIs for manipulating string.
     *
     * All methods are static and null-safe. Inspired by Java's String utilities,
     * Go's strings package, and Python's str methods.
     */
    public class Strings : GLib.Object {
        /**
         * Check whether string is null or empty.
         *
         * Example:
         * {{{
         *     assert (Strings.isNullOrEmpty (null) == true);
         *     assert (Strings.isNullOrEmpty ("") == true);
         *     assert (Strings.isNullOrEmpty ("hello") == false);
         * }}}
         *
         * @param str string for checking.
         * @return true if string is null or empty, false otherwise.
         */
        public static bool isNullOrEmpty (string ? str) {
            return (Objects.isNull (str)) || (str == "");
        }

        /**
         * Returns whether the string contains only whitespace characters or is null/empty.
         *
         * Example:
         * {{{
         *     assert (Strings.isBlank (null) == true);
         *     assert (Strings.isBlank ("   ") == true);
         *     assert (Strings.isBlank (" hi ") == false);
         * }}}
         *
         * @param s string for checking.
         * @return true if string is null, empty, or contains only whitespace.
         */
        public static bool isBlank (string ? s) {
            if (isNullOrEmpty (s)) {
                return true;
            }
            for (int i = 0; i < s.length; i++) {
                if (!s.get_char (i).isspace ()) {
                    return false;
                }
            }
            return true;
        }

        /**
         * Returns whether the string contains only digit characters (0-9).
         *
         * Example:
         * {{{
         *     assert (Strings.isNumeric ("12345") == true);
         *     assert (Strings.isNumeric ("12.3") == false);
         *     assert (Strings.isNumeric ("") == false);
         * }}}
         *
         * @param s string for checking.
         * @return true if string is non-empty and all characters are digits.
         */
        public static bool isNumeric (string ? s) {
            if (isNullOrEmpty (s)) {
                return false;
            }
            for (int i = 0; i < s.length; i++) {
                if (!s.get_char (i).isdigit ()) {
                    return false;
                }
            }
            return true;
        }

        /**
         * Returns whether the string contains only alphabetic characters (a-z, A-Z).
         *
         * Example:
         * {{{
         *     assert (Strings.isAlpha ("Hello") == true);
         *     assert (Strings.isAlpha ("Hello1") == false);
         * }}}
         *
         * @param s string for checking.
         * @return true if string is non-empty and all characters are alphabetic.
         */
        public static bool isAlpha (string ? s) {
            if (isNullOrEmpty (s)) {
                return false;
            }
            for (int i = 0; i < s.length; i++) {
                if (!s.get_char (i).isalpha ()) {
                    return false;
                }
            }
            return true;
        }

        /**
         * Returns whether the string contains only alphanumeric characters.
         *
         * Example:
         * {{{
         *     assert (Strings.isAlphaNumeric ("Hello123") == true);
         *     assert (Strings.isAlphaNumeric ("Hello 123") == false);
         * }}}
         *
         * @param s string for checking.
         * @return true if string is non-empty and all characters are alphanumeric.
         */
        public static bool isAlphaNumeric (string ? s) {
            if (isNullOrEmpty (s)) {
                return false;
            }
            for (int i = 0; i < s.length; i++) {
                if (!s.get_char (i).isalnum ()) {
                    return false;
                }
            }
            return true;
        }

        /**
         * Remove whitespace and tabs at the beginning and end of the string.
         *
         * Example:
         * {{{
         *     assert (Strings.trimSpace ("  hello  ") == "hello");
         * }}}
         *
         * @param str string to be trimmed
         * @return string after trimming. If str is null, returns empty string.
         */
        public static string trimSpace (string str) {
            if (Objects.isNull (str)) {
                return "";
            }

            int start = 0;
            int end = 0;
            string now;
            for (int i = 0; i < str.length; i++) {
                now = str.get_char (i).to_string ();
                if (now != " " && now != "\t") {
                    start = i;
                    break;
                }
            }

            for (int i = str.length - 1; i >= 0; i--) {
                now = str.get_char (i).to_string ();
                if (now != " " && now != "\t") {
                    end = i;
                    break;
                }
            }

            string tmp = "";
            for (int i = start; i <= end; i++) {
                tmp += str.get_char (i).to_string ();
            }
            return tmp.dup ();
        }

        /**
         * Remove the specified characters from the left side of the string.
         *
         * Example:
         * {{{
         *     assert (Strings.trimLeft ("xxyhello", "xy") == "hello");
         * }}}
         *
         * @param s the string to trim.
         * @param cutset characters to remove from the left.
         * @return trimmed string.
         */
        public static string trimLeft (string ? s, string cutset) {
            if (isNullOrEmpty (s)) {
                return "";
            }
            int start = 0;
            for (int i = 0; i < s.length; i++) {
                if (!cutset.contains (s.get_char (i).to_string ())) {
                    start = i;
                    break;
                }
                if (i == s.length - 1) {
                    return "";
                }
            }
            return s.substring (start);
        }

        /**
         * Remove the specified characters from the right side of the string.
         *
         * Example:
         * {{{
         *     assert (Strings.trimRight ("helloxyy", "xy") == "hello");
         * }}}
         *
         * @param s the string to trim.
         * @param cutset characters to remove from the right.
         * @return trimmed string.
         */
        public static string trimRight (string ? s, string cutset) {
            if (isNullOrEmpty (s)) {
                return "";
            }
            int end = s.length - 1;
            for (int i = s.length - 1; i >= 0; i--) {
                if (!cutset.contains (s.get_char (i).to_string ())) {
                    end = i;
                    break;
                }
                if (i == 0) {
                    return "";
                }
            }
            return s.substring (0, end + 1);
        }

        /**
         * Remove the specified prefix from the string if present.
         *
         * Example:
         * {{{
         *     assert (Strings.trimPrefix ("HelloWorld", "Hello") == "World");
         *     assert (Strings.trimPrefix ("HelloWorld", "Bye") == "HelloWorld");
         * }}}
         *
         * @param s the string.
         * @param prefix the prefix to remove.
         * @return string with prefix removed, or original if prefix not found.
         */
        public static string trimPrefix (string ? s, string prefix) {
            if (isNullOrEmpty (s)) {
                return "";
            }
            if (s.has_prefix (prefix)) {
                return s.substring (prefix.length);
            }
            return s;
        }

        /**
         * Remove the specified suffix from the string if present.
         *
         * Example:
         * {{{
         *     assert (Strings.trimSuffix ("HelloWorld", "World") == "Hello");
         *     assert (Strings.trimSuffix ("HelloWorld", "Bye") == "HelloWorld");
         * }}}
         *
         * @param s the string.
         * @param suffix the suffix to remove.
         * @return string with suffix removed, or original if suffix not found.
         */
        public static string trimSuffix (string ? s, string suffix) {
            if (isNullOrEmpty (s)) {
                return "";
            }
            if (s.has_suffix (suffix)) {
                return s.substring (0, s.length - suffix.length);
            }
            return s;
        }

        /**
         * Returns whether substr is included in the string.
         *
         * Example:
         * {{{
         *     assert (Strings.contains ("hello world", "world") == true);
         *     assert (Strings.contains ("hello", "xyz") == false);
         * }}}
         *
         * @param s the string to be searched.
         * @param substr search keyword.
         * @return true if substr is included, false otherwise.
         */
        public static bool contains (string ? s, string ? substr) {
            if (isNullOrEmpty (s) || isNullOrEmpty (substr)) {
                return false;
            }
            return s.contains (substr);
        }

        /**
         * Returns whether the string starts with the specified prefix.
         *
         * Example:
         * {{{
         *     assert (Strings.startsWith ("HelloWorld", "Hello") == true);
         *     assert (Strings.startsWith ("HelloWorld", "World") == false);
         * }}}
         *
         * @param s the string to check.
         * @param prefix the prefix.
         * @return true if s starts with prefix.
         */
        public static bool startsWith (string ? s, string ? prefix) {
            if (isNullOrEmpty (s) || isNullOrEmpty (prefix)) {
                return false;
            }
            return s.has_prefix (prefix);
        }

        /**
         * Returns whether the string ends with the specified suffix.
         *
         * Example:
         * {{{
         *     assert (Strings.endsWith ("HelloWorld", "World") == true);
         *     assert (Strings.endsWith ("HelloWorld", "Hello") == false);
         * }}}
         *
         * @param s the string to check.
         * @param suffix the suffix.
         * @return true if s ends with suffix.
         */
        public static bool endsWith (string ? s, string ? suffix) {
            if (isNullOrEmpty (s) || isNullOrEmpty (suffix)) {
                return false;
            }
            return s.has_suffix (suffix);
        }

        /**
         * Convert the string to upper case.
         *
         * Example:
         * {{{
         *     assert (Strings.toUpperCase ("hello") == "HELLO");
         * }}}
         *
         * @param s the string to convert.
         * @return upper-cased string, or empty string if null.
         */
        public static string toUpperCase (string ? s) {
            if (isNullOrEmpty (s)) {
                return "";
            }
            return s.up ();
        }

        /**
         * Convert the string to lower case.
         *
         * Example:
         * {{{
         *     assert (Strings.toLowerCase ("HELLO") == "hello");
         * }}}
         *
         * @param s the string to convert.
         * @return lower-cased string, or empty string if null.
         */
        public static string toLowerCase (string ? s) {
            if (isNullOrEmpty (s)) {
                return "";
            }
            return s.down ();
        }

        /**
         * Replace all occurrences of old_str with new_str.
         *
         * Example:
         * {{{
         *     assert (Strings.replace ("hello world", "world", "vala") == "hello vala");
         * }}}
         *
         * @param s the original string.
         * @param old_str the substring to find.
         * @param new_str the replacement string.
         * @return string with all replacements applied.
         */
        public static string replace (string ? s, string old_str, string new_str) {
            if (isNullOrEmpty (s)) {
                return "";
            }
            return s.replace (old_str, new_str);
        }

        /**
         * Repeat the string the specified number of times.
         *
         * Example:
         * {{{
         *     assert (Strings.repeat ("ab", 3) == "ababab");
         *     assert (Strings.repeat ("x", 0) == "");
         * }}}
         *
         * @param s the string to repeat.
         * @param count the number of times to repeat (must be >= 0).
         * @return repeated string.
         */
        public static string repeat (string ? s, int count) {
            if (isNullOrEmpty (s) || count <= 0) {
                return "";
            }
            var sb = new GLib.StringBuilder.sized (s.length * count);
            for (int i = 0; i < count; i++) {
                sb.append (s);
            }
            return sb.str;
        }

        /**
         * Reverse the string.
         *
         * Example:
         * {{{
         *     assert (Strings.reverse ("hello") == "olleh");
         *     assert (Strings.reverse ("a") == "a");
         * }}}
         *
         * @param s the string to reverse.
         * @return reversed string.
         */
        public static string reverse (string ? s) {
            if (isNullOrEmpty (s)) {
                return "";
            }
            return s.reverse ();
        }

        /**
         * Pad the string on the left side to the specified length.
         *
         * Example:
         * {{{
         *     assert (Strings.padLeft ("42", 5, '0') == "00042");
         * }}}
         *
         * @param s the string to pad.
         * @param len the desired total length.
         * @param pad the padding character.
         * @return padded string.
         */
        public static string padLeft (string ? s, int len, char pad) {
            if (Objects.isNull (s)) {
                s = "";
            }
            if (s.length >= len) {
                return s;
            }
            var sb = new GLib.StringBuilder.sized (len);
            for (int i = 0; i < len - s.length; i++) {
                sb.append_c (pad);
            }
            sb.append (s);
            return sb.str;
        }

        /**
         * Pad the string on the right side to the specified length.
         *
         * Example:
         * {{{
         *     assert (Strings.padRight ("hi", 5, '.') == "hi...");
         * }}}
         *
         * @param s the string to pad.
         * @param len the desired total length.
         * @param pad the padding character.
         * @return padded string.
         */
        public static string padRight (string ? s, int len, char pad) {
            if (Objects.isNull (s)) {
                s = "";
            }
            if (s.length >= len) {
                return s;
            }
            var sb = new GLib.StringBuilder.sized (len);
            sb.append (s);
            for (int i = 0; i < len - s.length; i++) {
                sb.append_c (pad);
            }
            return sb.str;
        }

        /**
         * Center the string within the specified width using the pad character.
         *
         * Example:
         * {{{
         *     assert (Strings.center ("hi", 6, '*') == "**hi**");
         * }}}
         *
         * @param s the string to center.
         * @param width the desired total width.
         * @param pad the padding character.
         * @return centered string.
         */
        public static string center (string ? s, int width, char pad) {
            if (Objects.isNull (s)) {
                s = "";
            }
            if (s.length >= width) {
                return s;
            }
            int total_pad = width - s.length;
            int left_pad = total_pad / 2;
            int right_pad = total_pad - left_pad;
            var sb = new GLib.StringBuilder.sized (width);
            for (int i = 0; i < left_pad; i++) {
                sb.append_c (pad);
            }
            sb.append (s);
            for (int i = 0; i < right_pad; i++) {
                sb.append_c (pad);
            }
            return sb.str;
        }

        /**
         * Returns the index of the first occurrence of substr in s.
         * Returns -1 if not found.
         *
         * Example:
         * {{{
         *     assert (Strings.indexOf ("hello world", "world") == 6);
         *     assert (Strings.indexOf ("hello", "xyz") == -1);
         * }}}
         *
         * @param s the string to search in.
         * @param substr the substring to find.
         * @return index of first occurrence, or -1 if not found.
         */
        public static int indexOf (string ? s, string ? substr) {
            if (isNullOrEmpty (s) || isNullOrEmpty (substr)) {
                return -1;
            }
            return s.index_of (substr);
        }

        /**
         * Returns the index of the last occurrence of substr in s.
         * Returns -1 if not found.
         *
         * Example:
         * {{{
         *     assert (Strings.lastIndexOf ("hello hello", "hello") == 6);
         *     assert (Strings.lastIndexOf ("hello", "xyz") == -1);
         * }}}
         *
         * @param s the string to search in.
         * @param substr the substring to find.
         * @return index of last occurrence, or -1 if not found.
         */
        public static int lastIndexOf (string ? s, string ? substr) {
            if (isNullOrEmpty (s) || isNullOrEmpty (substr)) {
                return -1;
            }
            return s.last_index_of (substr);
        }

        /**
         * Count the number of non-overlapping occurrences of substr in s.
         *
         * Example:
         * {{{
         *     assert (Strings.count ("abcabc", "abc") == 2);
         *     assert (Strings.count ("hello", "xyz") == 0);
         * }}}
         *
         * @param s the string to search in.
         * @param substr the substring to count.
         * @return number of occurrences.
         */
        public static int count (string ? s, string ? substr) {
            if (isNullOrEmpty (s) || isNullOrEmpty (substr)) {
                return 0;
            }
            int n = 0;
            int pos = 0;
            while (true) {
                int idx = s.index_of (substr, pos);
                if (idx < 0) {
                    break;
                }
                n++;
                pos = idx + substr.length;
            }
            return n;
        }

        /**
         * Join an array of strings with the specified separator.
         *
         * Example:
         * {{{
         *     assert (Strings.join (", ", {"a", "b", "c"}) == "a, b, c");
         * }}}
         *
         * @param separator the separator string.
         * @param parts the strings to join.
         * @return joined string.
         */
        public static string join (string separator, string[] parts) {
            return string.joinv (separator, parts);
        }

        /**
         * Split the string by the specified delimiter.
         *
         * Example:
         * {{{
         *     string[] parts = Strings.split ("a,b,c", ",");
         *     assert (parts.length == 3);
         *     assert (parts[0] == "a");
         * }}}
         *
         * @param s the string to split.
         * @param delimiter the delimiter.
         * @return array of substrings.
         */
        public static string[] split (string ? s, string delimiter) {
            if (isNullOrEmpty (s)) {
                return new string[0];
            }
            return s.split (delimiter);
        }

        /**
         * Split the string by the specified number of characters and returns it as an
         * array of strings.
         *
         * @param str character string to be split.
         * @param num number of characters per chunk.
         * @return array of split strings.
         */
        public static string[] splitByNum (string str, uint num) {
            if (Objects.isNull (str) || num == 0) {
                return new string[1];
            }

            string[] strs = {};
            string tmp = "";
            for (int i = 0; i < str.length; i++) {
                tmp += str.get_char (i).to_string ();
                if (i != 0 && i % num == 0) {
                    strs += tmp;
                    tmp = "";
                }
            }
            strs += tmp;
            return strs;
        }

        /**
         * Returns the substring from start (inclusive) to end (exclusive).
         *
         * Example:
         * {{{
         *     assert (Strings.substring ("hello world", 0, 5) == "hello");
         * }}}
         *
         * @param s the string.
         * @param start start index (inclusive).
         * @param end end index (exclusive).
         * @return the substring, or empty string if indices are invalid.
         */
        public static string substring (string ? s, int start, int end) {
            if (isNullOrEmpty (s)) {
                return "";
            }
            if (start < 0) {
                start = 0;
            }
            if (end > s.length) {
                end = s.length;
            }
            if (start >= end) {
                return "";
            }
            return s.slice (start, end);
        }

        /**
         * Capitalize the first character of the string.
         *
         * Example:
         * {{{
         *     assert (Strings.capitalize ("hello") == "Hello");
         *     assert (Strings.capitalize ("Hello") == "Hello");
         * }}}
         *
         * @param s the string.
         * @return string with first character uppercased.
         */
        public static string capitalize (string ? s) {
            if (isNullOrEmpty (s)) {
                return "";
            }
            if (s.length == 1) {
                return s.up ();
            }
            return s.get_char (0).toupper ().to_string () + s.substring (1);
        }

        /**
         * Convert the string to camelCase.
         * Splits on whitespace, hyphens, and underscores.
         *
         * Example:
         * {{{
         *     assert (Strings.toCamelCase ("hello_world") == "helloWorld");
         *     assert (Strings.toCamelCase ("Hello World") == "helloWorld");
         * }}}
         *
         * @param s the string.
         * @return camelCase string.
         */
        public static string toCamelCase (string ? s) {
            if (isNullOrEmpty (s)) {
                return "";
            }
            string normalized = s.replace ("-", " ").replace ("_", " ");
            string[] words = normalized.split (" ");
            var sb = new GLib.StringBuilder ();
            bool first = true;
            foreach (string w in words) {
                if (isNullOrEmpty (w)) {
                    continue;
                }
                if (first) {
                    sb.append (w.down ());
                    first = false;
                } else {
                    sb.append (w.get_char (0).toupper ().to_string ());
                    if (w.length > 1) {
                        sb.append (w.substring (1).down ());
                    }
                }
            }
            return sb.str;
        }

        /**
         * Convert the string to snake_case.
         * Splits on whitespace, hyphens, and camelCase boundaries.
         *
         * Example:
         * {{{
         *     assert (Strings.toSnakeCase ("helloWorld") == "hello_world");
         *     assert (Strings.toSnakeCase ("Hello World") == "hello_world");
         * }}}
         *
         * @param s the string.
         * @return snake_case string.
         */
        public static string toSnakeCase (string ? s) {
            if (isNullOrEmpty (s)) {
                return "";
            }
            var sb = new GLib.StringBuilder ();
            for (int i = 0; i < s.length; i++) {
                unichar c = s.get_char (i);
                if (c == ' ' || c == '-' || c == '_') {
                    if (sb.len > 0 && sb.str.get_char (sb.len - 1) != '_') {
                        sb.append_c ('_');
                    }
                } else if (c.isupper () && i > 0) {
                    unichar prev = s.get_char (i - 1);
                    if (prev != ' ' && prev != '-' && prev != '_' && !prev.isupper ()) {
                        sb.append_c ('_');
                    }
                    sb.append (c.tolower ().to_string ());
                } else {
                    sb.append (c.tolower ().to_string ());
                }
            }
            return sb.str;
        }

        /**
         * Convert the string to kebab-case.
         *
         * Example:
         * {{{
         *     assert (Strings.toKebabCase ("helloWorld") == "hello-world");
         *     assert (Strings.toKebabCase ("Hello World") == "hello-world");
         * }}}
         *
         * @param s the string.
         * @return kebab-case string.
         */
        public static string toKebabCase (string ? s) {
            return toSnakeCase (s).replace ("_", "-");
        }

        /**
         * Convert the string to PascalCase.
         *
         * Example:
         * {{{
         *     assert (Strings.toPascalCase ("hello_world") == "HelloWorld");
         * }}}
         *
         * @param s the string.
         * @return PascalCase string.
         */
        public static string toPascalCase (string ? s) {
            if (isNullOrEmpty (s)) {
                return "";
            }
            string camel = toCamelCase (s);
            if (isNullOrEmpty (camel)) {
                return "";
            }
            return camel.get_char (0).toupper ().to_string () + camel.substring (1);
        }

        /**
         * Capitalize the first letter of each word.
         *
         * Example:
         * {{{
         *     assert (Strings.title ("hello world") == "Hello World");
         * }}}
         *
         * @param s the string.
         * @return title-cased string.
         */
        public static string title (string ? s) {
            if (isNullOrEmpty (s)) {
                return "";
            }
            string[] words = s.split (" ");
            var result = new string[words.length];
            for (int i = 0; i < words.length; i++) {
                result[i] = capitalize (words[i]);
            }
            return string.joinv (" ", result);
        }

        /**
         * Compare two strings lexicographically.
         *
         * Example:
         * {{{
         *     assert (Strings.compareTo ("abc", "abd") < 0);
         *     assert (Strings.compareTo ("abc", "abc") == 0);
         *     assert (Strings.compareTo ("abd", "abc") > 0);
         * }}}
         *
         * @param a first string.
         * @param b second string.
         * @return negative if a < b, 0 if equal, positive if a > b.
         */
        public static int compareTo (string ? a, string ? b) {
            if (a == null && b == null) {
                return 0;
            }
            if (a == null) {
                return -1;
            }
            if (b == null) {
                return 1;
            }
            return GLib.strcmp (a, b);
        }

        /**
         * Compare two strings lexicographically, ignoring case.
         *
         * Example:
         * {{{
         *     assert (Strings.compareIgnoreCase ("ABC", "abc") == 0);
         * }}}
         *
         * @param a first string.
         * @param b second string.
         * @return negative if a < b, 0 if equal, positive if a > b (case-insensitive).
         */
        public static int compareIgnoreCase (string ? a, string ? b) {
            if (a == null && b == null) {
                return 0;
            }
            if (a == null) {
                return -1;
            }
            if (b == null) {
                return 1;
            }
            return GLib.strcmp (a.down (), b.down ());
        }

        /**
         * Returns whether two strings are equal, ignoring case.
         *
         * Example:
         * {{{
         *     assert (Strings.equalsIgnoreCase ("Hello", "hello") == true);
         * }}}
         *
         * @param a first string.
         * @param b second string.
         * @return true if strings are equal (case-insensitive).
         */
        public static bool equalsIgnoreCase (string ? a, string ? b) {
            return compareIgnoreCase (a, b) == 0;
        }

        /**
         * Split the string by newlines and return as an array.
         *
         * Example:
         * {{{
         *     string[] result = Strings.lines ("a\nb\nc");
         *     assert (result.length == 3);
         * }}}
         *
         * @param s the string.
         * @return array of lines.
         */
        public static string[] lines (string ? s) {
            if (isNullOrEmpty (s)) {
                return new string[0];
            }
            return s.split ("\n");
        }

        /**
         * Split the string by whitespace and return non-empty tokens.
         * Equivalent to Go's strings.Fields.
         *
         * Example:
         * {{{
         *     string[] result = Strings.words ("  hello   world  ");
         *     assert (result.length == 2);
         *     assert (result[0] == "hello");
         * }}}
         *
         * @param s the string.
         * @return array of words.
         */
        public static string[] words (string ? s) {
            if (isNullOrEmpty (s)) {
                return new string[0];
            }
            string[] parts = s.split (" ");
            string[] result = {};
            foreach (string p in parts) {
                string trimmed = trimSpace (p);
                if (!isNullOrEmpty (trimmed)) {
                    result += trimmed;
                }
            }
            return result;
        }

        /**
         * Truncate the string to the specified maximum length, appending ellipsis if truncated.
         *
         * Example:
         * {{{
         *     assert (Strings.truncate ("Hello World", 8, "...") == "Hello...");
         * }}}
         *
         * @param s the string.
         * @param maxLen maximum length of result including ellipsis.
         * @param ellipsis the ellipsis string to append.
         * @return truncated string.
         */
        public static string truncate (string ? s, int maxLen, string ellipsis) {
            if (isNullOrEmpty (s)) {
                return "";
            }
            if (s.length <= maxLen) {
                return s;
            }
            if (maxLen <= ellipsis.length) {
                return ellipsis.substring (0, maxLen);
            }
            return s.substring (0, maxLen - ellipsis.length) + ellipsis;
        }

        /**
         * Wrap the string at the specified width by inserting newlines.
         *
         * Example:
         * {{{
         *     assert (Strings.wrap ("abcdef", 3) == "abc\ndef");
         * }}}
         *
         * @param s the string.
         * @param width the maximum line width.
         * @return wrapped string.
         */
        public static string wrap (string ? s, int width) {
            if (isNullOrEmpty (s) || width <= 0) {
                return s ?? "";
            }
            if (s.length <= width) {
                return s;
            }
            var sb = new GLib.StringBuilder ();
            int pos = 0;
            while (pos < s.length) {
                int end = pos + width;
                if (end > s.length) {
                    end = s.length;
                }
                if (pos > 0) {
                    sb.append ("\n");
                }
                sb.append (s.slice (pos, end));
                pos = end;
            }
            return sb.str;
        }
    }
}
