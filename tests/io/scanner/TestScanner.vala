using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testFromString", testFromString);
    Test.add_func ("/testFromFile", testFromFile);
    Test.add_func ("/testFromFileNotFound", testFromFileNotFound);
    Test.add_func ("/testNextLine", testNextLine);
    Test.add_func ("/testNextInt", testNextInt);
    Test.add_func ("/testNextDouble", testNextDouble);
    Test.add_func ("/testNext", testNext);
    Test.add_func ("/testHasNextLine", testHasNextLine);
    Test.add_func ("/testHasNextInt", testHasNextInt);
    Test.add_func ("/testSetDelimiter", testSetDelimiter);
    Test.add_func ("/testClose", testClose);
    Test.add_func ("/testNextAcrossLines", testNextAcrossLines);
    Test.add_func ("/testNextLineDiscardsTokens", testNextLineDiscardsTokens);
    Test.add_func ("/testEmptyInput", testEmptyInput);
    Test.add_func ("/testNegativeInt", testNegativeInt);
    Test.run ();
}

void testFromString () {
    var scanner = Vala.Io.Scanner.fromString ("hello world");
    assert (scanner != null);
    assert (scanner.next () == "hello");
    scanner.close ();
}

void testFromFile () {
    /* Create a temp file to read */
    var path = new Vala.Io.Path ("/tmp/test_scanner_from_file.txt");
    Files.writeText (path, "line1\nline2\n");

    var scanner = Vala.Io.Scanner.fromFile (path);
    assert (scanner != null);
    assert (scanner.nextLine () == "line1");
    assert (scanner.nextLine () == "line2");
    scanner.close ();

    Files.remove (path);
}

void testFromFileNotFound () {
    var scanner = Vala.Io.Scanner.fromFile (new Vala.Io.Path ("/tmp/nonexistent_scanner_test_file.txt"));
    assert (scanner == null);
}

void testNextLine () {
    var scanner = Vala.Io.Scanner.fromString ("first line\nsecond line\nthird line");
    assert (scanner.nextLine () == "first line");
    assert (scanner.nextLine () == "second line");
    assert (scanner.nextLine () == "third line");
    assert (scanner.nextLine () == null);
    scanner.close ();
}

void testNextInt () {
    var scanner = Vala.Io.Scanner.fromString ("10 20 30");
    assert (scanner.nextInt () == 10);
    assert (scanner.nextInt () == 20);
    assert (scanner.nextInt () == 30);

    /* No more tokens returns 0 */
    assert (scanner.nextInt () == 0);
    scanner.close ();
}

void testNextDouble () {
    var scanner = Vala.Io.Scanner.fromString ("3.14 2.71");
    var d1 = scanner.nextDouble ();
    assert (d1 > 3.13 && d1 < 3.15);
    var d2 = scanner.nextDouble ();
    assert (d2 > 2.70 && d2 < 2.72);

    /* No more tokens returns 0.0 */
    assert (scanner.nextDouble () == 0.0);
    scanner.close ();
}

void testNext () {
    var scanner = Vala.Io.Scanner.fromString ("alpha beta gamma");
    assert (scanner.next () == "alpha");
    assert (scanner.next () == "beta");
    assert (scanner.next () == "gamma");
    assert (scanner.next () == null);
    scanner.close ();
}

void testHasNextLine () {
    var scanner = Vala.Io.Scanner.fromString ("line1\nline2");
    assert (scanner.hasNextLine () == true);
    assert (scanner.nextLine () == "line1");
    assert (scanner.hasNextLine () == true);
    assert (scanner.nextLine () == "line2");
    assert (scanner.hasNextLine () == false);
    scanner.close ();
}

void testHasNextInt () {
    var scanner = Vala.Io.Scanner.fromString ("42 hello 7");
    assert (scanner.hasNextInt () == true);
    assert (scanner.nextInt () == 42);
    assert (scanner.hasNextInt () == false);
    assert (scanner.next () == "hello");
    assert (scanner.hasNextInt () == true);
    assert (scanner.nextInt () == 7);
    scanner.close ();
}

void testSetDelimiter () {
    var scanner = Vala.Io.Scanner.fromString ("a,b,c");
    scanner.setDelimiter (",");
    assert (scanner.next () == "a");
    assert (scanner.next () == "b");
    assert (scanner.next () == "c");
    assert (scanner.next () == null);
    scanner.close ();
}

void testClose () {
    var scanner = Vala.Io.Scanner.fromString ("data");
    scanner.close ();

    /* After close, all operations return null/0/false */
    assert (scanner.next () == null);
    assert (scanner.nextLine () == null);
    assert (scanner.nextInt () == 0);
    assert (scanner.nextDouble () == 0.0);
    assert (scanner.hasNextLine () == false);
    assert (scanner.hasNextInt () == false);

    /* Double close is safe */
    scanner.close ();
}

void testNextAcrossLines () {
    var scanner = Vala.Io.Scanner.fromString ("a b\nc d");
    assert (scanner.next () == "a");
    assert (scanner.next () == "b");
    /* next() should automatically read the next line */
    assert (scanner.next () == "c");
    assert (scanner.next () == "d");
    assert (scanner.next () == null);
    scanner.close ();
}

void testNextLineDiscardsTokens () {
    var scanner = Vala.Io.Scanner.fromString ("a b c\nd e f");
    /* Read only one token from the first line */
    assert (scanner.next () == "a");
    /* nextLine() discards remaining tokens ("b", "c") and reads "d e f" */
    assert (scanner.nextLine () == "d e f");
    scanner.close ();
}

void testEmptyInput () {
    var scanner = Vala.Io.Scanner.fromString ("");
    assert (scanner.next () == null);
    assert (scanner.nextLine () == null);
    assert (scanner.hasNextLine () == false);
    assert (scanner.hasNextInt () == false);
    scanner.close ();
}

void testNegativeInt () {
    var scanner = Vala.Io.Scanner.fromString ("-5 -100");
    assert (scanner.hasNextInt () == true);
    assert (scanner.nextInt () == -5);
    assert (scanner.nextInt () == -100);
    scanner.close ();
}
