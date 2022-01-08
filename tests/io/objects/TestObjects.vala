using Vala.Lang;

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
    assert (Objects.isNull (test) == true);
}

void testIsNullFalse () {
    string test = "test";
    assert (Objects.isNull (test) == false);
}

void testNonNullTrue () {
    string test = "test";
    assert (Objects.nonNull (test) == true);
}

void testNonNullFalse () {
    string test = null;
    assert (Objects.nonNull (test) == false);
}
