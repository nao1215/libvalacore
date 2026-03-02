using Vala.Math;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/math/testConstants", testConstants);
    Test.add_func ("/math/testAbsMaxMinClamp", testAbsMaxMinClamp);
    Test.add_func ("/math/testRoundFunctions", testRoundFunctions);
    Test.add_func ("/math/testPowSqrtLog", testPowSqrtLog);
    Test.add_func ("/math/testTrig", testTrig);
    Test.add_func ("/math/testGcdLcm", testGcdLcm);
    Test.add_func ("/math/testIsPrime", testIsPrime);
    Test.add_func ("/math/testFactorial", testFactorial);
    Test.add_func ("/math/testInvalidArguments", testInvalidArguments);
    Test.run ();
}

void assertClose (double actual, double expected, double eps = 1e-9) {
    assert (Vala.Math.Math.abs (actual - expected) <= eps);
}

void testConstants () {
    assertClose (Vala.Math.Math.PI, 3.14159265358979323846);
    assertClose (Vala.Math.Math.E, 2.71828182845904523536);
}

void testAbsMaxMinClamp () {
    assertClose (Vala.Math.Math.abs (-3.5), 3.5);
    assertClose (Vala.Math.Math.max (2.0, 5.0), 5.0);
    assertClose (Vala.Math.Math.min (2.0, 5.0), 2.0);
    var clampUpper = Vala.Math.Math.clamp (5.0, 0.0, 3.0);
    assert (clampUpper.isOk ());
    assertClose (clampUpper.unwrap (), 3.0);

    var clampLower = Vala.Math.Math.clamp (-2.0, 0.0, 3.0);
    assert (clampLower.isOk ());
    assertClose (clampLower.unwrap (), 0.0);

    var clampMiddle = Vala.Math.Math.clamp (2.0, 0.0, 3.0);
    assert (clampMiddle.isOk ());
    assertClose (clampMiddle.unwrap (), 2.0);
}

void testRoundFunctions () {
    assertClose (Vala.Math.Math.floor (1.9), 1.0);
    assertClose (Vala.Math.Math.ceil (1.1), 2.0);
    assertClose (Vala.Math.Math.round (1.49), 1.0);
    assertClose (Vala.Math.Math.round (1.5), 2.0);
}

void testPowSqrtLog () {
    assertClose (Vala.Math.Math.pow (2.0, 8.0), 256.0);
    assertClose (Vala.Math.Math.sqrt (81.0), 9.0);
    assertClose (Vala.Math.Math.log (Vala.Math.Math.E), 1.0);
    assertClose (Vala.Math.Math.log10 (1000.0), 3.0);
}

void testTrig () {
    assertClose (Vala.Math.Math.sin (Vala.Math.Math.PI / 2.0), 1.0);
    assertClose (Vala.Math.Math.cos (0.0), 1.0);
    assertClose (Vala.Math.Math.tan (0.0), 0.0);
}

void testGcdLcm () {
    assert (Vala.Math.Math.gcd (54, 24) == 6);
    assert (Vala.Math.Math.gcd (-54, 24) == 6);
    assert (Vala.Math.Math.lcm (12, 18) == 36);
    assert (Vala.Math.Math.lcm (0, 18) == 0);
}

void testIsPrime () {
    assert (Vala.Math.Math.isPrime (2) == true);
    assert (Vala.Math.Math.isPrime (3) == true);
    assert (Vala.Math.Math.isPrime (17) == true);
    assert (Vala.Math.Math.isPrime (1) == false);
    assert (Vala.Math.Math.isPrime (15) == false);
}

void testFactorial () {
    var fact0 = Vala.Math.Math.factorial (0);
    assert (fact0.isOk ());
    assert (fact0.unwrap () == 1);

    var fact1 = Vala.Math.Math.factorial (1);
    assert (fact1.isOk ());
    assert (fact1.unwrap () == 1);

    var fact5 = Vala.Math.Math.factorial (5);
    assert (fact5.isOk ());
    assert (fact5.unwrap () == 120);

    var fact10 = Vala.Math.Math.factorial (10);
    assert (fact10.isOk ());
    assert (fact10.unwrap () == 3628800);

    var fact20 = Vala.Math.Math.factorial (20);
    assert (fact20.isOk ());
    assert (fact20.unwrap () == 2432902008176640000);
}

void testInvalidArguments () {
    var clampInvalid = Vala.Math.Math.clamp (1.0, 2.0, 1.0);
    assert (clampInvalid.isError ());
    assert (clampInvalid.unwrapError () is MathError.INVALID_ARGUMENT);
    assert (clampInvalid.unwrapError ().message == "lo must be less than or equal to hi");

    var factorialNegative = Vala.Math.Math.factorial (-1);
    assert (factorialNegative.isError ());
    assert (factorialNegative.unwrapError () is MathError.INVALID_ARGUMENT);
    assert (factorialNegative.unwrapError ().message == "n must be non-negative");

    var factorialOverflow = Vala.Math.Math.factorial (21);
    assert (factorialOverflow.isError ());
    assert (factorialOverflow.unwrapError () is MathError.INVALID_ARGUMENT);
    assert (factorialOverflow.unwrapError ().message == "n must be in range [0, 20]");
}
