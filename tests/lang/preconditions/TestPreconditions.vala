using Vala.Lang;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/lang/preconditions/testConstruct", testConstruct);
    Test.add_func ("/lang/preconditions/testCheckArgument", testCheckArgument);
    Test.add_func ("/lang/preconditions/testCheckState", testCheckState);
    Test.run ();
}

void testConstruct () {
    Preconditions preconditions = new Preconditions ();
    assert (preconditions != null);
}

// NOTE: false-condition paths call error() and abort the process.
// We keep this suite on the non-aborting path only.
void testCheckArgument () {
    Preconditions.checkArgument (true, "must not fail");
}

void testCheckState () {
    Preconditions.checkState (true, "must not fail");
}
