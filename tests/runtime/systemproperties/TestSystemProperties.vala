using Vala.Runtime;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/runtime/systemproperties/testBasicSeparators", testBasicSeparators);
    Test.add_func ("/runtime/systemproperties/testGet", testGet);
    Test.add_func ("/runtime/systemproperties/testTime", testTime);
    Test.run ();
}

void testBasicSeparators () {
    assert (SystemProperties.lineSeparator () == "\n");
    assert (SystemProperties.fileSeparator () == "/");
    assert (SystemProperties.pathSeparator () == ":");
}

void testGet () {
    assert (SystemProperties.get ("line.separator") == "\n");
    assert (SystemProperties.get ("file.separator") == "/");
    assert (SystemProperties.get ("path.separator") == ":");

    string? home = SystemProperties.get ("user.home");
    assert (home != null);
    assert (home == Environment.get_home_dir ());

    string? cwd = SystemProperties.get ("user.dir");
    assert (cwd != null);
    assert (cwd == Environment.get_current_dir ());
}

void testTime () {
    int64 ms = SystemProperties.currentTimeMillis ();
    assert (ms > 0);

    int64 n1 = SystemProperties.nanoTime ();
    Thread.usleep (1000);
    int64 n2 = SystemProperties.nanoTime ();
    assert (n2 >= n1);
}
