namespace Vala.Math {
    /**
     * Static utility methods for random values.
     */
    public class Random : GLib.Object {
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
         * Returns a random integer in [min, max).
         *
         * @param min inclusive lower bound.
         * @param max exclusive upper bound.
         * @return random integer.
         */
        public static int nextIntRange (int min, int max) {
            if (min >= max) {
                error ("min must be less than max");
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
        public static T? choice<T> (T[] array) {
            if (array.length == 0) {
                return null;
            }

            int index = GLib.Random.int_range (0, array.length);
            return array[index];
        }
    }
}
