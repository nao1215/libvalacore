using Vala.Math;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/math/biginteger/testNormalize", testNormalize);
    Test.add_func ("/math/biginteger/testAdd", testAdd);
    Test.add_func ("/math/biginteger/testSubtract", testSubtract);
    Test.add_func ("/math/biginteger/testMultiply", testMultiply);
    Test.add_func ("/math/biginteger/testDivideAndMod", testDivideAndMod);
    Test.add_func ("/math/biginteger/testPow", testPow);
    Test.add_func ("/math/biginteger/testLargeValues", testLargeValues);
    Test.add_func ("/math/biginteger/testInvalidArguments", testInvalidArguments);
    Test.run ();
}

BigInteger bi (string value) {
    var parsed = BigInteger.of (value);
    assert (parsed.isOk ());
    return parsed.unwrap ();
}

BigInteger divideOk (BigInteger left, BigInteger right) {
    var quotient = left.divide (right);
    assert (quotient.isOk ());
    return quotient.unwrap ();
}

BigInteger modOk (BigInteger left, BigInteger right) {
    var remainder = left.mod (right);
    assert (remainder.isOk ());
    return remainder.unwrap ();
}

BigInteger powOk (BigInteger value, int exponent) {
    var powered = value.pow (exponent);
    assert (powered.isOk ());
    return powered.unwrap ();
}

void testNormalize () {
    assert (bi ("000123").toString () == "123");
    assert (bi ("-00000123").toString () == "-123");
    assert (bi ("+0000").toString () == "0");
}

void testAdd () {
    assert (bi ("123").add (bi ("456")).toString () == "579");
    assert (bi ("-10").add (bi ("3")).toString () == "-7");
    assert (bi ("-10").add (bi ("-3")).toString () == "-13");
    assert (bi ("10").add (bi ("-10")).toString () == "0");
}

void testSubtract () {
    assert (bi ("10").subtract (bi ("3")).toString () == "7");
    assert (bi ("3").subtract (bi ("10")).toString () == "-7");
    assert (bi ("-3").subtract (bi ("10")).toString () == "-13");
    assert (bi ("-3").subtract (bi ("-10")).toString () == "7");
}

void testMultiply () {
    assert (bi ("12").multiply (bi ("7")).toString () == "84");
    assert (bi ("-12").multiply (bi ("7")).toString () == "-84");
    assert (bi ("-12").multiply (bi ("-7")).toString () == "84");
    assert (bi ("0").multiply (bi ("999999")).toString () == "0");
}

void testDivideAndMod () {
    assert (divideOk (bi ("10"), bi ("3")).toString () == "3");
    assert (modOk (bi ("10"), bi ("3")).toString () == "1");

    assert (divideOk (bi ("-10"), bi ("3")).toString () == "-3");
    assert (modOk (bi ("-10"), bi ("3")).toString () == "-1");

    assert (divideOk (bi ("10"), bi ("-3")).toString () == "-3");
    assert (modOk (bi ("10"), bi ("-3")).toString () == "1");

    assert (divideOk (bi ("2"), bi ("5")).toString () == "0");
    assert (modOk (bi ("2"), bi ("5")).toString () == "2");
}

void testPow () {
    assert (powOk (bi ("2"), 0).toString () == "1");
    assert (powOk (bi ("2"), 10).toString () == "1024");
    assert (powOk (bi ("-2"), 3).toString () == "-8");
    assert (powOk (bi ("-2"), 4).toString () == "16");
}

void testLargeValues () {
    BigInteger a = bi ("123456789012345678901234567890");
    BigInteger b = bi ("987654321098765432109876543210");
    assert (a.add (b).toString () == "1111111110111111111011111111100");

    BigInteger c = bi ("12345678901234567890");
    assert (c.multiply (bi ("9")).toString () == "111111110111111111010");
    assert (divideOk (b, bi ("10")).toString () == "98765432109876543210987654321");
}

void testInvalidArguments () {
    var emptyInput = BigInteger.of ("");
    assert (emptyInput.isError ());
    assert (emptyInput.unwrapError () is BigIntegerError.INVALID_ARGUMENT);

    var nonNumeric = BigInteger.of ("abc");
    assert (nonNumeric.isError ());
    assert (nonNumeric.unwrapError () is BigIntegerError.INVALID_ARGUMENT);

    var signOnly = BigInteger.of ("-");
    assert (signOnly.isError ());
    assert (signOnly.unwrapError () is BigIntegerError.INVALID_ARGUMENT);

    var decimal = BigInteger.of ("12.34");
    assert (decimal.isError ());
    assert (decimal.unwrapError () is BigIntegerError.INVALID_ARGUMENT);

    var div = bi ("10").divide (bi ("0"));
    assert (div.isError ());
    assert (div.unwrapError () is BigIntegerError.DIVISION_BY_ZERO);

    var mod = bi ("10").mod (bi ("0"));
    assert (mod.isError ());
    assert (mod.unwrapError () is BigIntegerError.DIVISION_BY_ZERO);

    var pow = bi ("2").pow (-1);
    assert (pow.isError ());
    assert (pow.unwrapError () is BigIntegerError.INVALID_ARGUMENT);
}
