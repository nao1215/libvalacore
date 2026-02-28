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
    Test.run ();
}

void testNormalize () {
    assert (new BigInteger ("000123").toString () == "123");
    assert (new BigInteger ("-00000123").toString () == "-123");
    assert (new BigInteger ("+0000").toString () == "0");
}

void testAdd () {
    assert (new BigInteger ("123").add (new BigInteger ("456")).toString () == "579");
    assert (new BigInteger ("-10").add (new BigInteger ("3")).toString () == "-7");
    assert (new BigInteger ("-10").add (new BigInteger ("-3")).toString () == "-13");
    assert (new BigInteger ("10").add (new BigInteger ("-10")).toString () == "0");
}

void testSubtract () {
    assert (new BigInteger ("10").subtract (new BigInteger ("3")).toString () == "7");
    assert (new BigInteger ("3").subtract (new BigInteger ("10")).toString () == "-7");
    assert (new BigInteger ("-3").subtract (new BigInteger ("10")).toString () == "-13");
    assert (new BigInteger ("-3").subtract (new BigInteger ("-10")).toString () == "7");
}

void testMultiply () {
    assert (new BigInteger ("12").multiply (new BigInteger ("7")).toString () == "84");
    assert (new BigInteger ("-12").multiply (new BigInteger ("7")).toString () == "-84");
    assert (new BigInteger ("-12").multiply (new BigInteger ("-7")).toString () == "84");
    assert (new BigInteger ("0").multiply (new BigInteger ("999999")).toString () == "0");
}

void testDivideAndMod () {
    assert (new BigInteger ("10").divide (new BigInteger ("3")).toString () == "3");
    assert (new BigInteger ("10").mod (new BigInteger ("3")).toString () == "1");

    assert (new BigInteger ("-10").divide (new BigInteger ("3")).toString () == "-3");
    assert (new BigInteger ("-10").mod (new BigInteger ("3")).toString () == "-1");

    assert (new BigInteger ("10").divide (new BigInteger ("-3")).toString () == "-3");
    assert (new BigInteger ("10").mod (new BigInteger ("-3")).toString () == "1");

    assert (new BigInteger ("2").divide (new BigInteger ("5")).toString () == "0");
    assert (new BigInteger ("2").mod (new BigInteger ("5")).toString () == "2");
}

void testPow () {
    assert (new BigInteger ("2").pow (0).toString () == "1");
    assert (new BigInteger ("2").pow (10).toString () == "1024");
    assert (new BigInteger ("-2").pow (3).toString () == "-8");
    assert (new BigInteger ("-2").pow (4).toString () == "16");
}

void testLargeValues () {
    BigInteger a = new BigInteger ("123456789012345678901234567890");
    BigInteger b = new BigInteger ("987654321098765432109876543210");
    assert (a.add (b).toString () == "1111111110111111111011111111100");

    BigInteger c = new BigInteger ("12345678901234567890");
    assert (c.multiply (new BigInteger ("9")).toString () == "111111110111111111010");
    assert (b.divide (new BigInteger ("10")).toString () == "98765432109876543210987654321");
}
