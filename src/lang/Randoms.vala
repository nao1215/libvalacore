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
     *     var idResult = Randoms.nextInt (1000);
     *     if (idResult.isOk ()) {
     *         int? id = idResult.unwrap ();
     *     }
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
         * @return Result containing random integer, or INVALID_ARGUMENT error.
         */
        public static Vala.Collections.Result<int, GLib.Error> nextInt (int bound) {
            if (bound <= 0) {
                return Vala.Collections.Result.error<int, GLib.Error> (
                    new RandomsError.INVALID_ARGUMENT ("bound must be greater than zero")
                );
            }
            return Vala.Collections.Result.ok<int, GLib.Error> (GLib.Random.int_range (0, bound));
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
