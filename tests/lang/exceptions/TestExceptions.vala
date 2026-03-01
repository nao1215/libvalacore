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
    bool thrown = false;
    GLib.Error source = new TestError.SAMPLE ("boom");
    try {
        Exceptions.sneakyThrow (source);
    } catch (GLib.Error e) {
        thrown = true;
        assert (e is TestError.SAMPLE);
        assert (e.message == "boom");
    }
    assert (thrown);
}
