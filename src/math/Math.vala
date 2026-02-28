namespace Vala.Math {
    /**
     * Static utility methods for mathematics.
     */
    public class Math : GLib.Object {
        public const double PI = GLib.Math.PI;
        public const double E = GLib.Math.E;

        /**
         * Returns absolute value.
         *
         * @param x input value.
         * @return absolute value.
         */
        public static double abs (double x) {
            return GLib.Math.fabs (x);
        }

        /**
         * Returns the larger value.
         *
         * @param a first value.
         * @param b second value.
         * @return larger value.
         */
        public static double max (double a, double b) {
            return GLib.Math.fmax (a, b);
        }

        /**
         * Returns the smaller value.
         *
         * @param a first value.
         * @param b second value.
         * @return smaller value.
         */
        public static double min (double a, double b) {
            return GLib.Math.fmin (a, b);
        }

        /**
         * Clamps value into [lo, hi].
         *
         * @param x value.
         * @param lo lower bound.
         * @param hi upper bound.
         * @return clamped value.
         */
        public static double clamp (double x, double lo, double hi) {
            if (lo > hi) {
                error ("lo must be less than or equal to hi");
            }

            if (x < lo) {
                return lo;
            }
            if (x > hi) {
                return hi;
            }
            return x;
        }

        /**
         * Returns floor value.
         *
         * @param x input value.
         * @return floor value.
         */
        public static double floor (double x) {
            return GLib.Math.floor (x);
        }

        /**
         * Returns ceil value.
         *
         * @param x input value.
         * @return ceil value.
         */
        public static double ceil (double x) {
            return GLib.Math.ceil (x);
        }

        /**
         * Returns rounded value.
         *
         * @param x input value.
         * @return rounded value.
         */
        public static double round (double x) {
            return GLib.Math.round (x);
        }

        /**
         * Returns power.
         *
         * @param base_value base value.
         * @param exp exponent value.
         * @return base raised to exp.
         */
        public static double pow (double base_value, double exp) {
            return GLib.Math.pow (base_value, exp);
        }

        /**
         * Returns square root.
         *
         * @param x input value.
         * @return square root.
         */
        public static double sqrt (double x) {
            return GLib.Math.sqrt (x);
        }

        /**
         * Returns natural logarithm.
         *
         * @param x input value.
         * @return natural log.
         */
        public static double log (double x) {
            return GLib.Math.log (x);
        }

        /**
         * Returns base-10 logarithm.
         *
         * @param x input value.
         * @return base-10 log.
         */
        public static double log10 (double x) {
            return GLib.Math.log10 (x);
        }

        /**
         * Returns sine.
         *
         * @param x angle in radians.
         * @return sine value.
         */
        public static double sin (double x) {
            return GLib.Math.sin (x);
        }

        /**
         * Returns cosine.
         *
         * @param x angle in radians.
         * @return cosine value.
         */
        public static double cos (double x) {
            return GLib.Math.cos (x);
        }

        /**
         * Returns tangent.
         *
         * @param x angle in radians.
         * @return tangent value.
         */
        public static double tan (double x) {
            return GLib.Math.tan (x);
        }

        /**
         * Returns greatest common divisor.
         *
         * @param a first number.
         * @param b second number.
         * @return greatest common divisor.
         */
        public static int64 gcd (int64 a, int64 b) {
            int64 x = _abs_int64 (a);
            int64 y = _abs_int64 (b);

            while (y != 0) {
                int64 t = x % y;
                x = y;
                y = t;
            }

            return x;
        }

        /**
         * Returns least common multiple.
         *
         * @param a first number.
         * @param b second number.
         * @return least common multiple.
         */
        public static int64 lcm (int64 a, int64 b) {
            if (a == 0 || b == 0) {
                return 0;
            }

            return _abs_int64 ((a / gcd (a, b)) * b);
        }

        /**
         * Returns whether n is prime.
         *
         * @param n input number.
         * @return true if prime.
         */
        public static bool isPrime (int64 n) {
            if (n <= 1) {
                return false;
            }
            if (n <= 3) {
                return true;
            }
            if ((n % 2) == 0) {
                return false;
            }

            for (int64 i = 3; i <= (n / i); i += 2) {
                if ((n % i) == 0) {
                    return false;
                }
            }

            return true;
        }

        /**
         * Returns factorial.
         *
         * @param n non-negative integer.
         * @return factorial value.
         */
        public static int64 factorial (int n) {
            if (n < 0) {
                error ("n must be non-negative");
            }

            int64 result = 1;
            for (int i = 2; i <= n; i++) {
                result *= i;
            }
            return result;
        }

        private static int64 _abs_int64 (int64 x) {
            return x < 0 ? -x : x;
        }
    }
}
