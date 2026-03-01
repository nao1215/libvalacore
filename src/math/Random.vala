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
     *     int x = Random.nextIntRange (10, 20);
     *     bool coin = Random.nextBool ();
     * }}}
     */
    public class Random : GLib.Object {
        /**
         * Returns a random integer in [0, bound).
         *
         * @param bound exclusive upper bound.
         * @return random integer.
         * @throws RandomError.INVALID_ARGUMENT when bound is not positive.
         */
        public static int nextInt (int bound) throws RandomError {
            if (bound <= 0) {
                throw new RandomError.INVALID_ARGUMENT ("bound must be greater than zero");
            }
            return GLib.Random.int_range (0, bound);
        }

        /**
         * Returns a random integer in [min, max).
         *
         * @param min inclusive lower bound.
         * @param max exclusive upper bound.
         * @return random integer.
         * @throws RandomError.INVALID_ARGUMENT when min is not less than max.
         */
        public static int nextIntRange (int min, int max) throws RandomError {
            if (min >= max) {
                throw new RandomError.INVALID_ARGUMENT ("min must be less than max");
            }
            return GLib.Random.int_range (min, max);
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
