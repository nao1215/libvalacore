using Vala.Lang;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/lang/process/testExec", testExec);
    Test.add_func ("/lang/process/testExecStderr", testExecStderr);
    Test.add_func ("/lang/process/testExecFailure", testExecFailure);
    Test.add_func ("/lang/process/testExecAsync", testExecAsync);
    Test.add_func ("/lang/process/testExecAsyncInvalid", testExecAsyncInvalid);
    Test.add_func ("/lang/process/testExecAsyncShellFallback", testExecAsyncShellFallback);
    Test.add_func ("/lang/process/testExecAsyncSpawnError", testExecAsyncSpawnError);
    Test.add_func ("/lang/process/testKill", testKill);
    Test.run ();
}

Vala.Lang.Process mustProcess (Vala.Collections.Result<Vala.Lang.Process, GLib.Error> result) {
    assert (result.isOk ());
    return result.unwrap ();
}

void assertWaitOk (Vala.Lang.Process proc) {
    var waited = proc.waitFor ();
    assert (waited.isOk ());
    assert (waited.unwrap () == true);
}

void testExec () {
    Vala.Lang.Process proc = mustProcess (Vala.Lang.Process.exec ("printf 'hello'"));
    assert (proc.exitCode () == 0);
    assert (proc.stdout () == "hello");
    assert (proc.stderr () == "");
}

void testExecStderr () {
    Vala.Lang.Process proc = mustProcess (Vala.Lang.Process.exec ("echo 'err' 1>&2"));
    assert (proc.exitCode () == 0);
    assert (proc.stderr ().strip () == "err");
}

void testExecFailure () {
    Vala.Lang.Process proc = mustProcess (Vala.Lang.Process.exec ("exit 42"));
    assert (proc.exitCode () == 42);
}

void testExecAsync () {
    Vala.Lang.Process proc = mustProcess (Vala.Lang.Process.execAsync ("printf 'ok'"));
    assertWaitOk (proc);
    assertWaitOk (proc);
    assert (proc.exitCode () == 0);
    assert (proc.stdout () == "ok");
}

void testExecAsyncInvalid () {
    var result = Vala.Lang.Process.execAsync ("");
    assert (result.isError ());
    assert (result.unwrapError () is LangProcessError.INVALID_ARGUMENT);
}

void testExecAsyncShellFallback () {
    string ? oldShell = Environment.get_variable ("SHELL");
    Environment.set_variable ("SHELL", "", true);

    try {
        Vala.Lang.Process proc = mustProcess (Vala.Lang.Process.exec ("printf 'fallback'"));
        assert (proc.exitCode () == 0);
        assert (proc.stdout () == "fallback");
    } finally {
        if (oldShell == null) {
            Environment.unset_variable ("SHELL");
        } else {
            Environment.set_variable ("SHELL", oldShell, true);
        }
    }
}

void testExecAsyncSpawnError () {
    string ? oldShell = Environment.get_variable ("SHELL");
    Environment.set_variable ("SHELL", "/definitely/missing/sh", true);

    try {
        var result = Vala.Lang.Process.execAsync ("echo test");
        assert (result.isError ());
        assert (result.unwrapError () is LangProcessError.SPAWN_FAILED);
    } finally {
        if (oldShell == null) {
            Environment.unset_variable ("SHELL");
        } else {
            Environment.set_variable ("SHELL", oldShell, true);
        }
    }
}

void testKill () {
    int64 start = GLib.get_monotonic_time ();
    Vala.Lang.Process proc = mustProcess (Vala.Lang.Process.execAsync ("sleep 2"));
    var killed = proc.kill ();
    assert (killed.isOk ());
    assert (killed.unwrap () == true);
    assertWaitOk (proc);
    int64 elapsedMillis = (GLib.get_monotonic_time () - start) / 1000;
    assert (elapsedMillis < 1900);
    assert (proc.exitCode () != 0);
}
