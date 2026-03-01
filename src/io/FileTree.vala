using Vala.Collections;
using Vala.Time;

namespace Vala.Io {
    /**
     * High-level recursive directory operations.
     *
     * FileTree provides traversal, search, copy/sync, and aggregation
     * utilities for directory trees.
     */
    public class FileTree : GLib.Object {
        /**
         * Recursively walks all files under root.
         *
         * @param root root path.
         * @return recursively discovered files.
         */
        public static ArrayList<Path> walk (Path root) {
            return walkWithDepth (root, int.MAX);
        }

        /**
         * Recursively walks files under root up to maxDepth.
         *
         * Root path depth is 0. Direct children are depth 1.
         *
         * @param root root path.
         * @param maxDepth maximum traversal depth.
         * @return recursively discovered files.
         */
        public static ArrayList<Path> walkWithDepth (Path root, int maxDepth) {
            var result = new ArrayList<Path> ();
            if (maxDepth < 0 || !Files.exists (root)) {
                return result;
            }
            walkInternal (root, 0, maxDepth, result);
            sortPaths (result);
            return result;
        }

        /**
         * Finds files by glob pattern.
         *
         * @param root root path.
         * @param glob glob pattern.
         * @return matched files.
         */
        public static ArrayList<Path> find (Path root, string glob) {
            var result = new ArrayList<Path> ();
            if (glob.length == 0) {
                return result;
            }
            var files = walk (root);
            for (int i = 0; i < files.size (); i++) {
                Path ? p = files.get (i);
                if (p == null) {
                    continue;
                }
                if (GLib.PatternSpec.match_simple (glob, p.basename ())) {
                    result.add (p);
                }
            }
            return result;
        }

        /**
         * Finds files by regex pattern.
         *
         * @param root root path.
         * @param pattern regex pattern.
         * @return matched files.
         */
        public static ArrayList<Path> findByRegex (Path root, string pattern) {
            var result = new ArrayList<Path> ();
            GLib.Regex regex;
            try {
                regex = new GLib.Regex (pattern);
            } catch (GLib.RegexError e) {
                return result;
            }

            var files = walk (root);
            for (int i = 0; i < files.size (); i++) {
                Path ? p = files.get (i);
                if (p == null) {
                    continue;
                }
                if (regex.match (p.toString ())) {
                    result.add (p);
                }
            }
            return result;
        }

        /**
         * Finds files by size range.
         *
         * @param root root path.
         * @param minBytes minimum bytes (inclusive).
         * @param maxBytes maximum bytes (inclusive).
         * @return matched files.
         */
        public static ArrayList<Path> findBySize (Path root, int64 minBytes, int64 maxBytes) {
            var result = new ArrayList<Path> ();
            if (minBytes > maxBytes) {
                return result;
            }

            var files = walk (root);
            for (int i = 0; i < files.size (); i++) {
                Path ? p = files.get (i);
                if (p == null) {
                    continue;
                }
                int64 size = Files.size (p);
                if (size >= minBytes && size <= maxBytes) {
                    result.add (p);
                }
            }
            return result;
        }

        /**
         * Finds files modified after the given date-time.
         *
         * @param root root path.
         * @param after lower bound timestamp.
         * @return matched files.
         */
        public static ArrayList<Path> findModifiedAfter (Path root, Vala.Time.DateTime after) {
            var result = new ArrayList<Path> ();
            int64 lower = after.toUnixTimestamp ();
            var files = walk (root);
            for (int i = 0; i < files.size (); i++) {
                Path ? p = files.get (i);
                if (p == null) {
                    continue;
                }
                GLib.DateTime ? mtime = Files.lastModified (p);
                if (mtime == null) {
                    continue;
                }
                if (mtime.to_unix () > lower) {
                    result.add (p);
                }
            }
            return result;
        }

        /**
         * Recursively copies directory tree.
         *
         * @param src source directory.
         * @param dst destination directory.
         * @return true if copied successfully.
         */
        public static bool copyTree (Path src, Path dst) {
            return copyTreeWithFilter (src, dst, (path) => {
                return true;
            });
        }

        /**
         * Recursively copies directory tree with path filter.
         *
         * @param src source directory.
         * @param dst destination directory.
         * @param filter include filter.
         * @return true if copied successfully.
         */
        public static bool copyTreeWithFilter (Path src,
                                               Path dst,
                                               owned PredicateFunc<Path> filter) {
            if (!Files.exists (src) || !Files.isDir (src)) {
                return false;
            }
            if (!ensureDirectory (dst)) {
                return false;
            }

            PredicateFunc<Path> filterFn = (owned) filter;
            return copyTreeInternal (src, dst, filterFn);
        }

        /**
         * One-way synchronization from src to dst.
         *
         * Files are copied when missing in dst, or when size/mtime differs.
         *
         * @param src source directory.
         * @param dst destination directory.
         * @return true if synchronization succeeds.
         */
        public static bool sync (Path src, Path dst) {
            if (!Files.exists (src) || !Files.isDir (src)) {
                return false;
            }
            if (!ensureDirectory (dst)) {
                return false;
            }
            return syncInternal (src, dst);
        }

        /**
         * Recursively deletes a tree.
         *
         * @param root root path.
         * @return true if deletion succeeds.
         */
        public static bool deleteTree (Path root) {
            return Files.deleteRecursive (root);
        }

        /**
         * Returns total size of regular files under root.
         *
         * @param root root path.
         * @return total size in bytes.
         */
        public static int64 totalSize (Path root) {
            int64 total = 0;
            var files = walk (root);
            for (int i = 0; i < files.size (); i++) {
                Path ? p = files.get (i);
                if (p == null) {
                    continue;
                }
                int64 size = Files.size (p);
                if (size > 0) {
                    total += size;
                }
            }
            return total;
        }

        /**
         * Returns number of regular files under root.
         *
         * @param root root path.
         * @return file count.
         */
        public static int countFiles (Path root) {
            return (int) walk (root).size ();
        }

        /**
         * Flattens nested files under src into dst directory.
         *
         * Name collisions are resolved by suffixing "-N" before extension.
         *
         * @param src source directory.
         * @param dst destination directory.
         * @return true if flatten succeeds.
         */
        public static bool flatten (Path src, Path dst) {
            if (!Files.exists (src) || !Files.isDir (src)) {
                return false;
            }
            if (!ensureDirectory (dst)) {
                return false;
            }

            var files = walk (src);
            for (int i = 0; i < files.size (); i++) {
                Path ? p = files.get (i);
                if (p == null) {
                    continue;
                }
                Path dstFile = uniqueDestinationPath (dst, p.basename ());
                if (!Files.copy (p, dstFile)) {
                    return false;
                }
            }
            return true;
        }

        private static void walkInternal (Path current,
                                          int depth,
                                          int maxDepth,
                                          ArrayList<Path> outFiles) {
            if (!Files.exists (current) || depth > maxDepth) {
                return;
            }

            if (Files.isSymbolicFile (current)) {
                return;
            }

            if (Files.isFile (current)) {
                outFiles.add (current);
                return;
            }

            if (!Files.isDir (current)) {
                return;
            }

            GLib.List<string> ? entries = Files.listDir (current);
            if (entries == null) {
                return;
            }

            foreach (string name in entries) {
                Path child = new Path (current.toString () + "/" + name);
                walkInternal (child, depth + 1, maxDepth, outFiles);
            }
        }

        private static bool copyTreeInternal (Path src, Path dst, PredicateFunc<Path> filter) {
            if (!filter (src)) {
                return true;
            }

            if (Files.isSymbolicFile (src)) {
                Path ? target = Files.readSymlink (src);
                if (target == null) {
                    return false;
                }
                if (Files.exists (dst)) {
                    if (!Files.remove (dst)) {
                        return false;
                    }
                }
                return Files.createSymlink (target, dst);
            }

            if (Files.isFile (src)) {
                return Files.copy (src, dst);
            }

            if (!Files.isDir (src)) {
                return false;
            }

            if (!ensureDirectory (dst)) {
                return false;
            }

            GLib.List<string> ? entries = Files.listDir (src);
            if (entries == null) {
                return false;
            }

            foreach (string name in entries) {
                Path srcChild = new Path (src.toString () + "/" + name);
                Path dstChild = new Path (dst.toString () + "/" + name);
                if (!copyTreeInternal (srcChild, dstChild, filter)) {
                    return false;
                }
            }
            return true;
        }

        private static bool syncInternal (Path src, Path dst) {
            if (Files.isSymbolicFile (src)) {
                Path ? srcTarget = Files.readSymlink (src);
                if (srcTarget == null) {
                    return false;
                }

                if (Files.exists (dst)) {
                    if (!Files.isSymbolicFile (dst)) {
                        if (!Files.deleteRecursive (dst)) {
                            return false;
                        }
                    } else {
                        Path ? dstTarget = Files.readSymlink (dst);
                        if (dstTarget != null && dstTarget.equals (srcTarget)) {
                            return true;
                        }
                        if (!Files.remove (dst)) {
                            return false;
                        }
                    }
                }
                return Files.createSymlink (srcTarget, dst);
            }

            if (Files.isFile (src)) {
                if (shouldCopyForSync (src, dst)) {
                    return Files.copy (src, dst);
                }
                return true;
            }

            if (!Files.isDir (src)) {
                return false;
            }

            if (!ensureDirectory (dst)) {
                return false;
            }

            GLib.List<string> ? entries = Files.listDir (src);
            if (entries == null) {
                return false;
            }

            foreach (string name in entries) {
                Path srcChild = new Path (src.toString () + "/" + name);
                Path dstChild = new Path (dst.toString () + "/" + name);
                if (!syncInternal (srcChild, dstChild)) {
                    return false;
                }
            }

            return true;
        }

        private static bool shouldCopyForSync (Path src, Path dst) {
            if (!Files.exists (dst) || !Files.isFile (dst)) {
                return true;
            }

            if (Files.size (src) != Files.size (dst)) {
                return true;
            }

            GLib.DateTime ? srcTime = Files.lastModified (src);
            GLib.DateTime ? dstTime = Files.lastModified (dst);
            if (srcTime == null || dstTime == null) {
                return true;
            }

            return srcTime.to_unix () > dstTime.to_unix ();
        }

        private static bool ensureDirectory (Path path) {
            if (Files.isDir (path)) {
                return true;
            }
            return Files.makeDirs (path);
        }

        private static Path uniqueDestinationPath (Path dst, string fileName) {
            Path candidate = new Path (dst.toString () + "/" + fileName);
            if (!Files.exists (candidate)) {
                return candidate;
            }

            string baseName = fileName;
            string ext = "";
            int dot = fileName.last_index_of_char ('.');
            if (dot > 0) {
                baseName = fileName.substring (0, dot);
                ext = fileName.substring (dot);
            }

            int n = 1;
            while (true) {
                string name = "%s-%d%s".printf (baseName, n, ext);
                Path next = new Path (dst.toString () + "/" + name);
                if (!Files.exists (next)) {
                    return next;
                }
                n++;
            }
        }

        private static void sortPaths (ArrayList<Path> paths) {
            paths.sort ((a, b) => {
                return strcmp (a.toString (), b.toString ());
            });
        }
    }
}
