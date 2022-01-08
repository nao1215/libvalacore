/*
 * libvalacore/src/io/Files.vala
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
using Posix;
using Vala.Lang;
namespace Vala.Io {
    /**
     * Files class is an abstract representation of file and directory pathnames.
     */
    public class Files : GLib.Object {
        /**
         * Returns whether the file exists in the specified path.
         * @param path Path to file or directory.
         * @return true: File object(path) is file, false: File object(path)  is not file
         */
        public static bool isFile (Vala.Io.Path path) {
            return FileUtils.test (path.toString (), FileTest.IS_REGULAR);
        }

        /**
         * Returns whether the directory exists in the specified path.
         * @param path Path to file or directory.
         * @return true: File object(path) is directory, false: File object(path) is not directory
         */
        public static bool isDir (Vala.Io.Path path) {
            return FileUtils.test (path.toString (), FileTest.IS_DIR);
        }

        /**
         * Returns whether the file or directory exists in the specified path.
         * @param path Path to file or directory.
         * @return true: File or Directory exists, false: File or Directory doesn't exist
         */
        public static bool exists (Vala.Io.Path path) {
            var f = GLib.File.new_for_path (path.toString ());
            return f.query_exists ();
        }

        /**
         * Returns whether the file can read in the specified path.
         * @param path Path to file or directory.
         * @return true: can read, false: can not read.
         */
        public static bool canRead (Vala.Io.Path path) {
            return (Posix.access (path.toString (), R_OK) == 0) ? true : false;
        }

        /**
         * Returns whether the file can write in the specified path.
         * @param path Path to file or directory.
         * @return true: can write, false: can not write.
         */
        public static bool canWrite (Vala.Io.Path path) {
            return (Posix.access (path.toString (), W_OK) == 0) ? true : false;
        }

        /**
         * Returns whether the file can execute in the specified path.
         * @param path Path to file or directory.
         * @return true: can execute, false: can not execute.
         */
        public static bool canExec (Vala.Io.Path path) {
            return FileUtils.test (path.toString (), FileTest.IS_EXECUTABLE);
        }

        /**
         * Returns whether the symbolic file exists in the specified path.
         * @param path Path to file or directory.
         * @return true: path is symbolic file, false: path is not symbolic file
         */
        public static bool isSymbolicFile (Vala.Io.Path path) {
            return FileUtils.test (path.toString (), FileTest.IS_SYMLINK);
        }

        /**
         * Returns whether the hidden file exists in the specified path.
         * @param path Path to file or directory.
         * @return true: path is hidden file, false: path is not hidden file
         */
        public static bool isHiddenFile (Vala.Io.Path path) {
            return path.basename ().get_char (0).to_string () == ".";
        }

        /**
         * Create a directory including the parent directory.
         * @param path Path to file or directory.
         * @return true: directory is created successfully.
         *         false: path is null, or directory creation fails, or
         *                file to be created already exists.
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
         * @param path Path to file or directory.
         * @return true: directory is created successfully.
         *         false: path is null, or directory creation fails, or
         *                file to be created already exists.
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
    }
}
