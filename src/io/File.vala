/*
 * libvalacore/src/io/File.vala
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
namespace Core {
    /**
     * The File class is an abstract representation of file and directory pathnames.
     */
    public class File : GLib.Object {
        /**TODO: In the future, replace strings with path objects. */
        private string path;

        /**
         * Construct File object.
         * @param path PATH information represented by the string
         * @return File object
         */
        public File (string path) {
            this.path = path;
        }

        /**
         * Returns whether the file exists in the specified path.
         * @return true: File object(path) is file, false: File object(path)  is not file
         */
        public bool isFile () {
            if (Strings.isNullOrEmpty (this.path)) {
                return false;
            }
            return FileUtils.test (this.path, FileTest.IS_REGULAR);
        }

        /**
         * Returns whether the directory exists in the specified path.
         * @return true: File object(path) is directory, false: File object(path) is not directory
         */
        public bool isDir () {
            if (Strings.isNullOrEmpty (this.path)) {
                return false;
            }
            return FileUtils.test (this.path, FileTest.IS_DIR);
        }

        /**
         * Returns whether the file can read in the specified path.
         * @return true: can read, false: can not read.
         */
        public bool canRead () {
            if (Strings.isNullOrEmpty (this.path)) {
                return false;
            }
            return (Posix.access (this.path, R_OK) == 0) ? true : false;
        }

        /**
         * Returns whether the file can write in the specified path.
         * @return true: can write, false: can not write.
         */
        public bool canWrite () {
            if (Strings.isNullOrEmpty (this.path)) {
                return false;
            }
            return (Posix.access (this.path, W_OK) == 0) ? true : false;
        }

        /**
         * Returns whether the file can execute in the specified path.
         * @return true: can execute, false: can not execute.
         */
        public bool canExec () {
            if (Strings.isNullOrEmpty (this.path)) {
                return false;
            }
            return FileUtils.test (this.path, FileTest.IS_EXECUTABLE);
        }

        /**
         * Returns whether the symbolic file exists in the specified path.
         * @return true: path is symbolic file, false: path is not symbolic file
         */
        public bool isSymbolicFile () {
            if (Strings.isNullOrEmpty (this.path)) {
                return false;
            }
            return FileUtils.test (this.path, FileTest.IS_SYMLINK);
        }

        /**
         * Returns whether the hidden file exists in the specified path.
         * @return true: path is hidden file, false: path is not hidden file
         */
        public bool isHiddenFile () {
            if (Strings.isNullOrEmpty (this.path)) {
                return false;
            }
            return Core.Path.basename (this.path).get_char (0).to_string () == ".";
        }
    }
}