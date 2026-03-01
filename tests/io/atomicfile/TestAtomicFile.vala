using Vala.Io;

Vala.Io.Path mustTempDir (string prefix) {
    Vala.Io.Path ? dir = Files.tempDir (prefix);
    assert (dir != null);
    return (Vala.Io.Path) dir;
}

void cleanupTempDir (Vala.Io.Path dir) {
    Files.deleteRecursive (dir);
}

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
    Test.add_func ("/io/atomicfile/testBackupSuffixInvalid", testBackupSuffixInvalid);
    Test.run ();
}

AtomicFile atomicWithBackup (string suffix) {
    try {
        return new AtomicFile ().withBackup (true).backupSuffix (suffix);
    } catch (AtomicFileError e) {
        assert_not_reached ();
    }
}

void testWriteAndReadConsistent () {
    Vala.Io.Path dir = mustTempDir ("atomicfile-write-");
    Vala.Io.Path path = dir.resolve ("atomic_write.txt");

    try {
        var atomic = new AtomicFile ();
        assert (atomic.write (path, "hello") == true);
        assert (Files.readAllText (path) == "hello");

        string ? stable = atomic.readConsistent (path);
        assert (stable == "hello");
    } finally {
        cleanupTempDir (dir);
    }
}

void testWriteBytes () {
    Vala.Io.Path dir = mustTempDir ("atomicfile-bytes-");
    Vala.Io.Path path = dir.resolve ("atomic_bytes.bin");

    try {
        var atomic = new AtomicFile ();
        uint8[] data = { 0x41, 0x42, 0x43 };

        assert (atomic.writeBytes (path, data) == true);

        uint8[] ? loaded = Files.readBytes (path);
        assert (loaded != null);
        assert (loaded.length == 3);
        assert (loaded[0] == 0x41);
        assert (loaded[1] == 0x42);
        assert (loaded[2] == 0x43);
    } finally {
        cleanupTempDir (dir);
    }
}

void testAppend () {
    Vala.Io.Path dir = mustTempDir ("atomicfile-append-");
    Vala.Io.Path path = dir.resolve ("atomic_append.txt");

    try {
        var atomic = new AtomicFile ();

        assert (atomic.append (path, "a") == true);
        assert (atomic.append (path, "b") == true);
        assert (atomic.append (path, "c") == true);

        assert (Files.readAllText (path) == "abc");
    } finally {
        cleanupTempDir (dir);
    }
}

void testReplace () {
    Vala.Io.Path dir = mustTempDir ("atomicfile-replace-");
    Vala.Io.Path srcTmp = dir.resolve ("atomic_src.tmp");
    Vala.Io.Path dst = dir.resolve ("atomic_dst.txt");

    try {
        assert (Files.writeText (srcTmp, "new-content") == true);
        assert (Files.writeText (dst, "old-content") == true);

        var atomic = new AtomicFile ();
        assert (atomic.replace (srcTmp, dst) == true);

        assert (Files.exists (srcTmp) == false);
        assert (Files.readAllText (dst) == "new-content");
    } finally {
        cleanupTempDir (dir);
    }
}

void testReplaceWithBackup () {
    Vala.Io.Path dir = mustTempDir ("atomicfile-replace-backup-");
    Vala.Io.Path srcTmp = dir.resolve ("atomic_src_backup.tmp");
    Vala.Io.Path dst = dir.resolve ("atomic_dst_backup.txt");
    Vala.Io.Path backup = dir.resolve ("atomic_dst_backup.txt.old");

    try {
        assert (Files.writeText (srcTmp, "next") == true);
        assert (Files.writeText (dst, "prev") == true);

        var atomic = atomicWithBackup (".old");
        assert (atomic.replace (srcTmp, dst) == true);

        assert (Files.readAllText (dst) == "next");
        assert (Files.readAllText (backup) == "prev");
    } finally {
        cleanupTempDir (dir);
    }
}

void testWriteWithBackup () {
    Vala.Io.Path dir = mustTempDir ("atomicfile-write-backup-");
    Vala.Io.Path path = dir.resolve ("atomic_write_backup.txt");
    Vala.Io.Path backup = dir.resolve ("atomic_write_backup.txt.prev");

    try {
        assert (Files.writeText (path, "before") == true);

        var atomic = atomicWithBackup (".prev");
        assert (atomic.write (path, "after") == true);

        assert (Files.readAllText (path) == "after");
        assert (Files.readAllText (backup) == "before");
    } finally {
        cleanupTempDir (dir);
    }
}

void testReadConsistentMissing () {
    Vala.Io.Path dir = mustTempDir ("atomicfile-missing-");
    Vala.Io.Path missing = dir.resolve ("no_such_atomic_file.txt");
    Vala.Io.Path existingDir = new Vala.Io.Path (Environment.get_tmp_dir ());

    try {
        var atomic = new AtomicFile ();

        assert (atomic.readConsistent (missing) == null);
        assert (atomic.readConsistent (existingDir) == null);
    } finally {
        cleanupTempDir (dir);
    }
}

void testReplaceMissingSource () {
    Vala.Io.Path dir = mustTempDir ("atomicfile-missing-src-");
    Vala.Io.Path missing = dir.resolve ("atomic_no_src.tmp");
    Vala.Io.Path dst = dir.resolve ("atomic_dst_missing.txt");

    try {
        assert (Files.writeText (dst, "value") == true);

        var atomic = new AtomicFile ();
        assert (atomic.replace (missing, dst) == false);
        assert (Files.readAllText (dst) == "value");
    } finally {
        cleanupTempDir (dir);
    }
}

void testBackupSuffixInvalid () {
    bool thrown = false;
    try {
        new AtomicFile ().backupSuffix ("");
    } catch (AtomicFileError e) {
        thrown = true;
        assert (e is AtomicFileError.INVALID_ARGUMENT);
    }
    assert (thrown);
}
