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
    Test.add_func ("/testCopy", testCopy);
    Test.add_func ("/testMove", testMove);
    Test.add_func ("/testRemove", testRemove);
    Test.add_func ("/testReadAllText", testReadAllText);
    Test.add_func ("/testReadAllLines", testReadAllLines);
    Test.add_func ("/testWriteText", testWriteText);
    Test.add_func ("/testAppendText", testAppendText);
    Test.add_func ("/testSize", testSize);
    Test.add_func ("/testListDir", testListDir);
    Test.add_func ("/testTempFile", testTempFile);
    Test.add_func ("/testTempDir", testTempDir);
    Test.add_func ("/testTouch", testTouch);
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

void testCopy () {
    string src = "/tmp/valacore/ut/test_copy_src.txt";
    string dst = "/tmp/valacore/ut/test_copy_dst.txt";
    /* Setup */
    Files.writeText (new Vala.Io.Path (src), "copy content");

    /* Copy succeeds */
    assert (Files.copy (new Vala.Io.Path (src), new Vala.Io.Path (dst)) == true);
    assert (Files.exists (new Vala.Io.Path (dst)) == true);
    assert (Files.readAllText (new Vala.Io.Path (dst)) == "copy content");

    /* Copy non-existent file fails */
    assert (Files.copy (new Vala.Io.Path ("/tmp/valacore/ut/no_such_file"), new Vala.Io.Path (dst)) == false);

    /* Copy directory fails */
    assert (Files.copy (new Vala.Io.Path ("/tmp/valacore/ut"), new Vala.Io.Path (dst)) == false);

    /* Cleanup */
    Posix.system ("rm -f " + src + " " + dst);
}

void testMove () {
    string src = "/tmp/valacore/ut/test_move_src.txt";
    string dst = "/tmp/valacore/ut/test_move_dst.txt";
    /* Setup */
    Files.writeText (new Vala.Io.Path (src), "move content");

    /* Move succeeds */
    assert (Files.move (new Vala.Io.Path (src), new Vala.Io.Path (dst)) == true);
    assert (Files.exists (new Vala.Io.Path (src)) == false);
    assert (Files.exists (new Vala.Io.Path (dst)) == true);
    assert (Files.readAllText (new Vala.Io.Path (dst)) == "move content");

    /* Move non-existent file fails */
    assert (Files.move (new Vala.Io.Path (src), new Vala.Io.Path (dst)) == false);

    /* Cleanup */
    Posix.system ("rm -f " + dst);
}

void testRemove () {
    string path = "/tmp/valacore/ut/test_remove.txt";
    /* Setup */
    Files.writeText (new Vala.Io.Path (path), "remove me");

    /* Remove succeeds */
    assert (Files.remove (new Vala.Io.Path (path)) == true);
    assert (Files.exists (new Vala.Io.Path (path)) == false);

    /* Remove non-existent file fails */
    assert (Files.remove (new Vala.Io.Path (path)) == false);

    /* Remove empty directory */
    string dir = "/tmp/valacore/ut/test_remove_dir";
    Files.makeDirs (new Vala.Io.Path (dir));
    assert (Files.remove (new Vala.Io.Path (dir)) == true);
}

void testReadAllText () {
    string path = "/tmp/valacore/ut/test_read.txt";
    Files.writeText (new Vala.Io.Path (path), "hello world");

    /* Read text */
    string ? text = Files.readAllText (new Vala.Io.Path (path));
    assert (text != null);
    assert (text == "hello world");

    /* Read non-existent file returns null */
    assert (Files.readAllText (new Vala.Io.Path ("/tmp/valacore/ut/no_such")) == null);

    /* Read directory returns null */
    assert (Files.readAllText (new Vala.Io.Path ("/tmp/valacore/ut")) == null);

    /* Cleanup */
    Posix.system ("rm -f " + path);
}

void testReadAllLines () {
    string path = "/tmp/valacore/ut/test_lines.txt";
    Files.writeText (new Vala.Io.Path (path), "line1\nline2\nline3");

    var lines = Files.readAllLines (new Vala.Io.Path (path));
    assert (lines != null);
    assert (lines.nth_data (0) == "line1");
    assert (lines.nth_data (1) == "line2");
    assert (lines.nth_data (2) == "line3");

    /* Non-existent file returns null */
    assert (Files.readAllLines (new Vala.Io.Path ("/tmp/valacore/ut/no_such")) == null);

    /* Cleanup */
    Posix.system ("rm -f " + path);
}

void testWriteText () {
    string path = "/tmp/valacore/ut/test_write.txt";

    /* Write creates file */
    assert (Files.writeText (new Vala.Io.Path (path), "first") == true);
    assert (Files.readAllText (new Vala.Io.Path (path)) == "first");

    /* Write overwrites */
    assert (Files.writeText (new Vala.Io.Path (path), "second") == true);
    assert (Files.readAllText (new Vala.Io.Path (path)) == "second");

    /* Cleanup */
    Posix.system ("rm -f " + path);
}

void testAppendText () {
    string path = "/tmp/valacore/ut/test_append.txt";
    Posix.system ("rm -f " + path);

    /* Append to non-existent creates file */
    assert (Files.appendText (new Vala.Io.Path (path), "first") == true);
    assert (Files.readAllText (new Vala.Io.Path (path)) == "first");

    /* Append adds to end */
    assert (Files.appendText (new Vala.Io.Path (path), " second") == true);
    assert (Files.readAllText (new Vala.Io.Path (path)) == "first second");

    /* Cleanup */
    Posix.system ("rm -f " + path);
}

void testSize () {
    string path = "/tmp/valacore/ut/test_size.txt";
    Files.writeText (new Vala.Io.Path (path), "12345");

    assert (Files.size (new Vala.Io.Path (path)) == 5);

    /* Non-existent file returns -1 */
    assert (Files.size (new Vala.Io.Path ("/tmp/valacore/ut/no_such")) == -1);

    /* Cleanup */
    Posix.system ("rm -f " + path);
}

void testListDir () {
    string dir = "/tmp/valacore/ut/test_listdir";
    Posix.system ("rm -rf " + dir);
    Files.makeDirs (new Vala.Io.Path (dir));
    Files.writeText (new Vala.Io.Path (dir + "/a.txt"), "a");
    Files.writeText (new Vala.Io.Path (dir + "/b.txt"), "b");

    var entries = Files.listDir (new Vala.Io.Path (dir));
    assert (entries != null);
    assert (entries.length () == 2);

    /* Non-directory returns null */
    assert (Files.listDir (new Vala.Io.Path ("/tmp/valacore/ut/file.txt")) == null);

    /* Cleanup */
    Posix.system ("rm -rf " + dir);
}

void testTempFile () {
    var tmp = Files.tempFile ("valacore_test_", ".tmp");
    assert (tmp != null);
    assert (Files.exists (tmp) == true);
    assert (tmp.toString ().has_suffix (".tmp"));

    /* Cleanup */
    Posix.system ("rm -f " + tmp.toString ());
}

void testTempDir () {
    var tmp = Files.tempDir ("valacore_test_");
    assert (tmp != null);
    assert (Files.isDir (tmp) == true);

    /* Cleanup */
    Posix.system ("rm -rf " + tmp.toString ());
}

void testTouch () {
    string path = "/tmp/valacore/ut/test_touch.txt";
    Posix.system ("rm -f " + path);

    /* Touch creates non-existent file */
    assert (Files.touch (new Vala.Io.Path (path)) == true);
    assert (Files.exists (new Vala.Io.Path (path)) == true);

    /* Touch existing file updates timestamp */
    assert (Files.touch (new Vala.Io.Path (path)) == true);

    /* Cleanup */
    Posix.system ("rm -f " + path);
}
