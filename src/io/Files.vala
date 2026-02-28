using Posix;
using Vala.Lang;
/**
 * Vala.Io namespace provides file I/O, path manipulation, and string utility APIs.
 */
namespace Vala.Io {
    /**
     * Files class provides static utility methods for common file and
     * directory operations.
     */
    public class Files : GLib.Object {
        /**
         * Returns whether the file exists in the specified path.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/example.txt");
         *     if (Files.isFile (path)) {
         *         // path is a regular file
         *     }
         * }}}
         *
         * @param path Path to file or directory.
         * @return true if the path is a regular file, false otherwise.
         */
        public static bool isFile (Vala.Io.Path path) {
            return FileUtils.test (path.toString (), FileTest.IS_REGULAR);
        }

        /**
         * Returns whether the directory exists in the specified path.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp");
         *     if (Files.isDir (path)) {
         *         // path is a directory
         *     }
         * }}}
         *
         * @param path Path to file or directory.
         * @return true if the path is a directory, false otherwise.
         */
        public static bool isDir (Vala.Io.Path path) {
            return FileUtils.test (path.toString (), FileTest.IS_DIR);
        }

        /**
         * Returns whether the file or directory exists in the specified path.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/example.txt");
         *     if (Files.exists (path)) {
         *         // file or directory exists
         *     }
         * }}}
         *
         * @param path Path to file or directory.
         * @return true if file or directory exists, false otherwise.
         */
        public static bool exists (Vala.Io.Path path) {
            var f = GLib.File.new_for_path (path.toString ());
            return f.query_exists ();
        }

        /**
         * Returns whether the file can read in the specified path.
         *
         * @param path Path to file or directory.
         * @return true if readable, false otherwise.
         */
        public static bool canRead (Vala.Io.Path path) {
            return (Posix.access (path.toString (), R_OK) == 0) ? true : false;
        }

        /**
         * Returns whether the file can write in the specified path.
         *
         * @param path Path to file or directory.
         * @return true if writable, false otherwise.
         */
        public static bool canWrite (Vala.Io.Path path) {
            return (Posix.access (path.toString (), W_OK) == 0) ? true : false;
        }

        /**
         * Returns whether the file can execute in the specified path.
         *
         * @param path Path to file or directory.
         * @return true if executable, false otherwise.
         */
        public static bool canExec (Vala.Io.Path path) {
            return FileUtils.test (path.toString (), FileTest.IS_EXECUTABLE);
        }

        /**
         * Returns whether the symbolic file exists in the specified path.
         *
         * @param path Path to file or directory.
         * @return true if the path is a symbolic link, false otherwise.
         */
        public static bool isSymbolicFile (Vala.Io.Path path) {
            return FileUtils.test (path.toString (), FileTest.IS_SYMLINK);
        }

        /**
         * Returns whether the hidden file exists in the specified path.
         *
         * @param path Path to file or directory.
         * @return true if the path is a hidden file (starts with '.'), false otherwise.
         */
        public static bool isHiddenFile (Vala.Io.Path path) {
            return path.basename ().get_char (0).to_string () == ".";
        }

        /**
         * Create a directory including the parent directory.
         *
         * @param path Path to directory.
         * @return true if directory is created successfully, false if it already
         *         exists or creation fails.
         */
        public static bool makeDirs (Vala.Io.Path path) {
            if (Files.isDir (path)) {
                return false; /* already exists. */
            }
            try {
                var file = GLib.File.new_for_path (path.toString ());
                file.make_directory_with_parents ();
            } catch (Error e) {
                return false;
            }
            return true;
        }

        /**
         * Create a directory.
         *
         * @param path Path to directory.
         * @return true if directory is created successfully, false if it already
         *         exists or creation fails.
         */
        public bool makeDir (Vala.Io.Path path) {
            if (Files.isDir (path)) {
                return false; /* already exists. */
            }
            try {
                var file = GLib.File.new_for_path (path.toString ());
                file.make_directory ();
            } catch (Error e) {
                return false;
            }
            return true;
        }

        /**
         * Copies a file from source to destination.
         *
         * Example:
         * {{{
         *     var src = new Path ("/tmp/source.txt");
         *     var dst = new Path ("/tmp/dest.txt");
         *     bool ok = Files.copy (src, dst);
         * }}}
         *
         * @param src source file path.
         * @param dst destination file path.
         * @return true if copy succeeded, false otherwise.
         */
        public static bool copy (Vala.Io.Path src, Vala.Io.Path dst) {
            if (!Files.exists (src) || Files.isDir (src)) {
                return false;
            }
            try {
                var srcFile = GLib.File.new_for_path (src.toString ());
                var dstFile = GLib.File.new_for_path (dst.toString ());
                srcFile.copy (dstFile, FileCopyFlags.OVERWRITE);
            } catch (Error e) {
                return false;
            }
            return true;
        }

        /**
         * Moves (renames) a file from source to destination.
         *
         * Example:
         * {{{
         *     var src = new Path ("/tmp/old.txt");
         *     var dst = new Path ("/tmp/new.txt");
         *     bool ok = Files.move (src, dst);
         * }}}
         *
         * @param src source file path.
         * @param dst destination file path.
         * @return true if move succeeded, false otherwise.
         */
        public static bool move (Vala.Io.Path src, Vala.Io.Path dst) {
            if (!Files.exists (src)) {
                return false;
            }
            try {
                var srcFile = GLib.File.new_for_path (src.toString ());
                var dstFile = GLib.File.new_for_path (dst.toString ());
                srcFile.move (dstFile, FileCopyFlags.OVERWRITE);
            } catch (Error e) {
                return false;
            }
            return true;
        }

        /**
         * Deletes a file or empty directory.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/to_delete.txt");
         *     bool ok = Files.remove (path);
         * }}}
         *
         * @param path path to file or empty directory.
         * @return true if deletion succeeded, false otherwise.
         */
        public static bool remove (Vala.Io.Path path) {
            if (!Files.exists (path)) {
                return false;
            }
            try {
                var file = GLib.File.new_for_path (path.toString ());
                file.delete ();
            } catch (Error e) {
                return false;
            }
            return true;
        }

        /**
         * Reads the entire contents of a file as a string.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/file.txt");
         *     string? text = Files.readAllText (path);
         *     if (text != null) {
         *         print ("%s\n", text);
         *     }
         * }}}
         *
         * @param path path to the file.
         * @return the file contents as a string, or null on error.
         */
        public static string ? readAllText (Vala.Io.Path path) {
            if (!Files.isFile (path)) {
                return null;
            }
            string contents;
            try {
                FileUtils.get_contents (path.toString (), out contents);
            } catch (FileError e) {
                return null;
            }
            return contents;
        }

        /**
         * Reads the entire contents of a file as a list of lines.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/file.txt");
         *     var lines = Files.readAllLines (path);
         * }}}
         *
         * @param path path to the file.
         * @return a list of lines, or null on error.
         */
        public static GLib.List<string> ? readAllLines (Vala.Io.Path path) {
            var text = readAllText (path);
            if (text == null) {
                return null;
            }
            var result = new GLib.List<string> ();
            var parts = text.split ("\n");
            foreach (var line in parts) {
                result.append (line);
            }
            return result;
        }

        /**
         * Writes a string to a file, replacing any existing content.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/output.txt");
         *     bool ok = Files.writeText (path, "Hello, World!");
         * }}}
         *
         * @param path path to the file.
         * @param text the string to write.
         * @return true if write succeeded, false otherwise.
         */
        public static bool writeText (Vala.Io.Path path, string text) {
            try {
                FileUtils.set_contents (path.toString (), text);
            } catch (FileError e) {
                return false;
            }
            return true;
        }

        /**
         * Appends a string to the end of a file. Creates the file if it
         * does not exist.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/log.txt");
         *     Files.appendText (path, "new log entry\n");
         * }}}
         *
         * @param path path to the file.
         * @param text the string to append.
         * @return true if append succeeded, false otherwise.
         */
        public static bool appendText (Vala.Io.Path path, string text) {
            try {
                var file = GLib.File.new_for_path (path.toString ());
                GLib.FileOutputStream stream;
                if (file.query_exists ()) {
                    stream = file.append_to (FileCreateFlags.NONE);
                } else {
                    stream = file.create (FileCreateFlags.NONE);
                }
                stream.write (text.data);
                stream.close ();
            } catch (Error e) {
                return false;
            }
            return true;
        }

        /**
         * Returns the size of a file in bytes.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/file.txt");
         *     int64 sz = Files.size (path);
         * }}}
         *
         * @param path path to the file.
         * @return file size in bytes, or -1 on error.
         */
        public static int64 size (Vala.Io.Path path) {
            try {
                var file = GLib.File.new_for_path (path.toString ());
                var info = file.query_info ("standard::size", FileQueryInfoFlags.NONE);
                return info.get_size ();
            } catch (Error e) {
                return -1;
            }
        }

        /**
         * Lists the entries in a directory.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp");
         *     var entries = Files.listDir (path);
         * }}}
         *
         * @param path path to the directory.
         * @return a list of entry names, or null if the path is not a directory.
         */
        public static GLib.List<string> ? listDir (Vala.Io.Path path) {
            if (!Files.isDir (path)) {
                return null;
            }
            var result = new GLib.List<string> ();
            try {
                var dir = GLib.Dir.open (path.toString ());
                string ? name = null;
                while ((name = dir.read_name ()) != null) {
                    result.append (name);
                }
            } catch (FileError e) {
                return null;
            }
            return result;
        }

        /**
         * Creates a temporary file and returns its path.
         *
         * Example:
         * {{{
         *     var tmpPath = Files.tempFile ("myapp", ".tmp");
         *     if (tmpPath != null) {
         *         Files.writeText (tmpPath, "temp data");
         *     }
         * }}}
         *
         * @param prefix the prefix for the temporary file name.
         * @param suffix the suffix (extension) for the temporary file name.
         * @return a Path to the created temporary file, or null on error.
         */
        public static Vala.Io.Path ? tempFile (string prefix, string suffix) {
            try {
                string template = prefix + "XXXXXX" + suffix;
                string path;
                int fd = FileUtils.open_tmp (template, out path);
                if (fd >= 0) {
                    Posix.close (fd);
                    return new Vala.Io.Path (path);
                }
            } catch (FileError e) {
                return null;
            }
            return null;
        }

        /**
         * Creates a temporary directory and returns its path.
         *
         * Example:
         * {{{
         *     var tmpDir = Files.tempDir ("myapp");
         *     if (tmpDir != null) {
         *         // use tmpDir.toString () as temporary workspace
         *     }
         * }}}
         *
         * @param prefix the prefix for the temporary directory name.
         * @return a Path to the created temporary directory, or null on error.
         */
        public static Vala.Io.Path ? tempDir (string prefix) {
            string template = prefix + "XXXXXX";
            string ? path = DirUtils.make_tmp (template);
            if (path == null) {
                return null;
            }
            return new Vala.Io.Path (path);
        }

        /**
         * Creates a file if it does not exist, or updates its modification
         * time if it does.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/touchme.txt");
         *     bool ok = Files.touch (path);
         * }}}
         *
         * @param path path to the file.
         * @return true on success, false on error.
         */
        public static bool touch (Vala.Io.Path path) {
            if (!Files.exists (path)) {
                return Files.writeText (path, "");
            }
            try {
                var file = GLib.File.new_for_path (path.toString ());
                var now = new GLib.DateTime.now_local ();
                var info = new FileInfo ();
                info.set_modification_date_time (now);
                file.set_attributes_from_info (info, FileQueryInfoFlags.NONE);
            } catch (Error e) {
                return false;
            }
            return true;
        }

        /**
         * Reads the entire contents of a file as a byte array.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/data.bin");
         *     uint8[]? data = Files.readBytes (path);
         *     if (data != null) {
         *         print ("Read %d bytes\n", data.length);
         *     }
         * }}}
         *
         * @param path path to the file.
         * @return the file contents as a byte array, or null on error.
         */
        public static uint8[] ? readBytes (Vala.Io.Path path) {
            if (!Files.isFile (path)) {
                return null;
            }
            try {
                uint8[] contents;
                FileUtils.get_data (path.toString (), out contents);
                return contents;
            } catch (FileError e) {
                return null;
            }
        }

        /**
         * Writes a byte array to a file, replacing any existing content.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/data.bin");
         *     uint8[] data = { 0x48, 0x65, 0x6C, 0x6C, 0x6F };
         *     bool ok = Files.writeBytes (path, data);
         * }}}
         *
         * @param path path to the file.
         * @param data the byte array to write.
         * @return true if write succeeded, false otherwise.
         */
        public static bool writeBytes (Vala.Io.Path path, uint8[] data) {
            try {
                FileUtils.set_data (path.toString (), data);
            } catch (FileError e) {
                return false;
            }
            return true;
        }

        /**
         * Changes the file mode (permissions) of the specified path.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/script.sh");
         *     bool ok = Files.chmod (path, 0755);
         * }}}
         *
         * @param path path to file or directory.
         * @param mode the permission mode (e.g. 0644, 0755).
         * @return true if permissions were changed, false otherwise.
         */
        public static bool chmod (Vala.Io.Path path, int mode) {
            if (!Files.exists (path)) {
                return false;
            }
            return Posix.chmod (path.toString (), (Posix.mode_t) mode) == 0;
        }

        /**
         * Changes the owner and group of the specified path.
         *
         * Note: Changing ownership typically requires root privileges.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/file.txt");
         *     bool ok = Files.chown (path, 1000, 1000);
         * }}}
         *
         * @param path path to file or directory.
         * @param uid the user ID of the new owner.
         * @param gid the group ID of the new group.
         * @return true if ownership was changed, false otherwise.
         */
        public static bool chown (Vala.Io.Path path, int uid, int gid) {
            if (!Files.exists (path)) {
                return false;
            }
            return Posix.chown (path.toString (), (Posix.uid_t) uid, (Posix.gid_t) gid) == 0;
        }

        /**
         * Returns the last modification time of a file or directory.
         *
         * Example:
         * {{{
         *     var path = new Path ("/tmp/file.txt");
         *     GLib.DateTime? mtime = Files.lastModified (path);
         *     if (mtime != null) {
         *         print ("Modified: %s\n", mtime.format_iso8601 ());
         *     }
         * }}}
         *
         * @param path path to file or directory.
         * @return the last modification time, or null on error.
         */
        public static GLib.DateTime ? lastModified (Vala.Io.Path path) {
            if (!Files.exists (path)) {
                return null;
            }
            try {
                var file = GLib.File.new_for_path (path.toString ());
                var info = file.query_info ("time::modified", FileQueryInfoFlags.NONE);
                return info.get_modification_date_time ();
            } catch (Error e) {
                return null;
            }
        }

        /**
         * Creates a symbolic link that points to the target path.
         *
         * Example:
         * {{{
         *     var target = new Path ("/tmp/original.txt");
         *     var link = new Path ("/tmp/link.txt");
         *     bool ok = Files.createSymlink (target, link);
         * }}}
         *
         * @param target the path the symlink will point to.
         * @param link the path of the symlink to create.
         * @return true if the symlink was created, false otherwise.
         */
        public static bool createSymlink (Vala.Io.Path target, Vala.Io.Path link) {
            if (Files.exists (link)) {
                return false;
            }
            try {
                var linkFile = GLib.File.new_for_path (link.toString ());
                linkFile.make_symbolic_link (target.toString ());
            } catch (Error e) {
                return false;
            }
            return true;
        }

        /**
         * Reads the target path of a symbolic link.
         *
         * Example:
         * {{{
         *     var link = new Path ("/tmp/link.txt");
         *     var target = Files.readSymlink (link);
         *     if (target != null) {
         *         print ("Points to: %s\n", target.toString ());
         *     }
         * }}}
         *
         * @param path path to the symbolic link.
         * @return a Path for the symlink target, or null on error.
         */
        public static Vala.Io.Path ? readSymlink (Vala.Io.Path path) {
            if (!Files.isSymbolicFile (path)) {
                return null;
            }
            try {
                var file = GLib.File.new_for_path (path.toString ());
                var info = file.query_info (
                    FileAttribute.STANDARD_SYMLINK_TARGET,
                    FileQueryInfoFlags.NOFOLLOW_SYMLINKS
                );
                string ? target = info.get_symlink_target ();
                if (target == null) {
                    return null;
                }
                return new Vala.Io.Path (target);
            } catch (Error e) {
                return null;
            }
        }

        /**
         * Returns whether two paths refer to the same file on disk.
         *
         * This compares device ID and inode number, so it correctly
         * detects files linked via hard links or symbolic links.
         *
         * Example:
         * {{{
         *     var a = new Path ("/tmp/file.txt");
         *     var b = new Path ("/tmp/link.txt");
         *     if (Files.isSameFile (a, b)) {
         *         // both paths point to the same file
         *     }
         * }}}
         *
         * @param a the first path.
         * @param b the second path.
         * @return true if both paths refer to the same file.
         */
        public static bool isSameFile (Vala.Io.Path a, Vala.Io.Path b) {
            if (!Files.exists (a) || !Files.exists (b)) {
                return false;
            }
            Posix.Stat statA;
            Posix.Stat statB;
            if (Posix.stat (a.toString (), out statA) != 0) {
                return false;
            }
            if (Posix.stat (b.toString (), out statB) != 0) {
                return false;
            }
            return statA.st_dev == statB.st_dev && statA.st_ino == statB.st_ino;
        }

        /**
         * Returns a list of file paths in the directory that match the
         * given glob pattern.
         *
         * Example:
         * {{{
         *     var dir = new Path ("/tmp/mydir");
         *     var matches = Files.glob (dir, "*.txt");
         *     if (matches != null) {
         *         foreach (var p in matches) {
         *             print ("%s\n", p.toString ());
         *         }
         *     }
         * }}}
         *
         * @param dir path to directory to search.
         * @param pattern glob pattern to match file names against.
         * @return a list of matching Paths, or null on error.
         */
        public static GLib.List<Vala.Io.Path> ? glob (Vala.Io.Path dir, string pattern) {
            if (!Files.isDir (dir)) {
                return null;
            }
            if (Strings.isNullOrEmpty (pattern)) {
                return null;
            }
            var result = new GLib.List<Vala.Io.Path> ();
            var spec = new GLib.PatternSpec (pattern);
            try {
                var d = GLib.Dir.open (dir.toString ());
                string ? name = null;
                while ((name = d.read_name ()) != null) {
                    if (spec.match_string (name)) {
                        result.append (new Vala.Io.Path (dir.toString () + "/" + name));
                    }
                }
            } catch (FileError e) {
                return null;
            }
            return result;
        }

        /**
         * Recursively deletes a directory and all its contents.
         *
         * If the path points to a regular file, it is deleted like
         * remove(). If the path does not exist, returns false.
         * Symbolic links are removed without following them.
         *
         * Example:
         * {{{
         *     var dir = new Path ("/tmp/mydir");
         *     bool ok = Files.deleteRecursive (dir);
         * }}}
         *
         * @param path path to file or directory to delete recursively.
         * @return true if deletion succeeded, false otherwise.
         */
        public static bool deleteRecursive (Vala.Io.Path path) {
            if (!Files.exists (path)) {
                return false;
            }
            if (Files.isSymbolicFile (path)) {
                return Files.remove (path);
            }
            if (!Files.isDir (path)) {
                return Files.remove (path);
            }
            try {
                var dir = GLib.Dir.open (path.toString ());
                string ? name = null;
                while ((name = dir.read_name ()) != null) {
                    var childPath = new Vala.Io.Path (path.toString () + "/" + name);
                    if (!deleteRecursive (childPath)) {
                        return false;
                    }
                }
                var file = GLib.File.new_for_path (path.toString ());
                file.delete ();
            } catch (Error e) {
                return false;
            }
            return true;
        }
    }
}
