using Vala.Lang;

namespace Vala.Io {
    /**
     * Path class is a value object that represents a file system path.
     *
     * Path is immutable: methods that transform the path return a new Path
     * instance rather than modifying the existing one.
     *
     * Example:
     * {{{
     *     var path = new Path ("/home/user/docs/file.txt");
     *     assert (path.extension () == ".txt");
     *     assert (path.isAbsolute () == true);
     *     assert (path.parent ().toString () == "/home/user/docs");
     * }}}
     */
    public class Path : GLib.Object {
        private string _path;

        /**
         * Construct Path object.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/file.txt");
         * }}}
         *
         * @param path PATH information represented by the string
         * @return Path object
         */
        public Path (string path) {
            this._path = path;
        }

        /**
         * Returns Path as a string.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/file.txt");
         *     assert (path.toString () == "/tmp/file.txt");
         * }}}
         *
         * @return path as a string.
         */
        public string toString () {
            return _path;
        }

        /**
         * Extract the base name (file name) from the file path.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/file.txt");
         *     assert (path.basename () == "file.txt");
         * }}}
         *
         * @return string of basename.
         */
        public string basename () {
            return GLib.Path.get_basename (_path);
        }

        /**
         * Extract the dirname from the file path.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/file.txt");
         *     assert (path.dirname ("/tmp/file.txt") == "/tmp");
         * }}}
         *
         * @param path file path to be checked.
         * @return string of dirname. If path is empty, return "".
         */
        public string dirname (string path) {
            if (Strings.isNullOrEmpty (path)) {
                return "";
            }
            return GLib.Path.get_dirname (path);
        }

        /**
         * Returns the file extension including the leading dot.
         * Returns an empty string if the file has no extension.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/file.txt");
         *     assert (path.extension () == ".txt");
         *     var noExt = new Path ("/tmp/Makefile");
         *     assert (noExt.extension () == "");
         * }}}
         *
         * @return the file extension (e.g. ".txt"), or "" if none.
         */
        public string extension () {
            var name = basename ();
            if (name == "." || name == "..") {
                return "";
            }
            var dot = name.last_index_of_char ('.');
            if (dot <= 0) {
                return "";
            }
            return name.substring (dot);
        }

        /**
         * Returns the path without the file extension.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/file.txt");
         *     assert (path.withoutExtension () == "/tmp/file");
         *     var noExt = new Path ("/tmp/Makefile");
         *     assert (noExt.withoutExtension () == "/tmp/Makefile");
         * }}}
         *
         * @return the path string without extension.
         */
        public string withoutExtension () {
            var ext = extension ();
            if (ext == "") {
                return _path;
            }
            return _path.substring (0, _path.length - ext.length);
        }

        /**
         * Returns whether this path is absolute.
         *
         * Example:
         * {{{
         *     assert (new Path ("/usr/bin").isAbsolute () == true);
         *     assert (new Path ("relative/path").isAbsolute () == false);
         * }}}
         *
         * @return true if the path starts with "/".
         */
        public bool isAbsolute () {
            return _path.length > 0 && _path[0] == '/';
        }

        /**
         * Returns a new Path representing the parent directory.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/file.txt");
         *     assert (path.parent ().toString () == "/tmp");
         * }}}
         *
         * @return a new Path for the parent directory.
         */
        public Path parent () {
            return new Path (GLib.Path.get_dirname (_path));
        }

        /**
         * Resolves the given path against this path.
         * If other is absolute, returns a new Path for other.
         * Otherwise, joins this path with other.
         *
         * Example:
         * {{{
         *     var base = new Path ("/home/user");
         *     assert (base.resolve ("docs").toString () == "/home/user/docs");
         *     assert (base.resolve ("/etc").toString () == "/etc");
         * }}}
         *
         * @param other the path to resolve.
         * @return a new resolved Path.
         */
        public Path resolve (string other) {
            if (other.length > 0 && other[0] == '/') {
                return new Path (other);
            }
            if (_path.has_suffix ("/")) {
                return new Path (_path + other);
            }
            return new Path (_path + "/" + other);
        }

        /**
         * Joins multiple path components to this path.
         *
         * Example:
         * {{{
         *     var root = new Path ("/home");
         *     assert (root.join ("user", "docs").toString () == "/home/user/docs");
         * }}}
         *
         * @param parts path components to join.
         * @return a new Path with all parts joined.
         */
        public Path join (string part1, ...) {
            var result = _path;
            var args = va_list ();

            /* Append first explicit parameter */
            if (!result.has_suffix ("/")) {
                result += "/";
            }
            result += part1;

            /* Append variadic parameters */
            while (true) {
                string ? next = args.arg<string ?> ();
                if (next == null) {
                    break;
                }
                if (!result.has_suffix ("/")) {
                    result += "/";
                }
                result += next;
            }
            return new Path (result);
        }

        /**
         * Returns whether this path equals another path by comparing their
         * string representations.
         *
         * Example:
         * {{{
         *     var a = new Path ("/tmp/file.txt");
         *     var b = new Path ("/tmp/file.txt");
         *     assert (a.equals (b) == true);
         * }}}
         *
         * @param other the other Path to compare.
         * @return true if both paths have the same string value.
         */
        public bool equals (Path other) {
            return _path == other.toString ();
        }

        /**
         * Returns whether this path starts with the given prefix.
         *
         * Example:
         * {{{
         *     var path = new Path ("/home/user/docs");
         *     assert (path.startsWith ("/home") == true);
         * }}}
         *
         * @param prefix the prefix to check.
         * @return true if the path starts with the prefix.
         */
        public bool startsWith (string prefix) {
            return _path.has_prefix (prefix);
        }

        /**
         * Returns whether this path ends with the given suffix.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/file.txt");
         *     assert (path.endsWith (".txt") == true);
         * }}}
         *
         * @param suffix the suffix to check.
         * @return true if the path ends with the suffix.
         */
        public bool endsWith (string suffix) {
            return _path.has_suffix (suffix);
        }

        /**
         * Splits the path into its individual components.
         *
         * Example:
         * {{{
         *     var path = new Path ("/home/user/docs");
         *     var parts = path.components ();
         *     assert (parts.length () == 3);
         *     assert (parts.nth_data (0) == "home");
         * }}}
         *
         * @return a list of path components (excluding empty segments).
         */
        public GLib.List<string> components () {
            var result = new GLib.List<string> ();
            var parts = _path.split ("/");
            foreach (var part in parts) {
                if (part != "") {
                    result.append (part);
                }
            }
            return result;
        }

        /**
         * Returns a normalized path by resolving "." and ".." segments.
         *
         * Example:
         * {{{
         *     var path = new Path ("/home/user/../admin/./docs");
         *     assert (path.normalize ().toString () == "/home/admin/docs");
         * }}}
         *
         * @return a new Path with the normalized path.
         */
        public Path normalize () {
            if (Strings.isNullOrEmpty (_path)) {
                return new Path ("");
            }

            bool absolute = isAbsolute ();
            var parts = _path.split ("/");
            var stack = new GLib.Queue<string> ();

            foreach (var part in parts) {
                if (part == "" || part == ".") {
                    continue;
                }
                if (part == "..") {
                    if (!stack.is_empty ()) {
                        stack.pop_tail ();
                    }
                } else {
                    stack.push_tail (part);
                }
            }

            var result = new GLib.StringBuilder ();
            if (absolute) {
                result.append ("/");
            }
            bool first = true;
            while (!stack.is_empty ()) {
                if (!first) {
                    result.append ("/");
                }
                result.append (stack.pop_head ());
                first = false;
            }

            if (result.len == 0) {
                return new Path (absolute ? "/" : ".");
            }
            return new Path (result.str);
        }

        /**
         * Returns the absolute path. If the path is already absolute,
         * returns a normalized version. If relative, prepends the current
         * working directory and normalizes.
         *
         * Example:
         * {{{
         *     var abs = new Path ("/tmp/file.txt");
         *     assert (abs.abs ().toString () == "/tmp/file.txt");
         * }}}
         *
         * @return a new Path with the absolute, normalized path.
         */
        public Path abs () {
            if (isAbsolute ()) {
                return normalize ();
            }
            var cwd = GLib.Environment.get_current_dir ();
            return new Path (cwd + "/" + _path).normalize ();
        }
    }
}
