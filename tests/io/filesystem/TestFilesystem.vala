using Vala.Io;
using Vala.Time;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/io/filesystem/testGetFileAttributes", testGetFileAttributes);
    Test.add_func ("/io/filesystem/testSetLastModifiedTime", testSetLastModifiedTime);
    Test.add_func ("/io/filesystem/testAccessChecks", testAccessChecks);
    Test.add_func ("/io/filesystem/testGetOwner", testGetOwner);
    Test.add_func ("/io/filesystem/testSetOwnerInvalid", testSetOwnerInvalid);
    Test.run ();
}

void testGetFileAttributes () {
    Vala.Io.Path ? tmp = Files.tempFile ("filesystem", ".tmp");
    assert (tmp != null);

    try {
        GLib.FileInfo ? info = Filesystem.getFileAttributes (tmp);
        assert (info != null);
        assert (info.get_file_type () == GLib.FileType.REGULAR);
    } finally {
        Files.remove (tmp);
    }
}

void testSetLastModifiedTime () {
    Vala.Io.Path ? tmp = Files.tempFile ("filesystem", ".tmp");
    assert (tmp != null);

    try {
        Vala.Time.DateTime target = Vala.Time.DateTime.of (2001, 2, 3, 4, 5, 6);
        assert (Filesystem.setLastModifiedTime (tmp, target) == true);

        GLib.DateTime ? modified = Files.lastModified (tmp);
        assert (modified != null);
        int64 diff = modified.to_unix () - target.toUnixTimestamp ();
        assert (diff >= -1 && diff <= 1);
    } finally {
        Files.remove (tmp);
    }
}

void testAccessChecks () {
    Vala.Io.Path ? tmp = Files.tempFile ("filesystem", ".tmp");
    assert (tmp != null);

    try {
        // Default temp file: readable + writable, not executable
        assert (Filesystem.isReadable (tmp) == true);
        assert (Filesystem.isWritable (tmp) == true);
        assert (Filesystem.isExecutable (tmp) == false);

        // Make read-only
        GLib.FileUtils.chmod (tmp.toString (), (int) Posix.S_IRUSR);
        assert (Filesystem.isReadable (tmp) == true);
        assert (Filesystem.isWritable (tmp) == false);
        assert (Filesystem.isExecutable (tmp) == false);

        // Restore write permission for cleanup
        GLib.FileUtils.chmod (tmp.toString (), (int) (Posix.S_IRUSR | Posix.S_IWUSR));
    } finally {
        Files.remove (tmp);
    }
}

void testGetOwner () {
    Vala.Io.Path ? tmp = Files.tempFile ("filesystem", ".tmp");
    assert (tmp != null);

    try {
        string ? owner = Filesystem.getOwner (tmp);
        assert (owner != null);
        assert (owner.length > 0);
    } finally {
        Files.remove (tmp);
    }
}

void testSetOwnerInvalid () {
    Vala.Io.Path ? tmp = Files.tempFile ("filesystem", ".tmp");
    assert (tmp != null);

    try {
        string invalid_user = "libvalacore-no-such-user-%d".printf (Posix.getpid ());
        assert (Filesystem.setOwner (tmp, invalid_user) == false);
    } finally {
        Files.remove (tmp);
    }
}
