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
    try {
        return new BigInteger (value);
    } catch (BigIntegerError e) {
        assert_not_reached ();
    }
}

BigInteger divideOk (BigInteger left, BigInteger right) {
    try {
        return left.divide (right);
    } catch (BigIntegerError e) {
        assert_not_reached ();
    }
}

BigInteger modOk (BigInteger left, BigInteger right) {
    try {
        return left.mod (right);
    } catch (BigIntegerError e) {
        assert_not_reached ();
    }
}

BigInteger powOk (BigInteger value, int exponent) {
    try {
        return value.pow (exponent);
    } catch (BigIntegerError e) {
        assert_not_reached ();
    }
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
    bool textThrown = false;
    try {
        new BigInteger ("");
    } catch (BigIntegerError e) {
        textThrown = true;
        assert (e is BigIntegerError.INVALID_ARGUMENT);
    }
    assert (textThrown);

    bool divThrown = false;
    try {
        bi ("10").divide (bi ("0"));
    } catch (BigIntegerError e) {
        divThrown = true;
        assert (e is BigIntegerError.DIVISION_BY_ZERO);
    }
    assert (divThrown);

    bool modThrown = false;
    try {
        bi ("10").mod (bi ("0"));
    } catch (BigIntegerError e) {
        modThrown = true;
        assert (e is BigIntegerError.DIVISION_BY_ZERO);
    }
    assert (modThrown);

    bool powThrown = false;
    try {
        bi ("2").pow (-1);
    } catch (BigIntegerError e) {
        powThrown = true;
        assert (e is BigIntegerError.INVALID_ARGUMENT);
    }
    assert (powThrown);
}
