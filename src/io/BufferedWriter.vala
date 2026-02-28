/*
 * libvalacore/src/io/BufferedWriter.vala
 *
 * Copyright 2022 Naohiro CHIKAMATSU
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
namespace Vala.Io {
    /**
     * BufferedWriter provides buffered character-output-stream writing.
     * It wraps a GLib.DataOutputStream and offers convenient methods
     * for writing strings and lines, similar to Java's BufferedWriter.
     *
     * Example:
     * {{{
     *     var writer = BufferedWriter.fromFile (new Path ("/tmp/out.txt"));
     *     writer.writeLine ("Hello");
     *     writer.writeLine ("World");
     *     writer.close ();
     * }}}
     */
    public class BufferedWriter : GLib.Object {
        private GLib.DataOutputStream _stream;
        private bool _closed;

        private BufferedWriter (GLib.DataOutputStream stream) {
            _stream = stream;
            _closed = false;
        }

        /**
         * Creates a BufferedWriter that writes to a file, replacing any
         * existing content.
         *
         * Example:
         * {{{
         *     var writer = BufferedWriter.fromFile (new Path ("/tmp/out.txt"));
         * }}}
         *
         * @param path the file to write to.
         * @return a new BufferedWriter, or null if the file cannot be opened.
         */
        public static BufferedWriter ? fromFile (Vala.Io.Path path) {
            try {
                var file = GLib.File.new_for_path (path.toString ());
                var fos = file.replace (null, false, FileCreateFlags.NONE);
                var dos = new GLib.DataOutputStream (fos);
                return new BufferedWriter (dos);
            } catch (Error e) {
                return null;
            }
        }

        /**
         * Creates a BufferedWriter that appends to an existing file, or
         * creates the file if it does not exist.
         *
         * Example:
         * {{{
         *     var writer = BufferedWriter.fromFileAppend (new Path ("/tmp/log.txt"));
         * }}}
         *
         * @param path the file to append to.
         * @return a new BufferedWriter, or null if the file cannot be opened.
         */
        public static BufferedWriter ? fromFileAppend (Vala.Io.Path path) {
            try {
                var file = GLib.File.new_for_path (path.toString ());
                GLib.FileOutputStream fos;
                if (file.query_exists ()) {
                    fos = file.append_to (FileCreateFlags.NONE);
                } else {
                    fos = file.create (FileCreateFlags.NONE);
                }
                var dos = new GLib.DataOutputStream (fos);
                return new BufferedWriter (dos);
            } catch (Error e) {
                return null;
            }
        }

        /**
         * Writes a string to the stream.
         *
         * @param s the string to write.
         * @return true on success, false on error.
         */
        public bool write (string s) {
            if (_closed) {
                return false;
            }
            try {
                _stream.put_string (s);
                return true;
            } catch (IOError e) {
                return false;
            }
        }

        /**
         * Writes a string followed by a newline to the stream.
         *
         * @param s the string to write.
         * @return true on success, false on error.
         */
        public bool writeLine (string s) {
            return write (s + "\n");
        }

        /**
         * Writes a newline to the stream.
         *
         * @return true on success, false on error.
         */
        public bool newLine () {
            return write ("\n");
        }

        /**
         * Flushes the stream, writing any buffered data.
         *
         * @return true on success, false on error.
         */
        public bool flush () {
            if (_closed) {
                return false;
            }
            try {
                _stream.flush ();
                return true;
            } catch (Error e) {
                return false;
            }
        }

        /**
         * Closes the underlying stream. After closing, all write
         * operations return false.
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
