namespace Vala.Lang {
    /**
     * Recoverable random utility argument errors.
     */
    public errordomain RandomsError {
        INVALID_ARGUMENT
    }

    /**
     * Random utility methods.
     *
     * This class offers common random operations for quick application logic:
     * bounded integers, doubles, and in-place array shuffling.
     *
     * Example:
     * {{{
     *     int id = Randoms.nextInt (1000);
     *     double ratio = Randoms.nextDouble ();
     *
     *     int[] values = { 1, 2, 3, 4 };
     *     Randoms.shuffle<int> (values);
     * }}}
     */
    public class Randoms : GLib.Object {
        /**
         * Returns a random integer in [0, bound).
         *
         * @param bound exclusive upper bound.
         * @return random integer.
         * @throws RandomsError.INVALID_ARGUMENT when bound is not positive.
         */
        public static int nextInt (int bound) throws RandomsError {
            if (bound <= 0) {
                throw new RandomsError.INVALID_ARGUMENT ("bound must be greater than zero");
            }
            return GLib.Random.int_range (0, bound);
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
    }
}
