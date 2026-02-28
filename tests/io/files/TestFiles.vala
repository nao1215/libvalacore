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
    Test.add_func ("/testReadBytes", testReadBytes);
    Test.add_func ("/testWriteBytes", testWriteBytes);
    Test.add_func ("/testChmod", testChmod);
    Test.add_func ("/testChown", testChown);
    Test.add_func ("/testLastModified", testLastModified);
    Test.add_func ("/testCreateSymlink", testCreateSymlink);
    Test.add_func ("/testReadSymlink", testReadSymlink);
    Test.add_func ("/testIsSameFile", testIsSameFile);
    Test.add_func ("/testGlob", testGlob);
    Test.add_func ("/testDeleteRecursive", testDeleteRecursive);
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

void testReadBytes () {
    string path = "/tmp/valacore/ut/test_readbytes.bin";
    Files.writeText (new Vala.Io.Path (path), "Hello");

    uint8[] ? data = Files.readBytes (new Vala.Io.Path (path));
    assert (data != null);
    assert (data.length == 5);
    assert (data[0] == 'H');
    assert (data[4] == 'o');

    /* Non-existent file returns null */
    assert (Files.readBytes (new Vala.Io.Path ("/tmp/valacore/ut/no_such")) == null);

    /* Directory returns null */
    assert (Files.readBytes (new Vala.Io.Path ("/tmp/valacore/ut")) == null);

    /* Cleanup */
    Posix.system ("rm -f " + path);
}

void testWriteBytes () {
    string path = "/tmp/valacore/ut/test_writebytes.bin";
    Posix.system ("rm -f " + path);

    uint8[] data = { 0x48, 0x65, 0x6C, 0x6C, 0x6F };
    assert (Files.writeBytes (new Vala.Io.Path (path), data) == true);

    /* Read back and verify */
    string ? text = Files.readAllText (new Vala.Io.Path (path));
    assert (text == "Hello");

    /* Write empty byte array */
    uint8[] empty = {};
    assert (Files.writeBytes (new Vala.Io.Path (path), empty) == true);
    assert (Files.size (new Vala.Io.Path (path)) == 0);

    /* Cleanup */
    Posix.system ("rm -f " + path);
}

void testChmod () {
    string path = "/tmp/valacore/ut/test_chmod.txt";
    Files.writeText (new Vala.Io.Path (path), "chmod test");

    /* Make read-only */
    assert (Files.chmod (new Vala.Io.Path (path), 0444) == true);
    assert (Files.canWrite (new Vala.Io.Path (path)) == false);

    /* Restore write permission */
    assert (Files.chmod (new Vala.Io.Path (path), 0644) == true);
    assert (Files.canWrite (new Vala.Io.Path (path)) == true);

    /* Make executable */
    assert (Files.chmod (new Vala.Io.Path (path), 0755) == true);
    assert (Files.canExec (new Vala.Io.Path (path)) == true);

    /* Non-existent file returns false */
    assert (Files.chmod (new Vala.Io.Path ("/tmp/valacore/ut/no_such"), 0644) == false);

    /* Cleanup */
    Posix.system ("rm -f " + path);
}

void testChown () {
    string path = "/tmp/valacore/ut/test_chown.txt";
    Files.writeText (new Vala.Io.Path (path), "chown test");

    /* Chown to current user (should succeed without root) */
    int uid = (int) Posix.getuid ();
    int gid = (int) Posix.getgid ();
    assert (Files.chown (new Vala.Io.Path (path), uid, gid) == true);

    /* Non-existent file returns false */
    assert (Files.chown (new Vala.Io.Path ("/tmp/valacore/ut/no_such"), uid, gid) == false);

    /* Cleanup */
    Posix.system ("rm -f " + path);
}

void testLastModified () {
    string path = "/tmp/valacore/ut/test_lastmod.txt";
    Files.writeText (new Vala.Io.Path (path), "lastmod test");

    GLib.DateTime ? mtime = Files.lastModified (new Vala.Io.Path (path));
    assert (mtime != null);
    /* Should be a reasonable year */
    assert (mtime.get_year () >= 2024);

    /* Non-existent file returns null */
    assert (Files.lastModified (new Vala.Io.Path ("/tmp/valacore/ut/no_such")) == null);

    /* Cleanup */
    Posix.system ("rm -f " + path);
}

void testCreateSymlink () {
    string target = "/tmp/valacore/ut/test_symlink_target.txt";
    string link = "/tmp/valacore/ut/test_symlink_link.txt";
    Posix.system ("rm -f " + target + " " + link);

    Files.writeText (new Vala.Io.Path (target), "symlink target");

    /* Create symlink succeeds */
    assert (Files.createSymlink (new Vala.Io.Path (target), new Vala.Io.Path (link)) == true);
    assert (Files.isSymbolicFile (new Vala.Io.Path (link)) == true);
    assert (Files.readAllText (new Vala.Io.Path (link)) == "symlink target");

    /* Create symlink to existing link path fails */
    assert (Files.createSymlink (new Vala.Io.Path (target), new Vala.Io.Path (link)) == false);

    /* Dangling symlink (target doesn't exist) succeeds */
    string dangling = "/tmp/valacore/ut/test_dangling_link.txt";
    Posix.system ("rm -f " + dangling);
    assert (Files.createSymlink (new Vala.Io.Path ("/tmp/valacore/ut/no_such"), new Vala.Io.Path (dangling)) == true);
    assert (Files.isSymbolicFile (new Vala.Io.Path (dangling)) == true);

    /* Cleanup */
    Posix.system ("rm -f " + target + " " + link + " " + dangling);
}

void testReadSymlink () {
    /* Use existing fixture symlink */
    var target = Files.readSymlink (new Vala.Io.Path ("/tmp/valacore/ut/symbolic.txt"));
    assert (target != null);

    /* Create a new symlink and read it */
    string src = "/tmp/valacore/ut/test_readlink_target.txt";
    string lnk = "/tmp/valacore/ut/test_readlink_link.txt";
    Posix.system ("rm -f " + src + " " + lnk);
    Files.writeText (new Vala.Io.Path (src), "read link");
    Files.createSymlink (new Vala.Io.Path (src), new Vala.Io.Path (lnk));

    var result = Files.readSymlink (new Vala.Io.Path (lnk));
    assert (result != null);
    assert (result.toString () == src);

    /* Regular file returns null */
    assert (Files.readSymlink (new Vala.Io.Path (src)) == null);

    /* Non-existent path returns null */
    assert (Files.readSymlink (new Vala.Io.Path ("/tmp/valacore/ut/no_such")) == null);

    /* Cleanup */
    Posix.system ("rm -f " + src + " " + lnk);
}

void testIsSameFile () {
    string path = "/tmp/valacore/ut/test_samefile.txt";
    Files.writeText (new Vala.Io.Path (path), "same file");

    /* Same path is same file */
    assert (Files.isSameFile (new Vala.Io.Path (path), new Vala.Io.Path (path)) == true);

    /* Symlink points to same file */
    string link = "/tmp/valacore/ut/test_samefile_link.txt";
    Posix.system ("rm -f " + link);
    Files.createSymlink (new Vala.Io.Path (path), new Vala.Io.Path (link));
    assert (Files.isSameFile (new Vala.Io.Path (path), new Vala.Io.Path (link)) == true);

    /* Different files are not same */
    string other = "/tmp/valacore/ut/test_samefile_other.txt";
    Files.writeText (new Vala.Io.Path (other), "different");
    assert (Files.isSameFile (new Vala.Io.Path (path), new Vala.Io.Path (other)) == false);

    /* Non-existent file returns false */
    assert (Files.isSameFile (new Vala.Io.Path (path), new Vala.Io.Path ("/tmp/valacore/ut/no_such")) == false);

    /* Cleanup */
    Posix.system ("rm -f " + path + " " + link + " " + other);
}

void testGlob () {
    string dir = "/tmp/valacore/ut/test_glob";
    Posix.system ("rm -rf " + dir);
    Files.makeDirs (new Vala.Io.Path (dir));
    Files.writeText (new Vala.Io.Path (dir + "/a.txt"), "a");
    Files.writeText (new Vala.Io.Path (dir + "/b.txt"), "b");
    Files.writeText (new Vala.Io.Path (dir + "/c.log"), "c");

    /* Match *.txt returns 2 entries */
    var matches = Files.glob (new Vala.Io.Path (dir), "*.txt");
    assert (matches != null);
    assert (matches.length () == 2);

    /* Match *.log returns 1 entry */
    matches = Files.glob (new Vala.Io.Path (dir), "*.log");
    assert (matches != null);
    assert (matches.length () == 1);

    /* Match * returns all entries */
    matches = Files.glob (new Vala.Io.Path (dir), "*");
    assert (matches != null);
    assert (matches.length () == 3);

    /* No match returns null (empty GLib.List is null) */
    matches = Files.glob (new Vala.Io.Path (dir), "*.xyz");
    assert (matches == null);

    /* Non-existent directory returns null */
    assert (Files.glob (new Vala.Io.Path ("/tmp/valacore/ut/no_such"), "*.txt") == null);

    /* Empty pattern returns null */
    assert (Files.glob (new Vala.Io.Path (dir), "") == null);

    /* Cleanup */
    Posix.system ("rm -rf " + dir);
}

void testDeleteRecursive () {
    string dir = "/tmp/valacore/ut/test_delrec";
    Posix.system ("rm -rf " + dir);

    /* Create nested directory structure */
    Files.makeDirs (new Vala.Io.Path (dir + "/a/b"));
    Files.writeText (new Vala.Io.Path (dir + "/file1.txt"), "file1");
    Files.writeText (new Vala.Io.Path (dir + "/a/file2.txt"), "file2");
    Files.writeText (new Vala.Io.Path (dir + "/a/b/file3.txt"), "file3");

    /* Recursive delete succeeds */
    assert (Files.deleteRecursive (new Vala.Io.Path (dir)) == true);
    assert (Files.exists (new Vala.Io.Path (dir)) == false);

    /* Non-existent path returns false */
    assert (Files.deleteRecursive (new Vala.Io.Path (dir)) == false);

    /* Single file works */
    string single = "/tmp/valacore/ut/test_delrec_single.txt";
    Files.writeText (new Vala.Io.Path (single), "single");
    assert (Files.deleteRecursive (new Vala.Io.Path (single)) == true);
    assert (Files.exists (new Vala.Io.Path (single)) == false);

    /* Empty directory works */
    string emptyDir = "/tmp/valacore/ut/test_delrec_empty";
    Files.makeDirs (new Vala.Io.Path (emptyDir));
    assert (Files.deleteRecursive (new Vala.Io.Path (emptyDir)) == true);
    assert (Files.exists (new Vala.Io.Path (emptyDir)) == false);
}
