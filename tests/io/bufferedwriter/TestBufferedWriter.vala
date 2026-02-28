using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testWriteToFile", testWriteToFile);
    Test.add_func ("/testWriteLine", testWriteLine);
    Test.add_func ("/testNewLine", testNewLine);
    Test.add_func ("/testAppendToFile", testAppendToFile);
    Test.add_func ("/testAppendCreatesFile", testAppendCreatesFile);
    Test.add_func ("/testFlush", testFlush);
    Test.add_func ("/testClose", testClose);
    Test.add_func ("/testCloseDouble", testCloseDouble);
    Test.add_func ("/testWriteAfterClose", testWriteAfterClose);
    Test.add_func ("/testFromFileInvalidPath", testFromFileInvalidPath);
    Test.run ();
}

void testWriteToFile () {
    var tmpPath = Files.tempFile ("bwtest", ".txt");
    assert (tmpPath != null);

    var writer = BufferedWriter.fromFile (tmpPath);
    assert (writer != null);
    assert (writer.write ("Hello, World!"));
    writer.close ();

    var text = Files.readAllText (tmpPath);
    assert (text == "Hello, World!");

    Files.remove (tmpPath);
}

void testWriteLine () {
    var tmpPath = Files.tempFile ("bwtest", ".txt");
    assert (tmpPath != null);

    var writer = BufferedWriter.fromFile (tmpPath);
    assert (writer != null);
    writer.writeLine ("line1");
    writer.writeLine ("line2");
    writer.close ();

    var text = Files.readAllText (tmpPath);
    assert (text == "line1\nline2\n");

    Files.remove (tmpPath);
}

void testNewLine () {
    var tmpPath = Files.tempFile ("bwtest", ".txt");
    assert (tmpPath != null);

    var writer = BufferedWriter.fromFile (tmpPath);
    assert (writer != null);
    writer.write ("a");
    writer.newLine ();
    writer.write ("b");
    writer.close ();

    var text = Files.readAllText (tmpPath);
    assert (text == "a\nb");

    Files.remove (tmpPath);
}

void testAppendToFile () {
    var tmpPath = Files.tempFile ("bwtest", ".txt");
    assert (tmpPath != null);
    Files.writeText (tmpPath, "existing ");

    var writer = BufferedWriter.fromFileAppend (tmpPath);
    assert (writer != null);
    writer.write ("appended");
    writer.close ();

    var text = Files.readAllText (tmpPath);
    assert (text == "existing appended");

    Files.remove (tmpPath);
}

void testAppendCreatesFile () {
    var tmpDir = Files.tempDir ("bwtest");
    assert (tmpDir != null);
    var filePath = new Vala.Io.Path (tmpDir.toString () + "/new_file.txt");

    var writer = BufferedWriter.fromFileAppend (filePath);
    assert (writer != null);
    writer.write ("created");
    writer.close ();

    var text = Files.readAllText (filePath);
    assert (text == "created");

    Files.remove (filePath);
    Files.remove (tmpDir);
}

void testFlush () {
    var tmpPath = Files.tempFile ("bwtest", ".txt");
    assert (tmpPath != null);

    var writer = BufferedWriter.fromFile (tmpPath);
    assert (writer != null);
    writer.write ("data");
    assert (writer.flush ());
    writer.close ();

    var text = Files.readAllText (tmpPath);
    assert (text == "data");

    Files.remove (tmpPath);
}

void testClose () {
    var tmpPath = Files.tempFile ("bwtest", ".txt");
    assert (tmpPath != null);

    var writer = BufferedWriter.fromFile (tmpPath);
    assert (writer != null);
    writer.close ();

    /* flush after close returns false */
    assert (writer.flush () == false);

    Files.remove (tmpPath);
}

void testCloseDouble () {
    var tmpPath = Files.tempFile ("bwtest", ".txt");
    assert (tmpPath != null);

    var writer = BufferedWriter.fromFile (tmpPath);
    assert (writer != null);
    writer.close ();
    writer.close (); /* Should not crash */

    Files.remove (tmpPath);
}

void testWriteAfterClose () {
    var tmpPath = Files.tempFile ("bwtest", ".txt");
    assert (tmpPath != null);

    var writer = BufferedWriter.fromFile (tmpPath);
    assert (writer != null);
    writer.close ();

    assert (writer.write ("data") == false);
    assert (writer.writeLine ("data") == false);
    assert (writer.newLine () == false);

    Files.remove (tmpPath);
}

void testFromFileInvalidPath () {
    var path = new Vala.Io.Path ("/nonexistent/dir/does/not/exist/file.txt");
    var writer = BufferedWriter.fromFile (path);
    assert (writer == null);
}
