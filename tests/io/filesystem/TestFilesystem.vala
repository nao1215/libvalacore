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
        assert (modified.to_unix () == target.toUnixTimestamp ());
    } finally {
        Files.remove (tmp);
    }
}

void testAccessChecks () {
    Vala.Io.Path ? tmp = Files.tempFile ("filesystem", ".tmp");
    assert (tmp != null);

    try {
        assert (Filesystem.isReadable (tmp) == Files.canRead (tmp));
        assert (Filesystem.isWritable (tmp) == Files.canWrite (tmp));
        assert (Filesystem.isExecutable (tmp) == Files.canExec (tmp));
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
        assert (Filesystem.setOwner (tmp, "libvalacore-no-such-user") == false);
    } finally {
        Files.remove (tmp);
    }
}
