namespace Vala.Io {
    /**
     * BufferedReader provides buffered character-input-stream reading.
     * It wraps a GLib.DataInputStream and offers convenient line-by-line
     * or full-text reading similar to Java's BufferedReader and Go's
     * bufio.Scanner.
     *
     * Example:
     * {{{
     *     var reader = BufferedReader.fromFile (new Path ("/tmp/file.txt"));
     *     string? line;
     *     while ((line = reader.readLine ()) != null) {
     *         print ("%s\n", line);
     *     }
     *     reader.close ();
     * }}}
     */
    public class BufferedReader : GLib.Object {
        private GLib.DataInputStream _stream;
        private bool _closed;
        private string ? _peekedLine;
        private bool _hasPeeked;

        private BufferedReader (GLib.DataInputStream stream) {
            _stream = stream;
            _closed = false;
            _peekedLine = null;
            _hasPeeked = false;
        }

        /**
         * Creates a BufferedReader that reads from a file.
         *
         * Example:
         * {{{
         *     var reader = BufferedReader.fromFile (new Path ("/tmp/data.txt"));
         * }}}
         *
         * @param path the file to read.
         * @return a new BufferedReader, or null if the file cannot be opened.
         */
        public static BufferedReader ? fromFile (Vala.Io.Path path) {
            try {
                var file = GLib.File.new_for_path (path.toString ());
                var fis = file.read ();
                var dis = new GLib.DataInputStream (fis);
                return new BufferedReader (dis);
            } catch (Error e) {
                return null;
            }
        }

        /**
         * Creates a BufferedReader that reads from a string.
         *
         * Example:
         * {{{
         *     var reader = BufferedReader.fromString ("line1\nline2\n");
         * }}}
         *
         * @param s the string to read from.
         * @return a new BufferedReader.
         */
        public static BufferedReader fromString (string s) {
            var mis = new GLib.MemoryInputStream.from_data (s.data);
            var dis = new GLib.DataInputStream (mis);
            return new BufferedReader (dis);
        }

        /**
         * Reads a single line from the stream. Returns null at end of
         * stream or if the reader has been closed.
         *
         * Example:
         * {{{
         *     string? line = reader.readLine ();
         * }}}
         *
         * @return the next line without line terminator, or null at EOF.
         */
        public string ? readLine () {
            if (_closed) {
                return null;
            }
            if (_hasPeeked) {
                _hasPeeked = false;
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
         * Reads a single byte from the stream as a character.
         * Returns the null character (0) at end of stream.
         *
         * @return the next byte as a char, or '\0' at EOF.
         */
        public char readChar () {
            if (_closed) {
                return '\0';
            }
            try {
                uint8 b = _stream.read_byte ();
                return (char) b;
            } catch (IOError e) {
                return '\0';
            }
        }

        /**
         * Reads the entire remaining stream as a single string.
         *
         * Example:
         * {{{
         *     string? text = reader.readAll ();
         * }}}
         *
         * @return the remaining content, or null on error.
         */
        public string ? readAll () {
            if (_closed) {
                return null;
            }
            var sb = new GLib.StringBuilder ();
            bool first = true;
            string ? line;
            while ((line = readLine ()) != null) {
                if (!first) {
                    sb.append ("\n");
                }
                sb.append (line);
                first = false;
            }
            return sb.str;
        }

        /**
         * Returns whether there is at least one more line to read.
         * This performs a look-ahead read; the peeked line is returned
         * by the next call to readLine().
         *
         * @return true if there is more data, false at EOF.
         */
        public bool hasNext () {
            if (_closed) {
                return false;
            }
            if (_hasPeeked) {
                return _peekedLine != null;
            }
            try {
                _peekedLine = _stream.read_line_utf8 ();
                _hasPeeked = true;
                return _peekedLine != null;
            } catch (IOError e) {
                return false;
            }
        }

        /**
         * Closes the underlying stream. After closing, all read
         * operations return null or '\0'.
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
    }
}
