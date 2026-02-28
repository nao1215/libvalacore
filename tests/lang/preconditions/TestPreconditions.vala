using Vala.Lang;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/lang/preconditions/testCheckArgument", testCheckArgument);
    Test.add_func ("/lang/preconditions/testCheckState", testCheckState);
    Test.run ();
}

void testCheckArgument () {
    Preconditions.checkArgument (true, "must not fail");
    assert (true);
}

void testCheckState () {
    Preconditions.checkState (true, "must not fail");
    assert (true);
}
