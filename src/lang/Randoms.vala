namespace Vala.Lang {
    /**
     * Random utility methods.
     */
    public class Randoms : GLib.Object {
        /**
         * Returns a random integer in [0, bound).
         *
         * @param bound exclusive upper bound.
         * @return random integer.
         */
        public static int nextInt (int bound) {
            if (bound <= 0) {
                error ("bound must be greater than zero");
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
