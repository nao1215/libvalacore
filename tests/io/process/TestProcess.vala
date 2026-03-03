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
    GLib.Error err = result.unwrapError ();
    assert (err is ProcessError.EXIT_NON_ZERO);
    assert (err.message.contains ("sh"));
}

void testExecInvalidCommand () {
    var result = Vala.Io.Process.exec ("", {});
    assert (result.isError ());
    GLib.Error err = result.unwrapError ();
    assert (err is ProcessError.INVALID_ARGUMENT);
    assert (err.message == "command must not be empty");
}

void testExecCommandNotFound () {
    var result = Vala.Io.Process.exec ("__no_such_command__", {});
    assert (result.isError ());
    GLib.Error err = result.unwrapError ();
    assert (err is ProcessError.SPAWN_FAILED);
    assert (err.message.contains ("__no_such_command__"));
}

void testExecWithOutputSuccess () {
    var result = Vala.Io.Process.execWithOutput ("sh", { "-c", "printf 'hello'" });
    assert (result.isOk ());
    assert (result.unwrap () == "hello");
}

void testExecWithOutputFailure () {
    var result = Vala.Io.Process.execWithOutput ("sh", { "-c", "echo err 1>&2; exit 2" });
    assert (result.isError ());
    GLib.Error err = result.unwrapError ();
    assert (err is ProcessError.EXIT_NON_ZERO);
    assert (err.message.contains ("stderr=err"));
}

void testExecWithOutputInvalidCommand () {
    var result = Vala.Io.Process.execWithOutput ("", {});
    assert (result.isError ());
    GLib.Error err = result.unwrapError ();
    assert (err is ProcessError.INVALID_ARGUMENT);
    assert (err.message == "command must not be empty");
}

void testExecWithOutputCommandNotFound () {
    var result = Vala.Io.Process.execWithOutput ("__no_such_command__", {});
    assert (result.isError ());
    GLib.Error err = result.unwrapError ();
    assert (err is ProcessError.SPAWN_FAILED);
    assert (err.message.contains ("__no_such_command__"));
}

void testExecWithOutputEmpty () {
    var result = Vala.Io.Process.execWithOutput ("sh", { "-c", ":" });
    assert (result.isOk ());
    assert (result.unwrap () == "");
}

void testKillInvalidPid () {
    var zero = Vala.Io.Process.kill (0);
    assert (zero.isError ());
    assert (zero.unwrapError () is ProcessError.INVALID_ARGUMENT);

    var negative = Vala.Io.Process.kill (-1);
    assert (negative.isError ());
    assert (negative.unwrapError () is ProcessError.INVALID_ARGUMENT);
}

void testKillMissingPid () {
    var missing = Vala.Io.Process.kill (999999);
    assert (missing.isError ());
    assert (missing.unwrapError () is ProcessError.NOT_FOUND);
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

    var killed = Vala.Io.Process.kill (pid);
    assert (killed.isOk ());
    assert (killed.unwrap () == true);

    try {
        assert (subprocess.wait (null) == true);
    } catch (GLib.Error e) {
        assert_not_reached ();
    }

    int64 elapsedMillis = (GLib.get_monotonic_time () - start) / 1000;
    assert (elapsedMillis < 4000);
}
