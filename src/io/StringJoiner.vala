namespace Vala.Io {
    /**
     * StringJoiner constructs a sequence of characters separated by a
     * delimiter and optionally starting with a prefix and ending with a
     * suffix. This is equivalent to Java's StringJoiner.
     *
     * Example:
     * {{{
     *     var joiner = new StringJoiner (", ", "[", "]");
     *     joiner.add ("a");
     *     joiner.add ("b");
     *     joiner.add ("c");
     *     assert (joiner.toString () == "[a, b, c]");
     * }}}
     */
    public class StringJoiner : GLib.Object {
        private string _delimiter;
        private string _prefix;
        private string _suffix;
        private string ? _emptyValue;
        private GLib.List<string> _elements;

        /**
         * Constructs a StringJoiner with the given delimiter, prefix,
         * and suffix.
         *
         * Example:
         * {{{
         *     var joiner = new StringJoiner (", ", "(", ")");
         * }}}
         *
         * @param delimiter the separator placed between elements.
         * @param prefix the string prepended to the result.
         * @param suffix the string appended to the result.
         */
        public StringJoiner (string delimiter, string prefix = "", string suffix = "") {
            _delimiter = delimiter;
            _prefix = prefix;
            _suffix = suffix;
            _emptyValue = null;
            _elements = new GLib.List<string> ();
        }

        /**
         * Adds an element to this joiner.
         *
         * Example:
         * {{{
         *     var joiner = new StringJoiner (", ");
         *     joiner.add ("hello");
         *     joiner.add ("world");
         *     assert (joiner.toString () == "hello, world");
         * }}}
         *
         * @param element the element to add.
         * @return this StringJoiner for chaining.
         */
        public StringJoiner add (string element) {
            _elements.append (element);
            return this;
        }

        /**
         * Merges the contents of another StringJoiner into this one.
         * The other joiner's elements are added without its prefix and
         * suffix, using its delimiter to join them as a single element.
         *
         * Example:
         * {{{
         *     var j1 = new StringJoiner (", ", "[", "]");
         *     j1.add ("a");
         *     var j2 = new StringJoiner ("-");
         *     j2.add ("b");
         *     j2.add ("c");
         *     j1.merge (j2);
         *     assert (j1.toString () == "[a, b-c]");
         * }}}
         *
         * @param other the StringJoiner to merge from.
         * @return this StringJoiner for chaining.
         */
        public StringJoiner merge (StringJoiner other) {
            if (other._elements.length () > 0) {
                var merged = joinElements (other._elements, other._delimiter);
                _elements.append (merged);
            }
            return this;
        }

        /**
         * Sets the value to return from toString() when no elements have
         * been added. By default, the empty value is prefix + suffix.
         *
         * Example:
         * {{{
         *     var joiner = new StringJoiner (", ", "[", "]");
         *     joiner.setEmptyValue ("EMPTY");
         *     assert (joiner.toString () == "EMPTY");
         * }}}
         *
         * @param value the string to use when no elements are present.
         * @return this StringJoiner for chaining.
         */
        public StringJoiner setEmptyValue (string value) {
            _emptyValue = value;
            return this;
        }

        /**
         * Returns the length of the string that would be produced by
         * toString().
         *
         * Example:
         * {{{
         *     var joiner = new StringJoiner (", ", "[", "]");
         *     joiner.add ("ab");
         *     assert (joiner.length () == 4);  // "[ab]"
         * }}}
         *
         * @return the length of the joined string.
         */
        public int length () {
            return toString ().length;
        }

        /**
         * Returns the joined string with prefix, delimiter-separated
         * elements, and suffix. If no elements have been added, returns
         * the empty value (or prefix + suffix if none was set).
         *
         * Example:
         * {{{
         *     var joiner = new StringJoiner (", ", "[", "]");
         *     joiner.add ("x");
         *     joiner.add ("y");
         *     assert (joiner.toString () == "[x, y]");
         * }}}
         *
         * @return the joined string.
         */
        public string toString () {
            if (_elements.length () == 0) {
                if (_emptyValue != null) {
                    return _emptyValue;
                }
                return _prefix + _suffix;
            }
            return _prefix + joinElements (_elements, _delimiter) + _suffix;
        }

        private static string joinElements (GLib.List<string> elements, string delimiter) {
            var sb = new GLib.StringBuilder ();
            bool first = true;
            foreach (var elem in elements) {
                if (!first) {
                    sb.append (delimiter);
                }
                sb.append (elem);
                first = false;
            }
            return sb.str;
        }
    }
}
