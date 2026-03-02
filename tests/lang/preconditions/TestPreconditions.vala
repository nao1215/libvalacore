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
    var result = Preconditions.checkArgument (true, "must not fail");
    assert (result.isOk ());
    assert (result.unwrap () == true);
}

void testCheckArgumentFailure () {
    var result = Preconditions.checkArgument (false, "bad argument");
    assert (result.isError ());
    assert (result.unwrapError () is PreconditionError.INVALID_ARGUMENT);
    assert (result.unwrapError ().message == "bad argument");
}

void testCheckState () {
    var result = Preconditions.checkState (true, "must not fail");
    assert (result.isOk ());
    assert (result.unwrap () == true);
}

void testCheckStateFailure () {
    var result = Preconditions.checkState (false, "");
    assert (result.isError ());
    assert (result.unwrapError () is PreconditionError.INVALID_STATE);
    assert (result.unwrapError ().message == "Invalid state");
}
