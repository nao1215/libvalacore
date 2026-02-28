using Vala.Lang;

errordomain TestError {
    SAMPLE
}

string ? test_program_path = null;

void main (string[] args) {
    if (args.length == 2 && args[1] == "--exceptions-child-sneaky") {
        runSneakyThrowChild ();
        return;
    }

    test_program_path = args[0];
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
    assert (test_program_path != null);

    string[] argv = { test_program_path, "--exceptions-child-sneaky", null };
    int waitStatus = 0;
    string stdoutText;
    string stderrText;
    bool spawned = false;

    try {
        spawned = GLib.Process.spawn_sync (null, argv, null, SpawnFlags.SEARCH_PATH, null,
                                           out stdoutText, out stderrText, out waitStatus);
    } catch (SpawnError e) {
        spawned = false;
    }
    assert (spawned == true);

    bool exitedSuccessfully = true;
    try {
        GLib.Process.check_wait_status (waitStatus);
    } catch (GLib.Error e) {
        exitedSuccessfully = false;
    }

    assert (exitedSuccessfully == false);
    assert (stderrText.contains ("boom"));
}

void runSneakyThrowChild () {
    GLib.Error e = new TestError.SAMPLE ("boom");
    Exceptions.sneakyThrow (e);
}
