/*
 * libvalacore/src/io/Strings.vala
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
using Vala.Lang;
namespace Vala.Io {
    /**
     * Strings class is a collection of static APIs for manipulating string.
     */
    public class Strings : GLib.Object {
        /**
         * Check whether sring is null or empty.
         * @param str string for checking.
         * @return true: string is null or empty, false: otherwise
         */
        public static bool isNullOrEmpty (string ? str) {
            return (Objects.isNull (str)) || (str == "");
        }

        /**
         * Remove whitespace and tabs at the beginning and end of the string.
         * @param str string to be trimmed
         * @return string after trimming. If str is null, trim() returns empty string.
         */
        public static string trimSpace (string str) {
            if (Objects.isNull (str)) {
                return "";
            }

            int start = 0;
            int end = 0;
            string now;
            for (int i = 0; i < str.length; i++) {
                now = str.get_char (i).to_string ();
                if (now != " " && now != "\t") {
                    start = i;
                    break;
                }
            }

            for (int i = str.length - 1; i >= 0; i--) {
                now = str.get_char (i).to_string ();
                if (now != " " && now != "\t") {
                    end = i;
                    break;
                }
            }

            string tmp = "";
            for (int i = start; i <= end; i++) {
                tmp += str.get_char (i).to_string ();
            }
            return tmp.dup ();
        }

        /**
         * Returns whether substr is included in the s.
         * @param s The string to be searched
         * @param substr Search keyword
         * @return true: substr is included, false substr is not included.
         */
        public static bool contains (string ? s, string ? substr) {
            if (isNullOrEmpty (s) || isNullOrEmpty (substr)) {
                return false;
            }
            return s.contains (substr);
        }

        /**
         * Split the string by the specified number of characters and returns it as an
         * array of strings.
         * @param str Character string to be splited
         * @return Array of split string.
         */
        public static string[] splitByNum (string str, uint num) {
            if (Objects.isNull (str) || num == 0) {
                return new string[1];
            }

            string[] strs = {};
            string tmp = "";
            for (int i = 0; i < str.length; i++) {
                tmp += str.get_char (i).to_string ();
                if (i != 0 && i % num == 0) {
                    strs += tmp;
                    tmp = "";
                }
            }
            strs += tmp;
            return strs;
        }
    }
}