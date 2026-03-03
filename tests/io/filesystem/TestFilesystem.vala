using Vala.Io;
using Vala.Time;
using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/io/filesystem/testConstruct", testConstruct);
    Test.add_func ("/io/filesystem/testGetFileAttributes", testGetFileAttributes);
    Test.add_func ("/io/filesystem/testSetLastModifiedTime", testSetLastModifiedTime);
    Test.add_func ("/io/filesystem/testAccessChecks", testAccessChecks);
    Test.add_func ("/io/filesystem/testGetOwner", testGetOwner);
    Test.add_func ("/io/filesystem/testSetOwnerInvalid", testSetOwnerInvalid);
    Test.add_func ("/io/filesystem/testInvalidPathOperations", testInvalidPathOperations);
    Test.run ();
}

void testConstruct () {
    var filesystem = new Filesystem ();
    assert (filesystem != null);
}

Vala.Time.DateTime createDateTime (int year,
                                   int month,
                                   int day,
                                   int hour,
                                   int min,
                                   int sec) {
    var created = Vala.Time.DateTime.of (year, month, day, hour, min, sec);
    assert (created.isOk ());
    return created.unwrap ();
}

void testGetFileAttributes () {
    Vala.Io.Path ? tmp = Files.tempFile ("filesystem", ".tmp");
    assert (tmp != null);

    try {
        GLib.FileInfo info = unwrapFileInfo (Filesystem.getFileAttributes (tmp));
        assert (info.get_file_type () == GLib.FileType.REGULAR);
    } finally {
        Files.remove (tmp);
    }
}

void testSetLastModifiedTime () {
    Vala.Io.Path ? tmp = Files.tempFile ("filesystem", ".tmp");
    assert (tmp != null);

    try {
        Vala.Time.DateTime target = createDateTime (2001, 2, 3, 4, 5, 6);
        assert (unwrapBool (Filesystem.setLastModifiedTime (tmp, target)) == true);

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
        string owner = unwrapString (Filesystem.getOwner (tmp));
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
        Result<bool, GLib.Error> updated = Filesystem.setOwner (tmp, invalid_user);
        assert (updated.isError ());
        assert (updated.unwrapError () is FilesystemError.NOT_FOUND);
    } finally {
        Files.remove (tmp);
    }
}

void testInvalidPathOperations () {
    string missingPath = "/tmp/valacore/ut/no_such_filesystem_%s".printf (GLib.Uuid.string_random ());
    Vala.Io.Path missing = new Vala.Io.Path (missingPath);
    Vala.Time.DateTime target = createDateTime (2001, 2, 3, 4, 5, 6);

    Result<GLib.FileInfo, GLib.Error> info = Filesystem.getFileAttributes (missing);
    Result<bool, GLib.Error> setMtime = Filesystem.setLastModifiedTime (missing, target);
    Result<string, GLib.Error> owner = Filesystem.getOwner (missing);
    Result<bool, GLib.Error> setOwnerEmpty = Filesystem.setOwner (missing, "");

    assert (info.isError ());
    assert (info.unwrapError () is FilesystemError.NOT_FOUND);
    assert (setMtime.isError ());
    assert (setMtime.unwrapError () is FilesystemError.NOT_FOUND);
    assert (owner.isError ());
    assert (owner.unwrapError () is FilesystemError.NOT_FOUND);
    assert (setOwnerEmpty.isError ());
    assert (setOwnerEmpty.unwrapError () is FilesystemError.NOT_FOUND);
}

GLib.FileInfo unwrapFileInfo (Result<GLib.FileInfo, GLib.Error> result) {
    assert (result.isOk ());
    return result.unwrap ();
}

bool unwrapBool (Result<bool, GLib.Error> result) {
    assert (result.isOk ());
    return result.unwrap ();
}

string unwrapString (Result<string, GLib.Error> result) {
    assert (result.isOk ());
    return result.unwrap ();
}
