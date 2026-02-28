using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/io/atomicfile/testWriteAndReadConsistent", testWriteAndReadConsistent);
    Test.add_func ("/io/atomicfile/testWriteBytes", testWriteBytes);
    Test.add_func ("/io/atomicfile/testAppend", testAppend);
    Test.add_func ("/io/atomicfile/testReplace", testReplace);
    Test.add_func ("/io/atomicfile/testReplaceWithBackup", testReplaceWithBackup);
    Test.add_func ("/io/atomicfile/testWriteWithBackup", testWriteWithBackup);
    Test.add_func ("/io/atomicfile/testReadConsistentMissing", testReadConsistentMissing);
    Test.add_func ("/io/atomicfile/testReplaceMissingSource", testReplaceMissingSource);
    Test.run ();
}

void testWriteAndReadConsistent () {
    Vala.Io.Path path = new Vala.Io.Path ("/tmp/valacore/ut/atomic_write.txt");
    Files.remove (path);

    var atomic = new AtomicFile ();
    assert (atomic.write (path, "hello") == true);
    assert (Files.readAllText (path) == "hello");

    string ? stable = atomic.readConsistent (path);
    assert (stable == "hello");

    assert (Files.remove (path) == true);
}

void testWriteBytes () {
    Vala.Io.Path path = new Vala.Io.Path ("/tmp/valacore/ut/atomic_bytes.bin");
    Files.remove (path);

    var atomic = new AtomicFile ();
    uint8[] data = { 0x41, 0x42, 0x43 };

    assert (atomic.writeBytes (path, data) == true);

    uint8[] ? loaded = Files.readBytes (path);
    assert (loaded != null);
    assert (loaded.length == 3);
    assert (loaded[0] == 0x41);
    assert (loaded[1] == 0x42);
    assert (loaded[2] == 0x43);

    assert (Files.remove (path) == true);
}

void testAppend () {
    Vala.Io.Path path = new Vala.Io.Path ("/tmp/valacore/ut/atomic_append.txt");
    Files.remove (path);

    var atomic = new AtomicFile ();

    assert (atomic.append (path, "a") == true);
    assert (atomic.append (path, "b") == true);
    assert (atomic.append (path, "c") == true);

    assert (Files.readAllText (path) == "abc");
    assert (Files.remove (path) == true);
}

void testReplace () {
    Vala.Io.Path srcTmp = new Vala.Io.Path ("/tmp/valacore/ut/atomic_src.tmp");
    Vala.Io.Path dst = new Vala.Io.Path ("/tmp/valacore/ut/atomic_dst.txt");

    Files.remove (srcTmp);
    Files.remove (dst);

    assert (Files.writeText (srcTmp, "new-content") == true);
    assert (Files.writeText (dst, "old-content") == true);

    var atomic = new AtomicFile ();
    assert (atomic.replace (srcTmp, dst) == true);

    assert (Files.exists (srcTmp) == false);
    assert (Files.readAllText (dst) == "new-content");

    assert (Files.remove (dst) == true);
}

void testReplaceWithBackup () {
    Vala.Io.Path srcTmp = new Vala.Io.Path ("/tmp/valacore/ut/atomic_src_backup.tmp");
    Vala.Io.Path dst = new Vala.Io.Path ("/tmp/valacore/ut/atomic_dst_backup.txt");
    Vala.Io.Path backup = new Vala.Io.Path ("/tmp/valacore/ut/atomic_dst_backup.txt.old");

    Files.remove (srcTmp);
    Files.remove (dst);
    Files.remove (backup);

    assert (Files.writeText (srcTmp, "next") == true);
    assert (Files.writeText (dst, "prev") == true);

    var atomic = new AtomicFile ().withBackup (true).backupSuffix (".old");
    assert (atomic.replace (srcTmp, dst) == true);

    assert (Files.readAllText (dst) == "next");
    assert (Files.readAllText (backup) == "prev");

    assert (Files.remove (dst) == true);
    assert (Files.remove (backup) == true);
}

void testWriteWithBackup () {
    Vala.Io.Path path = new Vala.Io.Path ("/tmp/valacore/ut/atomic_write_backup.txt");
    Vala.Io.Path backup = new Vala.Io.Path ("/tmp/valacore/ut/atomic_write_backup.txt.prev");

    Files.remove (path);
    Files.remove (backup);

    assert (Files.writeText (path, "before") == true);

    var atomic = new AtomicFile ().withBackup (true).backupSuffix (".prev");
    assert (atomic.write (path, "after") == true);

    assert (Files.readAllText (path) == "after");
    assert (Files.readAllText (backup) == "before");

    assert (Files.remove (path) == true);
    assert (Files.remove (backup) == true);
}

void testReadConsistentMissing () {
    Vala.Io.Path missing = new Vala.Io.Path ("/tmp/valacore/ut/no_such_atomic_file.txt");
    Vala.Io.Path dir = new Vala.Io.Path ("/tmp/valacore/ut");

    var atomic = new AtomicFile ();

    assert (atomic.readConsistent (missing) == null);
    assert (atomic.readConsistent (dir) == null);
}

void testReplaceMissingSource () {
    Vala.Io.Path missing = new Vala.Io.Path ("/tmp/valacore/ut/atomic_no_src.tmp");
    Vala.Io.Path dst = new Vala.Io.Path ("/tmp/valacore/ut/atomic_dst_missing.txt");

    Files.remove (missing);
    Files.remove (dst);
    assert (Files.writeText (dst, "value") == true);

    var atomic = new AtomicFile ();
    assert (atomic.replace (missing, dst) == false);
    assert (Files.readAllText (dst) == "value");

    assert (Files.remove (dst) == true);
}
