namespace Vala.Collections {
    /**
     * Static utility methods for int arrays.
     */
    public class Arrays : GLib.Object {
        /**
         * Sorts an int array in ascending order.
         *
         * @param arr target array.
         */
        public static void sort (int[] arr) {
            for (int i = 1; i < arr.length; i++) {
                int value = arr[i];
                int j = i - 1;
                while (j >= 0 && arr[j] > value) {
                    arr[j + 1] = arr[j];
                    j--;
                }
                arr[j + 1] = value;
            }
        }

        /**
         * Performs binary search on an ascending-sorted int array.
         *
         * @param arr ascending-sorted array.
         * @param key target value.
         * @return index when found, -1 otherwise.
         */
        public static int binarySearch (int[] arr, int key) {
            int left = 0;
            int right = arr.length - 1;

            while (left <= right) {
                int mid = left + (right - left) / 2;
                int value = arr[mid];

                if (value == key) {
                    return mid;
                }
                if (value < key) {
                    left = mid + 1;
                } else {
                    right = mid - 1;
                }
            }

            return -1;
        }

        /**
         * Copies an int array with a new length.
         *
         * New trailing elements are zero when expanded.
         *
         * @param arr source array.
         * @param newLen target length (must be >= 0, otherwise empty array).
         * @return copied array.
         */
        public static int[] copyOf (int[] arr, int newLen) {
            if (newLen < 0) {
                return {};
            }

            int[] copied = new int[newLen];
            int limit = arr.length < newLen ? arr.length : newLen;
            for (int i = 0; i < limit; i++) {
                copied[i] = arr[i];
            }
            return copied;
        }

        /**
         * Fills all elements with the same value.
         *
         * @param arr target array.
         * @param val fill value.
         */
        public static void fill (int[] arr, int val) {
            for (int i = 0; i < arr.length; i++) {
                arr[i] = val;
            }
        }

        /**
         * Returns whether two arrays are equal.
         *
         * @param a first array.
         * @param b second array.
         * @return true when same length and elements.
         */
        public static bool equals (int[] a, int[] b) {
            if (a.length != b.length) {
                return false;
            }
            for (int i = 0; i < a.length; i++) {
                if (a[i] != b[i]) {
                    return false;
                }
            }
            return true;
        }
    }
}
