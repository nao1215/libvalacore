using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/io/process/testExecSuccess", testExecSuccess);
    Test.add_func ("/io/process/testExecFailure", testExecFailure);
    Test.add_func ("/io/process/testExecInvalidCommand", testExecInvalidCommand);
    Test.add_func ("/io/process/testExecCommandNotFound", testExecCommandNotFound);
    Test.add_func ("/io/process/testExecWithOutputSuccess", testExecWithOutputSuccess);
    Test.add_func ("/io/process/testExecWithOutputFailure", testExecWithOutputFailure);
    Test.add_func ("/io/process/testExecWithOutputInvalidCommand", testExecWithOutputInvalidCommand);
    Test.add_func ("/io/process/testExecWithOutputCommandNotFound", testExecWithOutputCommandNotFound);
    Test.add_func ("/io/process/testExecWithOutputEmpty", testExecWithOutputEmpty);
    Test.add_func ("/io/process/testKillInvalidPid", testKillInvalidPid);
    Test.add_func ("/io/process/testKillMissingPid", testKillMissingPid);
    Test.add_func ("/io/process/testKillSuccess", testKillSuccess);
    Test.run ();
}

void testExecSuccess () {
    var result = Vala.Io.Process.exec ("sh", { "-c", "exit 0" });
    assert (result.isOk ());
    assert (result.unwrap () == true);
}

void testExecFailure () {
    var result = Vala.Io.Process.exec ("sh", { "-c", "exit 7" });
    assert (result.isError ());
    assert (result.unwrapError () is ProcessError.EXIT_NON_ZERO);
}

void testExecInvalidCommand () {
    var result = Vala.Io.Process.exec ("", {});
    assert (result.isError ());
    assert (result.unwrapError () is ProcessError.INVALID_ARGUMENT);
}

void testExecCommandNotFound () {
    var result = Vala.Io.Process.exec ("__no_such_command__", {});
    assert (result.isError ());
    assert (result.unwrapError () is ProcessError.SPAWN_FAILED);
}

void testExecWithOutputSuccess () {
    var result = Vala.Io.Process.execWithOutput ("sh", { "-c", "printf 'hello'" });
    assert (result.isOk ());
    assert (result.unwrap () == "hello");
}

void testExecWithOutputFailure () {
    var result = Vala.Io.Process.execWithOutput ("sh", { "-c", "echo err 1>&2; exit 2" });
    assert (result.isError ());
    assert (result.unwrapError () is ProcessError.EXIT_NON_ZERO);
}

void testExecWithOutputInvalidCommand () {
    var result = Vala.Io.Process.execWithOutput ("", {});
    assert (result.isError ());
    assert (result.unwrapError () is ProcessError.INVALID_ARGUMENT);
}

void testExecWithOutputCommandNotFound () {
    var result = Vala.Io.Process.execWithOutput ("__no_such_command__", {});
    assert (result.isError ());
    assert (result.unwrapError () is ProcessError.SPAWN_FAILED);
}

void testExecWithOutputEmpty () {
    var result = Vala.Io.Process.execWithOutput ("sh", { "-c", ":" });
    assert (result.isOk ());
    assert (result.unwrap () == "");
}

void testKillInvalidPid () {
    assert (Vala.Io.Process.kill (0) == false);
    assert (Vala.Io.Process.kill (-1) == false);
}

void testKillMissingPid () {
    assert (Vala.Io.Process.kill (999999) == false);
}

void testKillSuccess () {
    string[] argv = { "sh", "-c", "sleep 5", null };
    GLib.Subprocess subprocess;
    try {
        subprocess = new GLib.Subprocess.newv (argv, GLib.SubprocessFlags.NONE);
    } catch (GLib.Error e) {
        assert_not_reached ();
    }
    string ? identifier = subprocess.get_identifier ();
    assert (identifier != null);

    int pid = int.parse (identifier);
    int64 start = GLib.get_monotonic_time ();

    assert (Vala.Io.Process.kill (pid) == true);

    try {
        assert (subprocess.wait (null) == true);
    } catch (GLib.Error e) {
        assert_not_reached ();
    }

    int64 elapsedMillis = (GLib.get_monotonic_time () - start) / 1000;
    assert (elapsedMillis < 4000);
}
