using Core;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testIsNullTrue", testIsNullTrue);
    Test.add_func ("/testIsNullFalse", testIsNullFalse);
    Test.add_func ("/testNonNullTrue", testNonNullTrue);
    Test.add_func ("/testNonNullFalse", testNonNullFalse);
    Test.run ();
}

void testIsNullTrue () {
    string test = null;
    assert (Core.Objects.isNull (test) == true);
}

void testIsNullFalse () {
    string test = "test";
    assert (Core.Objects.isNull (test) == false);
}

void testNonNullTrue () {
    string test = "test";
    assert (Core.Objects.nonNull (test) == true);
}

void testNonNullFalse () {
    string test = null;
    assert (Core.Objects.nonNull (test) == false);
}
