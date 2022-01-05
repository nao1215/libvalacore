/*
 * libvalacore/src/os/Os.vala
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
     * Os class is operating system interfaces.
     */
    public class Os : GLib.Object {
        /**
         * Returns the value of the environment variable.
         * @param env string of environment variable
         * @return If the environment variable env is set, its value is returned.
         * If not set, returns null.
         */
        public static string ? get_env (string env) {
            if (Objects.isNull (env)) {
                return null;
            }
            return Environment.get_variable (env).dup ();
        }

        /**
         * Returns current working directory.
         * @return If the environment variable "PWD" is set to a value, that value is returned.
         * Returns null if the value is not set.
         */
        public static string ? cwd () {
            return Environment.get_current_dir ();
        }

        /**
         * Change current directory.
         * @param path string containing the new current directory
         * @return true: change directory is success, false: change directory is fail.
         */
        public static bool chdir (string path) {
            if (Objects.isNull (path)) {
                return false;
            }
            return Posix.chdir (path) == 0 ? true : false;
        }
    }
}
