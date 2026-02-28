using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testIsFile", testIsFile);
    Test.add_func ("/testIsDir", testIsDir);
    Test.add_func ("/testExists", testExists);
    Test.add_func ("/testCanRead", testCanRead);
    Test.add_func ("/testCanWrite", testCanWrite);
    Test.add_func ("/testCanExec", testCanExec);
    Test.add_func ("/testIsSymbolicFile", testIsSymbolicFile);
    Test.add_func ("/testIsHiddenFile", testIsHiddenFile);
    Test.add_func ("/testMakeDirs", testMakeDirs);
    Test.add_func ("/testMakeDir", testMakeDir);
    Test.run ();
}

void testIsFile () {
    assert (Files.isFile (new Vala.Io.Path ("/tmp/valacore/ut/file.txt")) == true);
    assert (Files.isFile (new Vala.Io.Path ("/tmp/valacore/ut")) == false);
    assert (Files.isFile (new Vala.Io.Path ("")) == false);
    assert (Files.isFile (new Vala.Io.Path ("/tmp/valacore/ut/symbolic.txt")) == true);
    assert (Files.isFile (new Vala.Io.Path ("/tmp/valacore/ut/symbolic")) == false);
    assert (Files.isFile (new Vala.Io.Path ("/tmp/valacore/ut/.hidden.txt")) == true);
    assert (Files.isFile (new Vala.Io.Path ("/tmp/valacore/ut/.hidden")) == false);
}

void testIsDir () {
    assert (Files.isDir (new Vala.Io.Path ("/tmp/valacore/ut/file.txt")) == false);
    assert (Files.isDir (new Vala.Io.Path ("/tmp/valacore/ut")) == true);
    assert (Files.isDir (new Vala.Io.Path ("")) == false);
    assert (Files.isDir (new Vala.Io.Path ("/tmp/valacore/ut/symbolic.txt")) == false);
    assert (Files.isDir (new Vala.Io.Path ("/tmp/valacore/ut/symbolic")) == true);
    assert (Files.isDir (new Vala.Io.Path ("/tmp/valacore/ut/.hidden.txt")) == false);
    assert (Files.isDir (new Vala.Io.Path ("/tmp/valacore/ut/.hidden")) == true);
}

void testExists () {
    assert (Files.exists (new Vala.Io.Path ("/tmp/valacore/ut/file.txt")) == true);
    assert (Files.exists (new Vala.Io.Path ("/tmp/valacore/ut")) == true);
    assert (Files.exists (new Vala.Io.Path ("no_exists")) == false);
    assert (Files.exists (new Vala.Io.Path ("/tmp/valacore/ut/symbolic.txt")) == true);
    assert (Files.exists (new Vala.Io.Path ("/tmp/valacore/ut/symbolic")) == true);
    assert (Files.exists (new Vala.Io.Path ("/tmp/valacore/ut/.hidden.txt")) == true);
    assert (Files.exists (new Vala.Io.Path ("/tmp/valacore/ut/.hidden")) == true);
}

void testCanRead () {
    assert (Files.canRead (new Vala.Io.Path ("/tmp/valacore/ut/canNotRead.txt")) == false);
    assert (Files.canRead (new Vala.Io.Path ("/tmp/valacore/ut")) == true);
    assert (Files.canRead (new Vala.Io.Path ("/tmp/valacore/ut/file.txt")) == true);
    assert (Files.canRead (new Vala.Io.Path ("/tmp/valacore/ut/no_exist_file.txt")) == false);
    assert (Files.canRead (new Vala.Io.Path ("/tmp/valacore/ut/canNotReadDir")) == false);
}

void testCanWrite () {
    assert (Files.canWrite (new Vala.Io.Path ("/tmp/valacore/ut/canNotWrite.txt")) == false);
    assert (Files.canWrite (new Vala.Io.Path ("/tmp/valacore/ut")) == true);
    assert (Files.canWrite (new Vala.Io.Path ("/tmp/valacore/ut/file.txt")) == true);
    assert (Files.canWrite (new Vala.Io.Path ("/tmp/valacore/ut/no_exist_file.txt")) == false);
    assert (Files.canWrite (new Vala.Io.Path ("/tmp/valacore/ut/canNotWriteDir")) == false);
}

void testCanExec () {
    assert (Files.canExec (new Vala.Io.Path ("/tmp/valacore/ut/canNotExec.txt")) == false);
    assert (Files.canExec (new Vala.Io.Path ("/tmp/valacore/ut")) == true);
    assert (Files.canExec (new Vala.Io.Path ("/tmp/valacore/ut/file.txt")) == true);
    assert (Files.canExec (new Vala.Io.Path ("/tmp/valacore/ut/no_exist_file.txt")) == false);
    assert (Files.canExec (new Vala.Io.Path ("/tmp/valacore/ut/canNotExecDir")) == false);
}

void testIsSymbolicFile () {
    assert (Files.isSymbolicFile (new Vala.Io.Path ("/tmp/valacore/ut")) == false);
    assert (Files.isSymbolicFile (new Vala.Io.Path ("/tmp/valacore/ut/file.txt")) == false);
    assert (Files.isSymbolicFile (new Vala.Io.Path ("/tmp/valacore/ut/no_exist_file.txt")) == false);
    assert (Files.isSymbolicFile (new Vala.Io.Path ("/tmp/valacore/ut/symbolic.txt")) == true);
    assert (Files.isSymbolicFile (new Vala.Io.Path ("/tmp/valacore/ut/symbolic")) == true);
    assert (Files.isSymbolicFile (new Vala.Io.Path ("/tmp/valacore/ut/.hidden.txt")) == false);
    assert (Files.isSymbolicFile (new Vala.Io.Path ("/tmp/valacore/ut/.hidden")) == false);
}

void testIsHiddenFile () {
    assert (Files.isHiddenFile (new Vala.Io.Path ("/tmp/valacore/ut")) == false);
    assert (Files.isHiddenFile (new Vala.Io.Path ("/tmp/valacore/ut/file.txt")) == false);
    assert (Files.isHiddenFile (new Vala.Io.Path ("/tmp/valacore/ut/no_exist_file.txt")) == false);
    assert (Files.isHiddenFile (new Vala.Io.Path ("/tmp/valacore/ut/symbolic.txt")) == false);
    assert (Files.isHiddenFile (new Vala.Io.Path ("/tmp/valacore/ut/symbolic")) == false);
    assert (Files.isHiddenFile (new Vala.Io.Path ("/tmp/valacore/ut/.hidden.txt")) == true);
    assert (Files.isHiddenFile (new Vala.Io.Path ("/tmp/valacore/ut/.hidden")) == true);
}

void testMakeDirs () {
    string testDir = "/tmp/valacore/ut/test_makedirs/a/b/c";
    /* Clean up if exists from previous run */
    if (Files.isDir (new Vala.Io.Path (testDir))) {
        Posix.system ("rm -rf /tmp/valacore/ut/test_makedirs");
    }
    /* Should create nested directories */
    assert (Files.makeDirs (new Vala.Io.Path (testDir)) == true);
    assert (Files.isDir (new Vala.Io.Path (testDir)) == true);
    /* Should return false if directory already exists */
    assert (Files.makeDirs (new Vala.Io.Path (testDir)) == false);
    /* Cleanup */
    Posix.system ("rm -rf /tmp/valacore/ut/test_makedirs");
}

void testMakeDir () {
    string testDir = "/tmp/valacore/ut/test_mkdir_single";
    /* Clean up if exists from previous run */
    if (Files.isDir (new Vala.Io.Path (testDir))) {
        Posix.system ("rm -rf " + testDir);
    }
    var files = new Files ();
    /* Should create a single directory */
    assert (files.makeDir (new Vala.Io.Path (testDir)) == true);
    assert (Files.isDir (new Vala.Io.Path (testDir)) == true);
    /* Should return false if directory already exists */
    assert (files.makeDir (new Vala.Io.Path (testDir)) == false);
    /* Should return false for nested path without parents */
    Posix.system ("rm -rf " + testDir);
    assert (files.makeDir (new Vala.Io.Path (testDir + "/a/b")) == false);
    /* Cleanup */
    Posix.system ("rm -rf " + testDir);
}
