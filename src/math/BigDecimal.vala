namespace Vala.Math {
    /**
     * Immutable arbitrary-precision decimal value object.
     */
    public class BigDecimal : GLib.Object {
        private const int DEFAULT_DIVIDE_SCALE = 16;

        private BigInteger _unscaled;
        private int _scale;

        /**
         * Creates a BigDecimal from decimal text.
         *
         * @param value decimal text (optional sign and decimal point).
         */
        public BigDecimal (string value) {
            BigInteger unscaled;
            int parsedScale;
            if (!tryParseComponents (value, out unscaled, out parsedScale)) {
                error ("invalid decimal text");
            }

            BigDecimal normalized = fromComponents (unscaled, parsedScale);
            _unscaled = new BigInteger (normalized._unscaled.toString ());
            _scale = normalized._scale;
        }

        private BigDecimal.fromParts (BigInteger unscaled, int scale) {
            _unscaled = unscaled;
            _scale = scale;
        }

        /**
         * Parses decimal text and returns null for invalid input.
         *
         * @param value decimal text.
         * @return parsed value or null.
         */
        public static BigDecimal ? parse (string value) {
            BigInteger unscaled;
            int parsedScale;
            if (!tryParseComponents (value, out unscaled, out parsedScale)) {
                return null;
            }
            return fromComponents (unscaled, parsedScale);
        }

        /**
         * Returns normalized decimal representation.
         *
         * @return normalized decimal text.
         */
        public string toString () {
            string raw = _unscaled.toString ();
            bool negative = raw.has_prefix ("-");
            string digits = negative ? raw.substring (1) : raw;

            if (digits == "0") {
                return "0";
            }
            if (_scale == 0) {
                return negative ? "-" + digits : digits;
            }

            string body;
            if (digits.length <= _scale) {
                var builder = new GLib.StringBuilder ("0.");
                for (int i = 0; i < _scale - digits.length; i++) {
                    builder.append_c ('0');
                }
                builder.append (digits);
                body = builder.str;
            } else {
                int point = digits.length - _scale;
                body = digits.substring (0, point) + "." + digits.substring (point);
            }
            return negative ? "-" + body : body;
        }

        /**
         * Returns fractional scale.
         *
         * @return scale (number of fractional digits).
         */
        public int scale () {
            return _scale;
        }

        /**
         * Returns absolute value.
         *
         * @return absolute value.
         */
        public BigDecimal abs () {
            if (_unscaled.toString ().has_prefix ("-")) {
                return fromComponents (new BigInteger (_unscaled.toString ().substring (1)), _scale);
            }
            return fromComponents (new BigInteger (_unscaled.toString ()), _scale);
        }

        /**
         * Returns value with inverted sign.
         *
         * @return negated value.
         */
        public BigDecimal negate () {
            string text = _unscaled.toString ();
            if (text == "0") {
                return fromComponents (new BigInteger ("0"), 0);
            }
            if (text.has_prefix ("-")) {
                return fromComponents (new BigInteger (text.substring (1)), _scale);
            }
            return fromComponents (new BigInteger ("-" + text), _scale);
        }

        /**
         * Compares this value to other.
         *
         * @param other value to compare.
         * @return -1, 0, or 1.
         */
        public int compareTo (BigDecimal other) {
            int targetScale = _scale > other._scale ? _scale : other._scale;
            BigInteger left = scaleUp (_unscaled, targetScale - _scale);
            BigInteger right = scaleUp (other._unscaled, targetScale - other._scale);
            return compareBigInteger (left, right);
        }

        /**
         * Returns sum of this value and other.
         *
         * @param other value to add.
         * @return computed sum.
         */
        public BigDecimal add (BigDecimal other) {
            int targetScale = _scale > other._scale ? _scale : other._scale;
            BigInteger left = scaleUp (_unscaled, targetScale - _scale);
            BigInteger right = scaleUp (other._unscaled, targetScale - other._scale);
            return fromComponents (left.add (right), targetScale);
        }

        /**
         * Returns this value minus other.
         *
         * @param other value to subtract.
         * @return computed difference.
         */
        public BigDecimal subtract (BigDecimal other) {
            int targetScale = _scale > other._scale ? _scale : other._scale;
            BigInteger left = scaleUp (_unscaled, targetScale - _scale);
            BigInteger right = scaleUp (other._unscaled, targetScale - other._scale);
            return fromComponents (left.subtract (right), targetScale);
        }

        /**
         * Returns product of this value and other.
         *
         * @param other multiplier.
         * @return computed product.
         */
        public BigDecimal multiply (BigDecimal other) {
            BigInteger product = _unscaled.multiply (other._unscaled);
            return fromComponents (product, _scale + other._scale);
        }

        /**
         * Returns quotient of this value divided by other.
         *
         * Quotient is truncated toward zero with up to 16 fractional digits.
         *
         * @param other divisor.
         * @return quotient.
         */
        public BigDecimal divide (BigDecimal other) {
            return divideWithScale (other, DEFAULT_DIVIDE_SCALE);
        }

        /**
         * Returns quotient with explicit scale.
         *
         * Quotient is truncated toward zero.
         *
         * @param other divisor.
         * @param scale scale for quotient.
         * @return quotient.
         */
        public BigDecimal divideWithScale (BigDecimal other, int scale) {
            if (scale < 0) {
                error ("scale must be non-negative");
            }
            if (other._unscaled.toString () == "0") {
                error ("division by zero");
            }

            BigInteger numerator = _unscaled.multiply (pow10 (scale + other._scale));
            BigInteger denominator = other._unscaled.multiply (pow10 (_scale));
            BigInteger quotient = numerator.divide (denominator);
            return fromComponents (quotient, scale);
        }

        /**
         * Returns remainder of this value divided by other.
         *
         * @param other divisor.
         * @return remainder.
         */
        public BigDecimal mod (BigDecimal other) {
            if (other._unscaled.toString () == "0") {
                error ("division by zero");
            }

            BigInteger numerator = _unscaled.multiply (pow10 (other._scale));
            BigInteger denominator = other._unscaled.multiply (pow10 (_scale));
            BigInteger quotient = numerator.divide (denominator);
            BigDecimal scaledQuotient = fromComponents (quotient, 0);
            return subtract (other.multiply (scaledQuotient));
        }

        /**
         * Returns this value raised to exponent.
         *
         * @param exponent non-negative exponent.
         * @return computed power.
         */
        public BigDecimal pow (int exponent) {
            if (exponent < 0) {
                error ("exponent must be non-negative");
            }
            return fromComponents (_unscaled.pow (exponent), _scale * exponent);
        }

        private static BigDecimal fromComponents (BigInteger unscaled, int scale) {
            if (scale < 0) {
                error ("scale must be non-negative");
            }

            string text = unscaled.toString ();
            bool negative = text.has_prefix ("-");
            string digits = negative ? text.substring (1) : text;
            if (digits == "0") {
                return new BigDecimal.fromParts (new BigInteger ("0"), 0);
            }

            while (scale > 0 && digits[digits.length - 1] == '0') {
                digits = digits.substring (0, digits.length - 1);
                scale--;
            }

            string normalized = negative ? "-" + digits : digits;
            return new BigDecimal.fromParts (new BigInteger (normalized), scale);
        }

        private static BigInteger scaleUp (BigInteger value, int scaleDelta) {
            if (scaleDelta <= 0) {
                return new BigInteger (value.toString ());
            }
            return value.multiply (pow10 (scaleDelta));
        }

        private static BigInteger pow10 (int n) {
            if (n < 0) {
                error ("n must be non-negative");
            }
            if (n == 0) {
                return new BigInteger ("1");
            }

            var builder = new GLib.StringBuilder ("1");
            for (int i = 0; i < n; i++) {
                builder.append_c ('0');
            }
            return new BigInteger (builder.str);
        }

        private static int compareBigInteger (BigInteger left, BigInteger right) {
            string leftText = left.toString ();
            string rightText = right.toString ();

            bool leftNegative = leftText.has_prefix ("-");
            bool rightNegative = rightText.has_prefix ("-");

            if (leftNegative && !rightNegative) {
                return -1;
            }
            if (!leftNegative && rightNegative) {
                return 1;
            }

            string leftAbs = leftNegative ? leftText.substring (1) : leftText;
            string rightAbs = rightNegative ? rightText.substring (1) : rightText;
            int absCmp = compareMagnitude (leftAbs, rightAbs);
            if (leftNegative) {
                return -absCmp;
            }
            return absCmp;
        }

        private static int compareMagnitude (string left, string right) {
            if (left.length > right.length) {
                return 1;
            }
            if (left.length < right.length) {
                return -1;
            }
            for (int i = 0; i < left.length; i++) {
                if (left[i] > right[i]) {
                    return 1;
                }
                if (left[i] < right[i]) {
                    return -1;
                }
            }
            return 0;
        }

        private static bool tryParseComponents (string value, out BigInteger unscaled, out int scale) {
            unscaled = new BigInteger ("0");
            scale = 0;

            if (value.length == 0) {
                return false;
            }

            int index = 0;
            bool negative = false;
            if (value[0] == '-') {
                negative = true;
                index = 1;
            } else if (value[0] == '+') {
                index = 1;
            }
            if (index >= value.length) {
                return false;
            }

            bool seenDot = false;
            bool hasDigit = false;
            var digitsBuilder = new GLib.StringBuilder ();

            for (int i = index; i < value.length; i++) {
                char c = value[i];
                if (c == '.') {
                    if (seenDot) {
                        return false;
                    }
                    seenDot = true;
                    continue;
                }

                if (c < '0' || c > '9') {
                    return false;
                }

                hasDigit = true;
                digitsBuilder.append_c (c);
                if (seenDot) {
                    scale++;
                }
            }

            if (!hasDigit) {
                return false;
            }

            string digits = digitsBuilder.str;
            int firstNonZero = 0;
            while (firstNonZero < digits.length && digits[firstNonZero] == '0') {
                firstNonZero++;
            }

            if (firstNonZero == digits.length) {
                unscaled = new BigInteger ("0");
                scale = 0;
                return true;
            }

            digits = digits.substring (firstNonZero);
            while (scale > 0 && digits[digits.length - 1] == '0') {
                digits = digits.substring (0, digits.length - 1);
                scale--;
            }

            string unscaledText = negative ? "-" + digits : digits;
            unscaled = new BigInteger (unscaledText);
            return true;
        }
    }
}
