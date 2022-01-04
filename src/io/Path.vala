/*
 * libvalacore/src/io/Path.vala
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
namespace Core {
    /**
     * Path class is an object that can be used to identify the file path in
     * the file system.
     */
    public class Path : GLib.Object {
        private string path;

        /**
         * Construct Path object.
         * @param path PATH information represented by the string
         * @return Path object
         */
        public Path (string path) {
            this.path = path;
        }

        /**
         * Extract the base name (file name) from the file path.
         * @param path file path to be checked.
         * @return string of basename. If path is null or not file path, return "";
         */
        public static string basename (string path) {
            if (Strings.isNullOrEmpty (path)) {
                return "";
            }
            return GLib.Path.get_basename (path);
        }

        /**
         * Extract the dirname from the file path.
         * @param path file path to be checked.
         * @return string of dirname. If path is null or not file path, return "";
         */
        public static string dirname (string path) {
            if (Strings.isNullOrEmpty (path)) {
                return "";
            }
            return GLib.Path.get_dirname (path);
        }

        /**
         * Returns absolute path that is normalized.
         * @return If the Path information is correct, abs() returns an absolute path.
         * If the Path information is incorrect (e.g. null), abs() returns "".
         */
        /*
           public string ? abs () {
           if (Objects.isNull (this.path)) {
               return null;
           }
           var cwd = Os.cwd ();
           return (cwd + "/" + this.path).dup ();
           }
         */

        /** T.B.D */
        /*
           private string ? normalized () {
            if (Objects.isNull (path)) {
                return null;
            }
            return path;
           }
         */
    }
}
