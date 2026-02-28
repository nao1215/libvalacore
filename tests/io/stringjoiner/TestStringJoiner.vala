using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testBasicJoin", testBasicJoin);
    Test.add_func ("/testWithPrefixSuffix", testWithPrefixSuffix);
    Test.add_func ("/testSingleElement", testSingleElement);
    Test.add_func ("/testEmptyNoElements", testEmptyNoElements);
    Test.add_func ("/testEmptyValue", testEmptyValue);
    Test.add_func ("/testAddChaining", testAddChaining);
    Test.add_func ("/testMerge", testMerge);
    Test.add_func ("/testMergeEmpty", testMergeEmpty);
    Test.add_func ("/testLength", testLength);
    Test.add_func ("/testLengthEmpty", testLengthEmpty);
    Test.add_func ("/testEmptyDelimiter", testEmptyDelimiter);
    Test.add_func ("/testSetEmptyValueChaining", testSetEmptyValueChaining);
    Test.add_func ("/testMergeChaining", testMergeChaining);
    Test.run ();
}

void testBasicJoin () {
    var joiner = new StringJoiner (", ");
    joiner.add ("a");
    joiner.add ("b");
    joiner.add ("c");
    assert (joiner.toString () == "a, b, c");
}

void testWithPrefixSuffix () {
    var joiner = new StringJoiner (", ", "[", "]");
    joiner.add ("a");
    joiner.add ("b");
    joiner.add ("c");
    assert (joiner.toString () == "[a, b, c]");
}

void testSingleElement () {
    var joiner = new StringJoiner (", ", "(", ")");
    joiner.add ("only");
    assert (joiner.toString () == "(only)");
}

void testEmptyNoElements () {
    var joiner = new StringJoiner (", ", "[", "]");
    assert (joiner.toString () == "[]");
}

void testEmptyValue () {
    var joiner = new StringJoiner (", ", "[", "]");
    joiner.setEmptyValue ("EMPTY");
    assert (joiner.toString () == "EMPTY");

    /* After adding elements, emptyValue is not used */
    joiner.add ("x");
    assert (joiner.toString () == "[x]");
}

void testAddChaining () {
    var joiner = new StringJoiner ("-");
    var result = joiner.add ("a").add ("b").add ("c");
    assert (result.toString () == "a-b-c");
}

void testMerge () {
    var j1 = new StringJoiner (", ", "[", "]");
    j1.add ("a");

    var j2 = new StringJoiner ("-");
    j2.add ("b");
    j2.add ("c");

    j1.merge (j2);
    assert (j1.toString () == "[a, b-c]");
}

void testMergeEmpty () {
    var j1 = new StringJoiner (", ");
    j1.add ("a");

    var j2 = new StringJoiner ("-");
    /* j2 has no elements */

    j1.merge (j2);
    assert (j1.toString () == "a");
}

void testLength () {
    var joiner = new StringJoiner (", ", "[", "]");
    joiner.add ("ab");
    /* "[ab]" = 4 */
    assert (joiner.length () == 4);

    joiner.add ("cd");
    /* "[ab, cd]" = 8 */
    assert (joiner.length () == 8);
}

void testLengthEmpty () {
    var joiner = new StringJoiner (", ", "[", "]");
    /* "[]" = 2 */
    assert (joiner.length () == 2);

    joiner.setEmptyValue ("NONE");
    /* "NONE" = 4 */
    assert (joiner.length () == 4);
}

void testEmptyDelimiter () {
    var joiner = new StringJoiner ("");
    joiner.add ("a");
    joiner.add ("b");
    joiner.add ("c");
    assert (joiner.toString () == "abc");
}

void testSetEmptyValueChaining () {
    var joiner = new StringJoiner (", ");
    var result = joiner.setEmptyValue ("N/A");
    assert (result.toString () == "N/A");
}

void testMergeChaining () {
    var j1 = new StringJoiner (", ");
    j1.add ("a");

    var j2 = new StringJoiner ("-");
    j2.add ("b");

    var j3 = new StringJoiner (":");
    j3.add ("c");

    j1.merge (j2).merge (j3);
    assert (j1.toString () == "a, b, c");
}
