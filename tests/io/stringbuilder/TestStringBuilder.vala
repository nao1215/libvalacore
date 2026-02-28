using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testDefaultConstructor", testDefaultConstructor);
    Test.add_func ("/testWithStringConstructor", testWithStringConstructor);
    Test.add_func ("/testSizedConstructor", testSizedConstructor);
    Test.add_func ("/testAppend", testAppend);
    Test.add_func ("/testAppendChaining", testAppendChaining);
    Test.add_func ("/testAppendLine", testAppendLine);
    Test.add_func ("/testAppendChar", testAppendChar);
    Test.add_func ("/testInsert", testInsert);
    Test.add_func ("/testInsertBoundary", testInsertBoundary);
    Test.add_func ("/testDeleteRange", testDeleteRange);
    Test.add_func ("/testDeleteRangeBoundary", testDeleteRangeBoundary);
    Test.add_func ("/testReplaceRange", testReplaceRange);
    Test.add_func ("/testReplaceRangeBoundary", testReplaceRangeBoundary);
    Test.add_func ("/testReverse", testReverse);
    Test.add_func ("/testLength", testLength);
    Test.add_func ("/testCharAt", testCharAt);
    Test.add_func ("/testCharAtBoundary", testCharAtBoundary);
    Test.add_func ("/testClear", testClear);
    Test.add_func ("/testToString", testToString);
    Test.add_func ("/testCapacity", testCapacity);
    Test.add_func ("/testInstantiation", testInstantiation);
    Test.run ();
}

void testDefaultConstructor () {
    var sb = new Vala.Io.StringBuilder ();
    assert (sb.length () == 0);
    assert (sb.toString () == "");
}

void testWithStringConstructor () {
    var sb = new Vala.Io.StringBuilder.withString ("hello");
    assert (sb.toString () == "hello");
    assert (sb.length () == 5);
}

void testSizedConstructor () {
    var sb = new Vala.Io.StringBuilder.sized (1024);
    assert (sb.length () == 0);
    assert (sb.capacity () >= 1024);
}

void testAppend () {
    var sb = new Vala.Io.StringBuilder ();
    sb.append ("Hello");
    assert (sb.toString () == "Hello");

    sb.append (" World");
    assert (sb.toString () == "Hello World");

    /* Append empty string */
    sb.append ("");
    assert (sb.toString () == "Hello World");
}

void testAppendChaining () {
    var sb = new Vala.Io.StringBuilder ();
    var result = sb.append ("a").append ("b").append ("c");
    assert (result.toString () == "abc");
}

void testAppendLine () {
    var sb = new Vala.Io.StringBuilder ();
    sb.appendLine ("line1");
    sb.appendLine ("line2");
    assert (sb.toString () == "line1\nline2\n");
}

void testAppendChar () {
    var sb = new Vala.Io.StringBuilder ();
    sb.appendChar ('A');
    sb.appendChar ('B');
    sb.appendChar ('C');
    assert (sb.toString () == "ABC");
}

void testInsert () {
    var sb = new Vala.Io.StringBuilder.withString ("HelloWorld");
    sb.insert (5, ", ");
    assert (sb.toString () == "Hello, World");

    /* Insert at beginning */
    var sb2 = new Vala.Io.StringBuilder.withString ("World");
    sb2.insert (0, "Hello ");
    assert (sb2.toString () == "Hello World");

    /* Insert at end */
    var sb3 = new Vala.Io.StringBuilder.withString ("Hello");
    sb3.insert (5, " World");
    assert (sb3.toString () == "Hello World");
}

void testInsertBoundary () {
    var sb = new Vala.Io.StringBuilder.withString ("abc");

    /* Negative offset ignored */
    sb.insert (-1, "x");
    assert (sb.toString () == "abc");

    /* Offset beyond length ignored */
    sb.insert (100, "x");
    assert (sb.toString () == "abc");
}

void testDeleteRange () {
    var sb = new Vala.Io.StringBuilder.withString ("Hello, World");
    sb.deleteRange (5, 7);
    assert (sb.toString () == "HelloWorld");

    /* Delete from beginning */
    var sb2 = new Vala.Io.StringBuilder.withString ("Hello World");
    sb2.deleteRange (0, 6);
    assert (sb2.toString () == "World");

    /* Delete to end */
    var sb3 = new Vala.Io.StringBuilder.withString ("Hello World");
    sb3.deleteRange (5, 11);
    assert (sb3.toString () == "Hello");
}

void testDeleteRangeBoundary () {
    var sb = new Vala.Io.StringBuilder.withString ("abc");

    /* Negative start ignored */
    sb.deleteRange (-1, 2);
    assert (sb.toString () == "abc");

    /* Start > end ignored */
    sb.deleteRange (2, 1);
    assert (sb.toString () == "abc");

    /* Start beyond length ignored */
    sb.deleteRange (100, 200);
    assert (sb.toString () == "abc");

    /* End beyond length truncated to length */
    sb.deleteRange (1, 100);
    assert (sb.toString () == "a");
}

void testReplaceRange () {
    var sb = new Vala.Io.StringBuilder.withString ("Hello World");
    sb.replaceRange (6, 11, "Vala");
    assert (sb.toString () == "Hello Vala");

    /* Replace with shorter */
    var sb2 = new Vala.Io.StringBuilder.withString ("abcdef");
    sb2.replaceRange (2, 5, "X");
    assert (sb2.toString () == "abXf");

    /* Replace with longer */
    var sb3 = new Vala.Io.StringBuilder.withString ("abc");
    sb3.replaceRange (1, 2, "XYZ");
    assert (sb3.toString () == "aXYZc");
}

void testReplaceRangeBoundary () {
    var sb = new Vala.Io.StringBuilder.withString ("abc");

    /* Negative start ignored */
    sb.replaceRange (-1, 2, "X");
    assert (sb.toString () == "abc");

    /* Start > end ignored */
    sb.replaceRange (2, 1, "X");
    assert (sb.toString () == "abc");

    /* End beyond length truncated */
    sb.replaceRange (1, 100, "X");
    assert (sb.toString () == "aX");
}

void testReverse () {
    var sb = new Vala.Io.StringBuilder.withString ("abc");
    sb.reverse ();
    assert (sb.toString () == "cba");

    /* Empty string */
    var sb2 = new Vala.Io.StringBuilder ();
    sb2.reverse ();
    assert (sb2.toString () == "");

    /* Single char */
    var sb3 = new Vala.Io.StringBuilder.withString ("x");
    sb3.reverse ();
    assert (sb3.toString () == "x");
}

void testLength () {
    var sb = new Vala.Io.StringBuilder ();
    assert (sb.length () == 0);

    sb.append ("Hello");
    assert (sb.length () == 5);

    sb.append (" World");
    assert (sb.length () == 11);

    sb.clear ();
    assert (sb.length () == 0);
}

void testCharAt () {
    var sb = new Vala.Io.StringBuilder.withString ("Hello");
    assert (sb.charAt (0) == 'H');
    assert (sb.charAt (1) == 'e');
    assert (sb.charAt (4) == 'o');
}

void testCharAtBoundary () {
    var sb = new Vala.Io.StringBuilder.withString ("abc");

    /* Negative index returns null char */
    assert (sb.charAt (-1) == '\0');

    /* Out of range returns null char */
    assert (sb.charAt (3) == '\0');
    assert (sb.charAt (100) == '\0');
}

void testClear () {
    var sb = new Vala.Io.StringBuilder.withString ("data");
    sb.clear ();
    assert (sb.length () == 0);
    assert (sb.toString () == "");

    /* Can reuse after clear */
    sb.append ("new data");
    assert (sb.toString () == "new data");
}

void testToString () {
    var sb = new Vala.Io.StringBuilder ();
    assert (sb.toString () == "");

    sb.append ("hello");
    assert (sb.toString () == "hello");
}

void testCapacity () {
    var sb = new Vala.Io.StringBuilder.sized (256);
    assert (sb.capacity () >= 256);

    /* Default constructor also has some capacity */
    var sb2 = new Vala.Io.StringBuilder ();
    assert (sb2.capacity () >= 0);
}

void testInstantiation () {
    var sb = new Vala.Io.StringBuilder ();
    assert (sb != null);
}
