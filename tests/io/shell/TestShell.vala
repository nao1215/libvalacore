using Vala.Io;
using Vala.Time;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/io/shell/testExec", testExec);
    Test.add_func ("/io/shell/testExecFailure", testExecFailure);
    Test.add_func ("/io/shell/testExecQuiet", testExecQuiet);
    Test.add_func ("/io/shell/testExecSpawnFailure", testExecSpawnFailure);
    Test.add_func ("/io/shell/testExecWithTimeout", testExecWithTimeout);
    Test.add_func ("/io/shell/testExecWithTimeoutZero", testExecWithTimeoutZero);
    Test.add_func ("/io/shell/testPipe", testPipe);
    Test.add_func ("/io/shell/testPipeEmpty", testPipeEmpty);
    Test.add_func ("/io/shell/testWhich", testWhich);
    Test.add_func ("/io/shell/testWhichMissing", testWhichMissing);
    Test.add_func ("/io/shell/testWhichEmpty", testWhichEmpty);
    Test.add_func ("/io/shell/testWhichDirectPath", testWhichDirectPath);
    Test.add_func ("/io/shell/testLines", testLines);
    Test.add_func ("/io/shell/testErrorLines", testErrorLines);
    Test.add_func ("/io/shell/testExecWithTimeoutInvalid", testExecWithTimeoutInvalid);
    Test.run ();
}

ShellResult mustExecWithTimeout (string command, Duration timeout) {
    var result = Vala.Io.Shell.execWithTimeout (command, timeout);
    assert (result.isOk ());
    return result.unwrap ();
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

void testExecSpawnFailure () {
    ShellResult result = Vala.Io.Shell.exec ("");

    assert (result.isSuccess () == false);
    assert (result.exitCode () == 127);
    assert (result.stderr () == "command must not be empty");
}

void testExecWithTimeout () {
    ShellResult result = mustExecWithTimeout ("sleep 2", Duration.ofSeconds (1));

    assert (result.isSuccess () == false);
    assert (result.durationMillis () >= 900);
    assert (result.durationMillis () < 5000);
}

void testExecWithTimeoutZero () {
    ShellResult result = mustExecWithTimeout ("echo now", Duration.ofSeconds (0));

    assert (result.isSuccess () == true);
    assert (result.stdout ().strip () == "now");
}

void testPipe () {
    string[] commands = { "printf 'a\\nb\\n'", "wc -l" };
    ShellResult result = Vala.Io.Shell.pipe (commands);

    assert (result.isSuccess () == true);
    assert (result.stdout ().strip () == "2");
}

void testPipeEmpty () {
    string[] commands = {};
    ShellResult result = Vala.Io.Shell.pipe (commands);

    assert (result.isSuccess () == false);
    assert (result.exitCode () == 127);
    assert (result.stderr () == "no commands");
}

void testWhich () {
    Vala.Io.Path ? path = Vala.Io.Shell.which ("sh");
    assert (path != null);
    assert (path.toString ().length > 0);
}

void testWhichMissing () {
    Vala.Io.Path ? path = Vala.Io.Shell.which ("__definitely_no_such_command__");
    assert (path == null);
}

void testWhichEmpty () {
    Vala.Io.Path ? path = Vala.Io.Shell.which ("");
    assert (path == null);
}

void testWhichDirectPath () {
    Vala.Io.Path ? tmp = Vala.Io.Files.tempFile ("shell-which-", ".sh");
    assert (tmp != null);
    if (tmp == null) {
        return;
    }

    bool written = Vala.Io.Files.writeText (tmp, "#!/bin/sh\necho x\n");
    assert (written);
    bool chmodOk = Vala.Io.Files.chmod (tmp, 0755);
    assert (chmodOk);

    Vala.Io.Path ? resolved = Vala.Io.Shell.which (tmp.toString ());
    assert (resolved != null);
    assert (resolved.toString () == tmp.toString ());

    bool removed = Vala.Io.Files.remove (tmp);
    assert (removed);
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

void testErrorLines () {
    ShellResult result = Vala.Io.Shell.exec ("printf 'e1\\ne2\\n' 1>&2");
    var errLines = result.stderrLines ();
    assert (errLines.length () == 2);
    assert (errLines.nth_data (0) == "e1");
    assert (errLines.nth_data (1) == "e2");
}

void testExecWithTimeoutInvalid () {
    var result = Vala.Io.Shell.execWithTimeout ("echo hello", Duration.ofSeconds (-1));
    assert (result.isError ());
    assert (result.unwrapError () is Vala.Io.ShellError.INVALID_ARGUMENT);
}
