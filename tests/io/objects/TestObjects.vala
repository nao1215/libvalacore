using Vala.Lang;
using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testIsNullTrue", testIsNullTrue);
    Test.add_func ("/testIsNullFalse", testIsNullFalse);
    Test.add_func ("/testNonNullTrue", testNonNullTrue);
    Test.add_func ("/testNonNullFalse", testNonNullFalse);
    Test.add_func ("/testIsNullWithObject", testIsNullWithObject);
    Test.add_func ("/testNonNullWithObject", testNonNullWithObject);
    Test.add_func ("/testIsNullWithInt", testIsNullWithInt);
    Test.add_func ("/testObjectInstantiation", testObjectInstantiation);
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

void testIsNullWithObject () {
    Vala.Io.Path ? p = null;
    assert (Objects.isNull (p) == true);
    p = new Vala.Io.Path ("/tmp");
    assert (Objects.isNull (p) == false);
}

void testNonNullWithObject () {
    Vala.Io.Path ? p = null;
    assert (Objects.nonNull (p) == false);
    p = new Vala.Io.Path ("/tmp");
    assert (Objects.nonNull (p) == true);
}

void testIsNullWithInt () {
    int ? val = null;
    assert (Objects.isNull (val) == true);
    val = 42;
    assert (Objects.isNull (val) == false);
    assert (Objects.nonNull (val) == true);
}

void testObjectInstantiation () {
    /* Exercises GObject boilerplate (construct, class_init, get_type) */
    var obj = new Objects ();
    assert (obj != null);
}
