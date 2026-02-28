using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testFromString", testFromString);
    Test.add_func ("/testReadLineMultiple", testReadLineMultiple);
    Test.add_func ("/testReadLineEof", testReadLineEof);
    Test.add_func ("/testReadAll", testReadAll);
    Test.add_func ("/testReadAllEmpty", testReadAllEmpty);
    Test.add_func ("/testReadChar", testReadChar);
    Test.add_func ("/testHasNext", testHasNext);
    Test.add_func ("/testHasNextEmpty", testHasNextEmpty);
    Test.add_func ("/testHasNextThenReadLine", testHasNextThenReadLine);
    Test.add_func ("/testClose", testClose);
    Test.add_func ("/testCloseDouble", testCloseDouble);
    Test.add_func ("/testFromFile", testFromFile);
    Test.add_func ("/testFromFileNotFound", testFromFileNotFound);
    Test.run ();
}

void testFromString () {
    var reader = BufferedReader.fromString ("hello");
    assert (reader != null);
    var line = reader.readLine ();
    assert (line == "hello");
    reader.close ();
}

void testReadLineMultiple () {
    var reader = BufferedReader.fromString ("line1\nline2\nline3");
    assert (reader.readLine () == "line1");
    assert (reader.readLine () == "line2");
    assert (reader.readLine () == "line3");
    assert (reader.readLine () == null);
    reader.close ();
}

void testReadLineEof () {
    var reader = BufferedReader.fromString ("");
    assert (reader.readLine () == null);
    reader.close ();
}

void testReadAll () {
    var reader = BufferedReader.fromString ("line1\nline2\nline3");
    var text = reader.readAll ();
    assert (text == "line1\nline2\nline3");
    reader.close ();
}

void testReadAllEmpty () {
    var reader = BufferedReader.fromString ("");
    var text = reader.readAll ();
    assert (text == "");
    reader.close ();
}

void testReadChar () {
    var reader = BufferedReader.fromString ("AB");
    assert (reader.readChar () == 'A');
    assert (reader.readChar () == 'B');
    reader.close ();
}

void testHasNext () {
    var reader = BufferedReader.fromString ("line1\nline2");
    assert (reader.hasNext () == true);
    reader.readLine ();
    assert (reader.hasNext () == true);
    reader.readLine ();
    assert (reader.hasNext () == false);
    reader.close ();
}

void testHasNextEmpty () {
    var reader = BufferedReader.fromString ("");
    assert (reader.hasNext () == false);
    reader.close ();
}

void testHasNextThenReadLine () {
    var reader = BufferedReader.fromString ("hello\nworld");
    /* hasNext peeks; readLine should return the peeked line */
    assert (reader.hasNext () == true);
    assert (reader.readLine () == "hello");
    assert (reader.hasNext () == true);
    assert (reader.readLine () == "world");
    assert (reader.hasNext () == false);
    reader.close ();
}

void testClose () {
    var reader = BufferedReader.fromString ("data");
    reader.close ();
    /* After close, operations return null/zero */
    assert (reader.readLine () == null);
    assert (reader.readAll () == null);
    assert (reader.readChar () == '\0');
    assert (reader.hasNext () == false);
}

void testCloseDouble () {
    var reader = BufferedReader.fromString ("data");
    reader.close ();
    reader.close (); /* Should not crash */
}

void testFromFile () {
    /* Write a temp file, then read it */
    var tmpPath = Files.tempFile ("brtest", ".txt");
    assert (tmpPath != null);
    Files.writeText (tmpPath, "aaa\nbbb\nccc");

    var reader = BufferedReader.fromFile (tmpPath);
    assert (reader != null);
    assert (reader.readLine () == "aaa");
    assert (reader.readLine () == "bbb");
    assert (reader.readLine () == "ccc");
    assert (reader.readLine () == null);
    reader.close ();

    Files.remove (tmpPath);
}

void testFromFileNotFound () {
    var path = new Vala.Io.Path ("/nonexistent/path/does/not/exist.txt");
    var reader = BufferedReader.fromFile (path);
    assert (reader == null);
}
