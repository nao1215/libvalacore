using Vala.Io;
using Vala.Time;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/io/shell/testExec", testExec);
    Test.add_func ("/io/shell/testExecFailure", testExecFailure);
    Test.add_func ("/io/shell/testExecQuiet", testExecQuiet);
    Test.add_func ("/io/shell/testExecWithTimeout", testExecWithTimeout);
    Test.add_func ("/io/shell/testPipe", testPipe);
    Test.add_func ("/io/shell/testWhich", testWhich);
    Test.add_func ("/io/shell/testLines", testLines);
    Test.run ();
}

void testExec () {
    ShellResult result = Vala.Io.Shell.exec ("echo hello");

    assert (result.isSuccess () == true);
    assert (result.exitCode () == 0);
    assert (result.stdout ().strip () == "hello");
}

void testExecFailure () {
    ShellResult result = Vala.Io.Shell.exec ("exit 7");

    assert (result.isSuccess () == false);
    assert (result.exitCode () == 7);
}

void testExecQuiet () {
    ShellResult result = Vala.Io.Shell.execQuiet ("echo out && echo err 1>&2");

    assert (result.isSuccess () == true);
    assert (result.stdout () == "");
    assert (result.stderr () == "");
}

void testExecWithTimeout () {
    ShellResult result = Vala.Io.Shell.execWithTimeout ("sleep 2", Duration.ofSeconds (1));

    assert (result.isSuccess () == false);
    assert (result.durationMillis () >= 900);
    assert (result.durationMillis () < 2500);
}

void testPipe () {
    string[] commands = { "printf 'a\\nb\\n'", "wc -l" };
    ShellResult result = Vala.Io.Shell.pipe (commands);

    assert (result.isSuccess () == true);
    assert (result.stdout ().strip () == "2");
}

void testWhich () {
    Vala.Io.Path ? path = Vala.Io.Shell.which ("sh");
    assert (path != null);
    assert (path.toString ().length > 0);
}

void testLines () {
    ShellResult result = Vala.Io.Shell.exec ("printf 'x\\ny\\n'");

    var outLines = result.stdoutLines ();
    assert (outLines.length () == 2);
    assert (outLines.nth_data (0) == "x");
    assert (outLines.nth_data (1) == "y");

    var errLines = result.stderrLines ();
    assert (errLines.length () == 0);
}
