namespace Vala.Math {
    /**
     * Recoverable BigInteger argument errors.
     */
    public errordomain BigIntegerError {
        INVALID_ARGUMENT,
        DIVISION_BY_ZERO
    }

    /**
     * Immutable arbitrary-precision integer value object.
     */
    public class BigInteger : GLib.Object {
        private string _value;

        /**
         * Creates a BigInteger from decimal text.
         *
         * @param value decimal text (optional leading + or -).
         * @throws BigIntegerError.INVALID_ARGUMENT when value is invalid decimal text.
         */
        public BigInteger (string value) throws BigIntegerError {
            _value = normalize (value);
        }

        private BigInteger.fromNormalized (string normalizedValue) {
            _value = normalizedValue;
        }

        /**
         * Returns decimal representation.
         *
         * @return normalized decimal text.
         */
        public string toString () {
            return _value;
        }

        /**
         * Returns the sum of this value and other.
         *
         * @param other value to add.
         * @return computed sum.
         */
        public BigInteger add (BigInteger other) {
            bool leftNegative = isNegative (_value);
            bool rightNegative = isNegative (other._value);
            string leftAbs = absValue (_value);
            string rightAbs = absValue (other._value);

            if (leftNegative == rightNegative) {
                string absSum = addAbs (leftAbs, rightAbs);
                if (leftNegative && absSum != "0") {
                    return new BigInteger.fromNormalized ("-" + absSum);
                }
                return new BigInteger.fromNormalized (absSum);
            }

            int cmp = compareAbs (leftAbs, rightAbs);
            if (cmp == 0) {
                return new BigInteger.fromNormalized ("0");
            }
            if (cmp > 0) {
                string absDiff = subtractAbs (leftAbs, rightAbs);
                if (leftNegative) {
                    return new BigInteger.fromNormalized ("-" + absDiff);
                }
                return new BigInteger.fromNormalized (absDiff);
            }

            string reversedDiff = subtractAbs (rightAbs, leftAbs);
            if (rightNegative) {
                return new BigInteger.fromNormalized ("-" + reversedDiff);
            }
            return new BigInteger.fromNormalized (reversedDiff);
        }

        /**
         * Returns this value minus other.
         *
         * @param other value to subtract.
         * @return computed difference.
         */
        public BigInteger subtract (BigInteger other) {
            return add (other.negate ());
        }

        /**
         * Returns product of this value and other.
         *
         * @param other multiplier.
         * @return computed product.
         */
        public BigInteger multiply (BigInteger other) {
            string absProduct = multiplyAbs (absValue (_value), absValue (other._value));
            if (absProduct == "0") {
                return new BigInteger.fromNormalized ("0");
            }
            bool negative = isNegative (_value) != isNegative (other._value);
            if (negative) {
                return new BigInteger.fromNormalized ("-" + absProduct);
            }
            return new BigInteger.fromNormalized (absProduct);
        }

        /**
         * Returns integer quotient of this value divided by other.
         *
         * Division is truncated toward zero.
         *
         * @param other divisor.
         * @return quotient.
         * @throws BigIntegerError.DIVISION_BY_ZERO when other is zero.
         */
        public BigInteger divide (BigInteger other) throws BigIntegerError {
            string divisorAbs = absValue (other._value);
            if (divisorAbs == "0") {
                throw new BigIntegerError.DIVISION_BY_ZERO ("division by zero");
            }

            string remainder;
            string quotientAbs = divideAbs (absValue (_value), divisorAbs, out remainder);
            if (quotientAbs == "0") {
                return new BigInteger.fromNormalized ("0");
            }

            bool negative = isNegative (_value) != isNegative (other._value);
            if (negative) {
                return new BigInteger.fromNormalized ("-" + quotientAbs);
            }
            return new BigInteger.fromNormalized (quotientAbs);
        }

        /**
         * Returns integer remainder of this value divided by other.
         *
         * Remainder sign follows this value (dividend).
         *
         * @param other divisor.
         * @return remainder.
         * @throws BigIntegerError.DIVISION_BY_ZERO when other is zero.
         */
        public BigInteger mod (BigInteger other) throws BigIntegerError {
            string divisorAbs = absValue (other._value);
            if (divisorAbs == "0") {
                throw new BigIntegerError.DIVISION_BY_ZERO ("division by zero");
            }

            string remainder;
            divideAbs (absValue (_value), divisorAbs, out remainder);
            if (remainder == "0") {
                return new BigInteger.fromNormalized ("0");
            }
            if (isNegative (_value)) {
                return new BigInteger.fromNormalized ("-" + remainder);
            }
            return new BigInteger.fromNormalized (remainder);
        }

        /**
         * Returns this value raised to exponent.
         *
         * @param exponent non-negative exponent.
         * @return computed power.
         * @throws BigIntegerError.INVALID_ARGUMENT when exponent is negative.
         */
        public BigInteger pow (int exponent) throws BigIntegerError {
            if (exponent < 0) {
                throw new BigIntegerError.INVALID_ARGUMENT ("exponent must be non-negative");
            }

            BigInteger result = new BigInteger.fromNormalized ("1");
            BigInteger baseValue = new BigInteger.fromNormalized (_value);
            int current = exponent;

            while (current > 0) {
                if ((current & 1) == 1) {
                    result = result.multiply (baseValue);
                }
                current >>= 1;
                if (current > 0) {
                    baseValue = baseValue.multiply (baseValue);
                }
            }
            return result;
        }

        private BigInteger negate () {
            if (_value == "0") {
                return new BigInteger.fromNormalized ("0");
            }
            if (isNegative (_value)) {
                return new BigInteger.fromNormalized (absValue (_value));
            }
            return new BigInteger.fromNormalized ("-" + _value);
        }

        private static bool isNegative (string value) {
            return value.has_prefix ("-");
        }

        private static string absValue (string value) {
            if (isNegative (value)) {
                return value.substring (1);
            }
            return value;
        }

        private static string normalize (string value) throws BigIntegerError {
            if (value.length == 0) {
                throw new BigIntegerError.INVALID_ARGUMENT ("value must not be empty");
            }

            int index = 0;
            bool negative = false;
            unichar first = value.get_char (0);
            if (first == '-') {
                negative = true;
                index = 1;
            } else if (first == '+') {
                index = 1;
            }

            if (index >= value.length) {
                throw new BigIntegerError.INVALID_ARGUMENT ("invalid integer text");
            }

            for (int i = index; i < value.length; i++) {
                unichar c = value.get_char (i);
                if (c < '0' || c > '9') {
                    throw new BigIntegerError.INVALID_ARGUMENT ("invalid integer text");
                }
            }

            while (index < value.length && value.get_char (index) == '0') {
                index++;
            }
            if (index == value.length) {
                return "0";
            }

            string absolute = value.substring (index);
            if (negative) {
                return "-" + absolute;
            }
            return absolute;
        }

        private static int compareAbs (string left, string right) {
            if (left.length > right.length) {
                return 1;
            }
            if (left.length < right.length) {
                return -1;
            }
            for (int i = 0; i < left.length; i++) {
                unichar l = left.get_char (i);
                unichar r = right.get_char (i);
                if (l > r) {
                    return 1;
                }
                if (l < r) {
                    return -1;
                }
            }
            return 0;
        }

        private static int digitToInt (unichar c) {
            return (int) (c - '0');
        }

        private static string stripLeadingZeros (string value) {
            int index = 0;
            while (index < value.length && value.get_char (index) == '0') {
                index++;
            }
            if (index == value.length) {
                return "0";
            }
            return value.substring (index);
        }

        private static string addAbs (string left, string right) {
            GLib.StringBuilder builder = new GLib.StringBuilder ();
            int i = left.length - 1;
            int j = right.length - 1;
            int carry = 0;

            while (i >= 0 || j >= 0 || carry > 0) {
                int sum = carry;
                if (i >= 0) {
                    sum += digitToInt (left.get_char (i));
                    i--;
                }
                if (j >= 0) {
                    sum += digitToInt (right.get_char (j));
                    j--;
                }
                builder.prepend_c ((char) ('0' + (sum % 10)));
                carry = sum / 10;
            }

            return stripLeadingZeros (builder.str);
        }

        private static string subtractAbs (string left, string right) {
            GLib.StringBuilder builder = new GLib.StringBuilder ();
            int i = left.length - 1;
            int j = right.length - 1;
            int borrow = 0;

            while (i >= 0) {
                int leftDigit = digitToInt (left.get_char (i));
                int rightDigit = j >= 0 ? digitToInt (right.get_char (j)) : 0;
                int diff = leftDigit - borrow - rightDigit;

                if (diff < 0) {
                    diff += 10;
                    borrow = 1;
                } else {
                    borrow = 0;
                }

                builder.prepend_c ((char) ('0' + diff));
                i--;
                j--;
            }

            return stripLeadingZeros (builder.str);
        }

        private static string multiplyAbs (string left, string right) {
            if (left == "0" || right == "0") {
                return "0";
            }

            int[] digits = new int[left.length + right.length];
            for (int i = left.length - 1; i >= 0; i--) {
                int leftDigit = digitToInt (left.get_char (i));
                for (int j = right.length - 1; j >= 0; j--) {
                    int rightDigit = digitToInt (right.get_char (j));
                    int positionLow = i + j + 1;
                    int positionHigh = i + j;
                    int sum = leftDigit * rightDigit + digits[positionLow];
                    digits[positionLow] = sum % 10;
                    digits[positionHigh] += sum / 10;
                }
            }

            for (int i = digits.length - 1; i > 0; i--) {
                digits[i - 1] += digits[i] / 10;
                digits[i] %= 10;
            }

            GLib.StringBuilder builder = new GLib.StringBuilder ();
            bool leading = true;
            for (int i = 0; i < digits.length; i++) {
                if (leading && digits[i] == 0) {
                    continue;
                }
                leading = false;
                builder.append_c ((char) ('0' + digits[i]));
            }

            if (leading) {
                return "0";
            }
            return builder.str;
        }

        private static string appendDigit (string value, unichar digit) {
            if (value == "0") {
                return digit.to_string ();
            }
            return value + digit.to_string ();
        }

        private static string divideAbs (string dividend, string divisor, out string remainder) {
            // divide() / mod() validate zero divisor before reaching divideAbs().
            if (compareAbs (dividend, divisor) < 0) {
                remainder = stripLeadingZeros (dividend);
                return "0";
            }

            GLib.StringBuilder quotient = new GLib.StringBuilder ();
            string current = "0";

            for (int i = 0; i < dividend.length; i++) {
                current = appendDigit (current, dividend.get_char (i));
                current = stripLeadingZeros (current);

                int count = 0;
                while (compareAbs (current, divisor) >= 0) {
                    current = subtractAbs (current, divisor);
                    count++;
                }

                quotient.append_c ((char) ('0' + count));
            }

            remainder = stripLeadingZeros (current);
            return stripLeadingZeros (quotient.str);
        }
    }
}
