using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/io/process/testExecSuccess", testExecSuccess);
    Test.add_func ("/io/process/testExecFailure", testExecFailure);
    Test.add_func ("/io/process/testExecInvalidCommand", testExecInvalidCommand);
    Test.add_func ("/io/process/testExecWithOutputSuccess", testExecWithOutputSuccess);
    Test.add_func ("/io/process/testExecWithOutputFailure", testExecWithOutputFailure);
    Test.add_func ("/io/process/testExecWithOutputInvalidCommand", testExecWithOutputInvalidCommand);
    Test.add_func ("/io/process/testKillInvalidPid", testKillInvalidPid);
    Test.add_func ("/io/process/testKillSuccess", testKillSuccess);
    Test.run ();
}

void testExecSuccess () {
    assert (Vala.Io.Process.exec ("sh", { "-c", "exit 0" }) == true);
}

void testExecFailure () {
    assert (Vala.Io.Process.exec ("sh", { "-c", "exit 7" }) == false);
}

void testExecInvalidCommand () {
    assert (Vala.Io.Process.exec ("", {}) == false);
}

void testExecWithOutputSuccess () {
    string ? output = Vala.Io.Process.execWithOutput ("sh", { "-c", "printf 'hello'" });
    assert (output == "hello");
}

void testExecWithOutputFailure () {
    assert (Vala.Io.Process.execWithOutput ("sh", { "-c", "echo err 1>&2; exit 2" }) == null);
}

void testExecWithOutputInvalidCommand () {
    assert (Vala.Io.Process.execWithOutput ("", {}) == null);
}

void testKillInvalidPid () {
    assert (Vala.Io.Process.kill (0) == false);
    assert (Vala.Io.Process.kill (-1) == false);
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
