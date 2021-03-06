/*
 * libvalacore/src/io/Objects.vala
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
namespace Vala.Lang {
    /**
     * Objects class is a collection of static APIs for manipulating objects
     */
    public class Objects : GLib.Object {
        /**
         * Returns whether the object is null.
         * @param obj Object to be checked.
         * @return true: object is null, false: object is not null.
         */
        public static bool isNull<T>(T ? obj) {
            return obj == null;
        }

        /**
         * Returns whether the object is not null.
         * @param obj Object to be checked.
         * @return true: object is not null, false: object is null.
         */
        public static bool nonNull<T>(T ? obj) {
            return !isNull (obj);
        }
    }
}