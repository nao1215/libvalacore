using Vala.Lang;

errordomain TestError {
    SAMPLE
}

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/lang/exceptions/testConstruct", testConstruct);
    Test.add_func ("/lang/exceptions/testGetStackTrace", testGetStackTrace);
    Test.add_func ("/lang/exceptions/testSneakyThrow", testSneakyThrow);
    Test.run ();
}

void testConstruct () {
    Exceptions exceptions = new Exceptions ();
    assert (exceptions != null);
}

void testGetStackTrace () {
    GLib.Error e = new TestError.SAMPLE ("boom");
    string trace = Exceptions.getStackTrace (e);
    assert (trace.contains ("boom"));
    assert (trace.contains ("code"));
    assert (trace.contains ("domain"));
}

void testSneakyThrow () {
    GLib.Error source = new TestError.SAMPLE ("boom");
    var failed = Exceptions.sneakyThrow (source);
    assert (failed.isError ());
    assert (failed.unwrapError () is TestError.SAMPLE);
    assert (failed.unwrapError ().message == "boom");
}
