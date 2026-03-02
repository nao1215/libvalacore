namespace Vala.Math {
    /**
     * Recoverable random utility argument errors.
     */
    public errordomain RandomError {
        INVALID_ARGUMENT
    }

    /**
     * Static utility methods for random values.
     *
     * Provides convenience generators for primitive random values and helper
     * operations such as in-place shuffle and random choice.
     *
     * Example:
     * {{{
     *     var x = Random.nextIntRange (10, 20);
     *     bool coin = Random.nextBool ();
     * }}}
     */
    public class Random : GLib.Object {
        /**
         * Returns a random integer in [0, bound).
         *
         * @param bound exclusive upper bound.
         * @return Result containing random integer, or INVALID_ARGUMENT error.
         */
        public static Vala.Collections.Result<int, GLib.Error> nextInt (int bound) {
            if (bound <= 0) {
                return Vala.Collections.Result.error<int, GLib.Error> (
                    new RandomError.INVALID_ARGUMENT ("bound must be greater than zero")
                );
            }
            return Vala.Collections.Result.ok<int, GLib.Error> (GLib.Random.int_range (0, bound));
        }

        /**
         * Returns a random integer in [min, max).
         *
         * @param min inclusive lower bound.
         * @param max exclusive upper bound.
         * @return Result containing random integer, or INVALID_ARGUMENT error.
         */
        public static Vala.Collections.Result<int, GLib.Error> nextIntRange (int min, int max) {
            if (min >= max) {
                return Vala.Collections.Result.error<int, GLib.Error> (
                    new RandomError.INVALID_ARGUMENT ("min must be less than max")
                );
            }
            return Vala.Collections.Result.ok<int, GLib.Error> (GLib.Random.int_range (min, max));
        }

        /**
         * Returns a random double in [0.0, 1.0).
         *
         * @return random double.
         */
        public static double nextDouble () {
            return GLib.Random.next_double ();
        }

        /**
         * Returns a random boolean.
         *
         * @return random boolean.
         */
        public static bool nextBool () {
            return GLib.Random.int_range (0, 2) == 1;
        }

        /**
         * Shuffles an array in place.
         *
         * @param array target array.
         */
        public static void shuffle<T> (T[] array) {
            for (int i = array.length - 1; i > 0; i--) {
                int j = GLib.Random.int_range (0, i + 1);
                T tmp = array[i];
                array[i] = array[j];
                array[j] = tmp;
            }
        }

        /**
         * Returns a random element from array.
         *
         * Returns null for an empty array.
         *
         * @param array source array.
         * @return random element or null.
         */
        public static T ? choice<T> (T[] array) {
            if (array.length == 0) {
                return null;
            }

            int index = GLib.Random.int_range (0, array.length);
            return array[index];
        }
    }
}
