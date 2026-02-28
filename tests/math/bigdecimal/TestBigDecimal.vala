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
    Test.run ();
}

void testNormalize () {
    BigDecimal a = new BigDecimal ("001.2300");
    assert (a.toString () == "1.23");
    assert (a.scale () == 2);

    BigDecimal b = new BigDecimal ("-0.000");
    assert (b.toString () == "0");
    assert (b.scale () == 0);

    assert (new BigDecimal (".5").toString () == "0.5");
    assert (new BigDecimal ("10.").toString () == "10");
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
    assert (new BigDecimal ("1.2").add (new BigDecimal ("0.03")).toString () == "1.23");
    assert (new BigDecimal ("-1.5").add (new BigDecimal ("0.2")).toString () == "-1.3");
    assert (new BigDecimal ("5.0").subtract (new BigDecimal ("2.25")).toString () == "2.75");
}

void testMultiply () {
    assert (new BigDecimal ("1.5").multiply (new BigDecimal ("2")).toString () == "3");
    assert (new BigDecimal ("-1.25").multiply (new BigDecimal ("2")).toString () == "-2.5");
}

void testDivide () {
    assert (new BigDecimal ("10").divide (new BigDecimal ("4")).toString () == "2.5");
    assert (new BigDecimal ("1").divide (new BigDecimal ("8")).toString () == "0.125");
    assert (new BigDecimal ("-1").divide (new BigDecimal ("2")).toString () == "-0.5");

    assert (new BigDecimal ("1").divideWithScale (new BigDecimal ("3"), 4).toString () == "0.3333");
    assert (new BigDecimal ("-1").divideWithScale (new BigDecimal ("3"), 2).toString () == "-0.33");
}

void testMod () {
    assert (new BigDecimal ("5.5").mod (new BigDecimal ("2")).toString () == "1.5");
    assert (new BigDecimal ("-5.5").mod (new BigDecimal ("2")).toString () == "-1.5");
    assert (new BigDecimal ("2").mod (new BigDecimal ("5.5")).toString () == "2");
}

void testPow () {
    assert (new BigDecimal ("1.2").pow (3).toString () == "1.728");
    assert (new BigDecimal ("-1.5").pow (2).toString () == "2.25");
    assert (new BigDecimal ("2").pow (0).toString () == "1");
}

void testCompareAbsNegate () {
    BigDecimal a = new BigDecimal ("-1.20");
    BigDecimal b = new BigDecimal ("-1.2");
    assert (a.compareTo (b) == 0);

    assert (a.abs ().toString () == "1.2");
    assert (a.negate ().toString () == "1.2");
    assert (new BigDecimal ("0").negate ().toString () == "0");
}

void testLargeValues () {
    BigDecimal a = new BigDecimal ("12345678901234567890.123");
    BigDecimal b = new BigDecimal ("0.877");

    assert (a.add (b).toString () == "12345678901234567891");
    assert (a.multiply (new BigDecimal ("10")).toString () == "123456789012345678901.23");
}
