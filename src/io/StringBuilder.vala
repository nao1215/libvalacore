namespace Vala.Io {
    /**
     * StringBuilder is a mutable string buffer for efficient string
     * construction. It wraps GLib.StringBuilder and provides a rich,
     * Java/C#-inspired API.
     *
     * Unlike regular string concatenation which creates a new string each
     * time, StringBuilder modifies an internal buffer, making it much more
     * efficient for building strings incrementally.
     *
     * Example:
     * {{{
     *     var sb = new StringBuilder ();
     *     sb.append ("Hello");
     *     sb.append (", ");
     *     sb.append ("World!");
     *     assert (sb.toString () == "Hello, World!");
     * }}}
     */
    public class StringBuilder : GLib.Object {
        private GLib.StringBuilder _sb;

        /**
         * Constructs an empty StringBuilder.
         *
         * Example:
         * {{{
         *     var sb = new StringBuilder ();
         *     assert (sb.length () == 0);
         * }}}
         */
        public StringBuilder () {
            _sb = new GLib.StringBuilder ();
        }

        /**
         * Constructs a StringBuilder with initial content.
         *
         * Example:
         * {{{
         *     var sb = new StringBuilder.withString ("hello");
         *     assert (sb.toString () == "hello");
         * }}}
         *
         * @param s the initial string content.
         */
        public StringBuilder.withString (string s) {
            _sb = new GLib.StringBuilder (s);
        }

        /**
         * Constructs a StringBuilder with a pre-allocated buffer size.
         *
         * Example:
         * {{{
         *     var sb = new StringBuilder.sized (1024);
         *     assert (sb.length () == 0);
         * }}}
         *
         * @param size the initial buffer capacity.
         */
        public StringBuilder.sized (size_t size) {
            _sb = new GLib.StringBuilder.sized (size);
        }

        /**
         * Appends a string to the end of this builder.
         *
         * Example:
         * {{{
         *     var sb = new StringBuilder ();
         *     sb.append ("Hello");
         *     sb.append (" World");
         *     assert (sb.toString () == "Hello World");
         * }}}
         *
         * @param s the string to append.
         * @return this StringBuilder for chaining.
         */
        public StringBuilder append (string s) {
            _sb.append (s);
            return this;
        }

        /**
         * Appends a string followed by a newline character.
         *
         * Example:
         * {{{
         *     var sb = new StringBuilder ();
         *     sb.appendLine ("line1");
         *     sb.appendLine ("line2");
         *     assert (sb.toString () == "line1\nline2\n");
         * }}}
         *
         * @param s the string to append before the newline.
         * @return this StringBuilder for chaining.
         */
        public StringBuilder appendLine (string s) {
            _sb.append (s);
            _sb.append_c ('\n');
            return this;
        }

        /**
         * Appends a single character to the end of this builder.
         *
         * Example:
         * {{{
         *     var sb = new StringBuilder ();
         *     sb.appendChar ('A');
         *     sb.appendChar ('B');
         *     assert (sb.toString () == "AB");
         * }}}
         *
         * @param c the character to append.
         * @return this StringBuilder for chaining.
         */
        public StringBuilder appendChar (char c) {
            _sb.append_c (c);
            return this;
        }

        /**
         * Inserts a string at the specified byte offset.
         *
         * Example:
         * {{{
         *     var sb = new StringBuilder.withString ("HelloWorld");
         *     sb.insert (5, ", ");
         *     assert (sb.toString () == "Hello, World");
         * }}}
         *
         * @param offset the byte position to insert at.
         * @param s the string to insert.
         * @return this StringBuilder for chaining.
         */
        public StringBuilder insert (int offset, string s) {
            if (offset < 0 || offset > (int) _sb.len) {
                return this;
            }
            _sb.insert (offset, s);
            return this;
        }

        /**
         * Deletes the characters in the range [start, end).
         *
         * Example:
         * {{{
         *     var sb = new StringBuilder.withString ("Hello, World");
         *     sb.deleteRange (5, 7);
         *     assert (sb.toString () == "HelloWorld");
         * }}}
         *
         * @param start the start index (inclusive).
         * @param end the end index (exclusive).
         * @return this StringBuilder for chaining.
         */
        public StringBuilder deleteRange (int start, int end) {
            if (start < 0 || end < start || start > (int) _sb.len) {
                return this;
            }
            if (end > (int) _sb.len) {
                end = (int) _sb.len;
            }
            _sb.erase (start, end - start);
            return this;
        }

        /**
         * Replaces the characters in the range [start, end) with the given
         * string.
         *
         * Example:
         * {{{
         *     var sb = new StringBuilder.withString ("Hello World");
         *     sb.replaceRange (6, 11, "Vala");
         *     assert (sb.toString () == "Hello Vala");
         * }}}
         *
         * @param start the start index (inclusive).
         * @param end the end index (exclusive).
         * @param s the replacement string.
         * @return this StringBuilder for chaining.
         */
        public StringBuilder replaceRange (int start, int end, string s) {
            if (start < 0 || end < start || start > (int) _sb.len) {
                return this;
            }
            if (end > (int) _sb.len) {
                end = (int) _sb.len;
            }
            _sb.erase (start, end - start);
            _sb.insert (start, s);
            return this;
        }

        /**
         * Reverses the contents of this builder.
         *
         * Example:
         * {{{
         *     var sb = new StringBuilder.withString ("abc");
         *     sb.reverse ();
         *     assert (sb.toString () == "cba");
         * }}}
         *
         * @return this StringBuilder for chaining.
         */
        public StringBuilder reverse () {
            var str = _sb.str;
            var reversed = str.reverse ();
            _sb.truncate (0);
            _sb.append (reversed);
            return this;
        }

        /**
         * Returns the number of bytes in this builder.
         *
         * Example:
         * {{{
         *     var sb = new StringBuilder.withString ("Hello");
         *     assert (sb.length () == 5);
         * }}}
         *
         * @return the current byte length.
         */
        public int length () {
            return (int) _sb.len;
        }

        /**
         * Returns the character at the specified byte index.
         *
         * Example:
         * {{{
         *     var sb = new StringBuilder.withString ("Hello");
         *     assert (sb.charAt (0) == 'H');
         *     assert (sb.charAt (4) == 'o');
         * }}}
         *
         * @param index the byte index.
         * @return the character at the index, or '\0' if out of range.
         */
        public char charAt (int index) {
            if (index < 0 || index >= (int) _sb.len) {
                return '\0';
            }
            return _sb.str[index];
        }

        /**
         * Clears the contents of this builder.
         *
         * Example:
         * {{{
         *     var sb = new StringBuilder.withString ("data");
         *     sb.clear ();
         *     assert (sb.length () == 0);
         *     assert (sb.toString () == "");
         * }}}
         *
         * @return this StringBuilder for chaining.
         */
        public StringBuilder clear () {
            _sb.truncate (0);
            return this;
        }

        /**
         * Returns the string representation of this builder.
         *
         * Example:
         * {{{
         *     var sb = new StringBuilder.withString ("hello");
         *     assert (sb.toString () == "hello");
         * }}}
         *
         * @return the built string.
         */
        public string toString () {
            return _sb.str;
        }

        /**
         * Returns the allocated buffer capacity in bytes.
         *
         * Example:
         * {{{
         *     var sb = new StringBuilder.sized (256);
         *     assert (sb.capacity () >= 256);
         * }}}
         *
         * @return the buffer capacity.
         */
        public int capacity () {
            return (int) _sb.allocated_len;
        }
    }
}
