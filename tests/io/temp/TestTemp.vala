using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/io/temp/testWithTempFile", testWithTempFile);
    Test.add_func ("/io/temp/testWithTempDir", testWithTempDir);
    Test.run ();
}

void testWithTempFile () {
    Vala.Io.Path ? tempPath = null;

    assert (Temp.withTempFile ((path) => {
        tempPath = path;
        assert (Files.exists (path) == true);
        assert (Files.writeText (path, "temp-data") == true);
        assert (Files.readAllText (path) == "temp-data");
    }) == true);

    assert (tempPath != null);
    assert (Files.exists (tempPath) == false);
}

void testWithTempDir () {
    Vala.Io.Path ? tempDir = null;

    assert (Temp.withTempDir ((dir) => {
        tempDir = dir;
        assert (Files.exists (dir) == true);
        assert (Files.isDir (dir) == true);

        Vala.Io.Path child = dir.resolve ("child.txt");
        assert (Files.writeText (child, "hello") == true);
        assert (Files.exists (child) == true);
    }) == true);

    assert (tempDir != null);
    assert (Files.exists (tempDir) == false);
}
