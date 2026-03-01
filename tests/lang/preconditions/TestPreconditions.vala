using Vala.Lang;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/lang/preconditions/testConstruct", testConstruct);
    Test.add_func ("/lang/preconditions/testCheckArgument", testCheckArgument);
    Test.add_func ("/lang/preconditions/testCheckArgumentFailure", testCheckArgumentFailure);
    Test.add_func ("/lang/preconditions/testCheckState", testCheckState);
    Test.add_func ("/lang/preconditions/testCheckStateFailure", testCheckStateFailure);
    Test.run ();
}

void testConstruct () {
    Preconditions preconditions = new Preconditions ();
    assert (preconditions != null);
}

void testCheckArgument () {
    try {
        Preconditions.checkArgument (true, "must not fail");
    } catch (PreconditionError e) {
        assert_not_reached ();
    }
}

void testCheckArgumentFailure () {
    bool thrown = false;
    try {
        Preconditions.checkArgument (false, "bad argument");
    } catch (PreconditionError e) {
        thrown = true;
        assert (e is PreconditionError.INVALID_ARGUMENT);
        assert (e.message == "bad argument");
    }
    assert (thrown);
}

void testCheckState () {
    try {
        Preconditions.checkState (true, "must not fail");
    } catch (PreconditionError e) {
        assert_not_reached ();
    }
}

void testCheckStateFailure () {
    bool thrown = false;
    try {
        Preconditions.checkState (false, "");
    } catch (PreconditionError e) {
        thrown = true;
        assert (e is PreconditionError.INVALID_STATE);
        assert (e.message == "Invalid state");
    }
    assert (thrown);
}
