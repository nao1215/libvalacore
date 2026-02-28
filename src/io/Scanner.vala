using Vala.Lang;

namespace Vala.Io {
    /**
     * Scanner splits input into tokens and provides typed parsing.
     *
     * Inspired by Java's Scanner and Go's bufio.Scanner, this class reads
     * from a file, string, or standard input and returns tokens separated
     * by a configurable delimiter (default: whitespace).
     *
     * Example:
     * {{{
     *     var scanner = Scanner.fromString ("hello world 42");
     *     assert (scanner.next () == "hello");
     *     assert (scanner.next () == "world");
     *     assert (scanner.nextInt () == 42);
     *     scanner.close ();
     * }}}
     */
    public class Scanner : GLib.Object {
        private GLib.DataInputStream _stream;
        private bool _closed;
        private string _delimiter;
        private string[] _tokens;
        private int _tokenIndex;
        private string ? _peekedLine;
        private bool _hasPeekedLine;

        private Scanner (GLib.DataInputStream stream) {
            _stream = stream;
            _closed = false;
            _delimiter = "\\s+";
            _tokens = new string[0];
            _tokenIndex = 0;
            _peekedLine = null;
            _hasPeekedLine = false;
        }

        /**
         * Creates a Scanner that reads from a file.
         *
         * Example:
         * {{{
         *     var scanner = Scanner.fromFile (new Path ("/tmp/data.txt"));
         * }}}
         *
         * @param path the file to read.
         * @return a new Scanner, or null if the file cannot be opened.
         */
        public static Scanner ? fromFile (Vala.Io.Path path) {
            try {
                var file = GLib.File.new_for_path (path.toString ());
                var fis = file.read ();
                var dis = new GLib.DataInputStream (fis);
                return new Scanner (dis);
            } catch (Error e) {
                return null;
            }
        }

        /**
         * Creates a Scanner that reads from a string.
         *
         * Example:
         * {{{
         *     var scanner = Scanner.fromString ("10 20 30");
         *     assert (scanner.nextInt () == 10);
         * }}}
         *
         * @param s the string to read from.
         * @return a new Scanner.
         */
        public static Scanner fromString (string s) {
            var mis = new GLib.MemoryInputStream.from_data (s.data);
            var dis = new GLib.DataInputStream (mis);
            return new Scanner (dis);
        }

        /**
         * Creates a Scanner that reads from standard input.
         *
         * Example:
         * {{{
         *     var scanner = Scanner.fromStdin ();
         *     string? line = scanner.nextLine ();
         * }}}
         *
         * @return a new Scanner reading from stdin.
         */
        public static Scanner ? fromStdin () {
            try {
                var file = GLib.File.new_for_path ("/dev/stdin");
                var fis = file.read ();
                var dis = new GLib.DataInputStream (fis);
                return new Scanner (dis);
            } catch (Error e) {
                return null;
            }
        }

        /**
         * Reads the next line from the input.
         *
         * When a line is read, any remaining tokens from the previous
         * line are discarded.
         *
         * Example:
         * {{{
         *     var scanner = Scanner.fromString ("first line\nsecond line");
         *     assert (scanner.nextLine () == "first line");
         * }}}
         *
         * @return the next line without terminator, or null at EOF.
         */
        public string ? nextLine () {
            if (_closed) {
                return null;
            }
            /* Discard buffered tokens */
            _tokens = new string[0];
            _tokenIndex = 0;

            if (_hasPeekedLine) {
                _hasPeekedLine = false;
                var result = _peekedLine;
                _peekedLine = null;
                return result;
            }
            try {
                return _stream.read_line_utf8 ();
            } catch (IOError e) {
                return null;
            }
        }

        /**
         * Reads the next token and parses it as an integer.
         *
         * Returns 0 if the token cannot be parsed or there are no
         * more tokens.
         *
         * Example:
         * {{{
         *     var scanner = Scanner.fromString ("42 hello");
         *     assert (scanner.nextInt () == 42);
         * }}}
         *
         * @return the parsed integer value, or 0 on failure.
         */
        public int nextInt () {
            var token = next ();
            if (token == null) {
                return 0;
            }
            return int.parse (token);
        }

        /**
         * Reads the next token and parses it as a double.
         *
         * Returns 0.0 if the token cannot be parsed or there are no
         * more tokens.
         *
         * Example:
         * {{{
         *     var scanner = Scanner.fromString ("3.14 2.71");
         *     assert (scanner.nextDouble () == 3.14);
         * }}}
         *
         * @return the parsed double value, or 0.0 on failure.
         */
        public double nextDouble () {
            var token = next ();
            if (token == null) {
                return 0.0;
            }
            return double.parse (token);
        }

        /**
         * Returns the next token from the input.
         *
         * Tokens are separated by the current delimiter (default:
         * whitespace). When all tokens in the current line are consumed,
         * the next line is read automatically.
         *
         * Example:
         * {{{
         *     var scanner = Scanner.fromString ("hello world");
         *     assert (scanner.next () == "hello");
         *     assert (scanner.next () == "world");
         * }}}
         *
         * @return the next token, or null if no more input.
         */
        public string ? next () {
            if (_closed) {
                return null;
            }

            while (_tokenIndex >= _tokens.length) {
                var line = readRawLine ();
                if (line == null) {
                    return null;
                }
                tokenizeLine (line);
            }
            return _tokens[_tokenIndex++];
        }

        /**
         * Returns whether there is at least one more line to read.
         *
         * This performs a look-ahead read; the peeked line is consumed
         * by the next call to nextLine() or next().
         *
         * Example:
         * {{{
         *     var scanner = Scanner.fromString ("line1\nline2");
         *     assert (scanner.hasNextLine () == true);
         * }}}
         *
         * @return true if there is more data.
         */
        public bool hasNextLine () {
            if (_closed) {
                return false;
            }
            if (_hasPeekedLine) {
                return _peekedLine != null;
            }
            try {
                _peekedLine = _stream.read_line_utf8 ();
                _hasPeekedLine = true;
                return _peekedLine != null;
            } catch (IOError e) {
                return false;
            }
        }

        /**
         * Returns whether the next token can be parsed as an integer.
         *
         * This does not consume the token. The peeked token is returned
         * by the next call to next() or nextInt().
         *
         * Example:
         * {{{
         *     var scanner = Scanner.fromString ("42 hello");
         *     assert (scanner.hasNextInt () == true);
         * }}}
         *
         * @return true if the next token is a valid integer.
         */
        public bool hasNextInt () {
            if (_closed) {
                return false;
            }

            /* Fill token buffer if needed */
            while (_tokenIndex >= _tokens.length) {
                var line = readRawLine ();
                if (line == null) {
                    return false;
                }
                tokenizeLine (line);
            }

            var token = _tokens[_tokenIndex];
            if (Strings.isNullOrEmpty (token)) {
                return false;
            }

            /* Check if all characters are digits, optionally with leading minus */
            int start = 0;
            if (token[0] == '-' && token.length > 1) {
                start = 1;
            }
            for (int i = start; i < token.length; i++) {
                if (!token[i].isdigit ()) {
                    return false;
                }
            }
            return true;
        }

        /**
         * Sets the delimiter pattern used to split tokens.
         *
         * The delimiter is a regular expression pattern. The default
         * delimiter is "\\s+" (one or more whitespace characters).
         *
         * Example:
         * {{{
         *     var scanner = Scanner.fromString ("a,b,c");
         *     scanner.setDelimiter (",");
         *     assert (scanner.next () == "a");
         * }}}
         *
         * @param pattern the regex pattern for the delimiter.
         */
        public void setDelimiter (string pattern) {
            _delimiter = pattern;
            /* Reset token buffer so next read uses the new delimiter */
            _tokens = new string[0];
            _tokenIndex = 0;
        }

        /**
         * Closes the underlying stream. After closing, all read
         * operations return null, 0, or false.
         *
         * Example:
         * {{{
         *     scanner.close ();
         * }}}
         */
        public void close () {
            if (_closed) {
                return;
            }
            try {
                _stream.close ();
            } catch (IOError e) {
                /* ignore */
            }
            _closed = true;
        }

        /**
         * Reads a raw line from the stream, consuming peeked line if present.
         */
        private string ? readRawLine () {
            if (_hasPeekedLine) {
                _hasPeekedLine = false;
                var result = _peekedLine;
                _peekedLine = null;
                return result;
            }
            try {
                return _stream.read_line_utf8 ();
            } catch (IOError e) {
                return null;
            }
        }

        /**
         * Tokenizes a line using the current delimiter and fills the token buffer.
         */
        private void tokenizeLine (string line) {
            try {
                var regex = new GLib.Regex (_delimiter);
                var parts = regex.split (line);
                var result = new GLib.Array<string> ();
                foreach (var part in parts) {
                    if (part != "") {
                        result.append_val (part);
                    }
                }
                _tokens = new string[result.length];
                for (uint i = 0; i < result.length; i++) {
                    _tokens[i] = result.index (i);
                }
                _tokenIndex = 0;
            } catch (RegexError e) {
                _tokens = new string[0];
                _tokenIndex = 0;
            }
        }
    }
}
