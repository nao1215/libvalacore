using Vala.Lang;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/lang/process/testExec", testExec);
    Test.add_func ("/lang/process/testExecStderr", testExecStderr);
    Test.add_func ("/lang/process/testExecFailure", testExecFailure);
    Test.add_func ("/lang/process/testExecAsync", testExecAsync);
    Test.add_func ("/lang/process/testKill", testKill);
    Test.run ();
}

void testExec () {
    Vala.Lang.Process ? proc = Vala.Lang.Process.exec ("printf 'hello'");
    assert (proc != null);
    assert (proc.exitCode () == 0);
    assert (proc.stdout () == "hello");
    assert (proc.stderr () == "");
}

void testExecStderr () {
    Vala.Lang.Process ? proc = Vala.Lang.Process.exec ("echo 'err' 1>&2");
    assert (proc != null);
    assert (proc.exitCode () == 0);
    assert (proc.stderr ().strip () == "err");
}

void testExecFailure () {
    Vala.Lang.Process ? proc = Vala.Lang.Process.exec ("exit 42");
    assert (proc != null);
    assert (proc.exitCode () == 42);
}

void testExecAsync () {
    Vala.Lang.Process ? proc = Vala.Lang.Process.execAsync ("printf 'ok'");
    assert (proc != null);
    assert (proc.waitFor () == true);
    assert (proc.exitCode () == 0);
    assert (proc.stdout () == "ok");
}

void testKill () {
    int64 start = GLib.get_monotonic_time ();
    Vala.Lang.Process ? proc = Vala.Lang.Process.execAsync ("sleep 2");
    assert (proc != null);
    assert (proc.kill () == true);
    assert (proc.waitFor () == true);
    int64 elapsedMillis = (GLib.get_monotonic_time () - start) / 1000;
    assert (elapsedMillis < 1900);
    assert (proc.exitCode () != 0);
}
