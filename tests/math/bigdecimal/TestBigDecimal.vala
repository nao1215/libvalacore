using Vala.Math;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/math/bigdecimal/testNormalize", testNormalize);
    Test.add_func ("/math/bigdecimal/testParse", testParse);
    Test.add_func ("/math/bigdecimal/testAddSubtract", testAddSubtract);
    Test.add_func ("/math/bigdecimal/testMultiply", testMultiply);
    Test.add_func ("/math/bigdecimal/testDivide", testDivide);
    Test.add_func ("/math/bigdecimal/testMod", testMod);
    Test.add_func ("/math/bigdecimal/testPow", testPow);
    Test.add_func ("/math/bigdecimal/testCompareAbsNegate", testCompareAbsNegate);
    Test.add_func ("/math/bigdecimal/testLargeValues", testLargeValues);
    Test.add_func ("/math/bigdecimal/testInvalidArguments", testInvalidArguments);
    Test.run ();
}

BigDecimal bd (string value) {
    try {
        return new BigDecimal (value);
    } catch (BigDecimalError e) {
        assert_not_reached ();
    }
}

BigDecimal multiplyOk (BigDecimal left, BigDecimal right) {
    try {
        return left.multiply (right);
    } catch (BigDecimalError e) {
        assert_not_reached ();
    }
}

BigDecimal divideOk (BigDecimal left, BigDecimal right) {
    try {
        return left.divide (right);
    } catch (BigDecimalError e) {
        assert_not_reached ();
    }
}

BigDecimal divideScaleOk (BigDecimal left, BigDecimal right, int scale) {
    try {
        return left.divideWithScale (right, scale);
    } catch (BigDecimalError e) {
        assert_not_reached ();
    }
}

BigDecimal modOk (BigDecimal left, BigDecimal right) {
    try {
        return left.mod (right);
    } catch (BigDecimalError e) {
        assert_not_reached ();
    }
}

BigDecimal powOk (BigDecimal value, int exponent) {
    try {
        return value.pow (exponent);
    } catch (BigDecimalError e) {
        assert_not_reached ();
    }
}

void testNormalize () {
    BigDecimal a = bd ("001.2300");
    assert (a.toString () == "1.23");
    assert (a.scale () == 2);

    BigDecimal b = bd ("-0.000");
    assert (b.toString () == "0");
    assert (b.scale () == 0);

    assert (bd (".5").toString () == "0.5");
    assert (bd ("10.").toString () == "10");
}

void testParse () {
    BigDecimal ? ok = BigDecimal.parse ("-12.3400");
    assert (ok != null);
    assert (ok.toString () == "-12.34");

    assert (BigDecimal.parse ("") == null);
    assert (BigDecimal.parse ("abc") == null);
    assert (BigDecimal.parse ("1.2.3") == null);
    assert (BigDecimal.parse ("-") == null);
}

void testAddSubtract () {
    assert (bd ("1.2").add (bd ("0.03")).toString () == "1.23");
    assert (bd ("-1.5").add (bd ("0.2")).toString () == "-1.3");
    assert (bd ("5.0").subtract (bd ("2.25")).toString () == "2.75");
}

void testMultiply () {
    assert (multiplyOk (bd ("1.5"), bd ("2")).toString () == "3");
    assert (multiplyOk (bd ("-1.25"), bd ("2")).toString () == "-2.5");
}

void testDivide () {
    assert (divideOk (bd ("10"), bd ("4")).toString () == "2.5");
    assert (divideOk (bd ("1"), bd ("8")).toString () == "0.125");
    assert (divideOk (bd ("-1"), bd ("2")).toString () == "-0.5");

    assert (divideScaleOk (bd ("1"), bd ("3"), 4).toString () == "0.3333");
    assert (divideScaleOk (bd ("-1"), bd ("3"), 2).toString () == "-0.33");
}

void testMod () {
    assert (modOk (bd ("5.5"), bd ("2")).toString () == "1.5");
    assert (modOk (bd ("-5.5"), bd ("2")).toString () == "-1.5");
    assert (modOk (bd ("2"), bd ("5.5")).toString () == "2");
}

void testPow () {
    assert (powOk (bd ("1.2"), 3).toString () == "1.728");
    assert (powOk (bd ("-1.5"), 2).toString () == "2.25");
    assert (powOk (bd ("2"), 0).toString () == "1");
}

void testCompareAbsNegate () {
    BigDecimal a = bd ("-1.20");
    BigDecimal b = bd ("-1.2");
    assert (a.compareTo (b) == 0);

    assert (a.abs ().toString () == "1.2");
    assert (a.negate ().toString () == "1.2");
    assert (bd ("0").negate ().toString () == "0");
}

void testLargeValues () {
    BigDecimal a = bd ("12345678901234567890.123");
    BigDecimal b = bd ("0.877");

    assert (a.add (b).toString () == "12345678901234567891");
    assert (multiplyOk (a, bd ("10")).toString () == "123456789012345678901.23");
}

void testInvalidArguments () {
    bool textThrown = false;
    try {
        new BigDecimal ("abc");
    } catch (BigDecimalError e) {
        textThrown = true;
        assert (e is BigDecimalError.INVALID_ARGUMENT);
    }
    assert (textThrown);

    bool divThrown = false;
    try {
        bd ("1").divide (bd ("0"));
    } catch (BigDecimalError e) {
        divThrown = true;
        assert (e is BigDecimalError.DIVISION_BY_ZERO);
    }
    assert (divThrown);

    bool scaleThrown = false;
    try {
        bd ("1").divideWithScale (bd ("3"), -1);
    } catch (BigDecimalError e) {
        scaleThrown = true;
        assert (e is BigDecimalError.INVALID_ARGUMENT);
    }
    assert (scaleThrown);

    bool modThrown = false;
    try {
        bd ("1").mod (bd ("0"));
    } catch (BigDecimalError e) {
        modThrown = true;
        assert (e is BigDecimalError.DIVISION_BY_ZERO);
    }
    assert (modThrown);

    bool powThrown = false;
    try {
        bd ("2").pow (-1);
    } catch (BigDecimalError e) {
        powThrown = true;
        assert (e is BigDecimalError.INVALID_ARGUMENT);
    }
    assert (powThrown);
}
