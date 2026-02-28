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
    Test.run ();
}

void assertClose (double actual, double expected, double eps = 1e-9) {
    assert (Vala.Math.Math.abs (actual - expected) < eps);
}

void testConstants () {
    assertClose (Vala.Math.Math.PI, 3.14159265358979323846);
    assertClose (Vala.Math.Math.E, 2.71828182845904523536);
}

void testAbsMaxMinClamp () {
    assertClose (Vala.Math.Math.abs (-3.5), 3.5);
    assertClose (Vala.Math.Math.max (2.0, 5.0), 5.0);
    assertClose (Vala.Math.Math.min (2.0, 5.0), 2.0);
    assertClose (Vala.Math.Math.clamp (5.0, 0.0, 3.0), 3.0);
    assertClose (Vala.Math.Math.clamp (-2.0, 0.0, 3.0), 0.0);
    assertClose (Vala.Math.Math.clamp (2.0, 0.0, 3.0), 2.0);
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
    assert (Vala.Math.Math.factorial (0) == 1);
    assert (Vala.Math.Math.factorial (1) == 1);
    assert (Vala.Math.Math.factorial (5) == 120);
    assert (Vala.Math.Math.factorial (10) == 3628800);
}
