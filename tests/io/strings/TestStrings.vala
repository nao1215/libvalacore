using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testIsNullOrEmpty", testIsNullOrEmpty);
    Test.add_func ("/testIsBlank", testIsBlank);
    Test.add_func ("/testIsNumeric", testIsNumeric);
    Test.add_func ("/testIsAlpha", testIsAlpha);
    Test.add_func ("/testIsAlphaNumeric", testIsAlphaNumeric);
    Test.add_func ("/testTrimSpace", testTrimSpace);
    Test.add_func ("/testTrimLeft", testTrimLeft);
    Test.add_func ("/testTrimRight", testTrimRight);
    Test.add_func ("/testTrimPrefix", testTrimPrefix);
    Test.add_func ("/testTrimSuffix", testTrimSuffix);
    Test.add_func ("/testContains", testContains);
    Test.add_func ("/testStartsWith", testStartsWith);
    Test.add_func ("/testEndsWith", testEndsWith);
    Test.add_func ("/testToUpperCase", testToUpperCase);
    Test.add_func ("/testToLowerCase", testToLowerCase);
    Test.add_func ("/testReplace", testReplace);
    Test.add_func ("/testRepeat", testRepeat);
    Test.add_func ("/testReverse", testReverse);
    Test.add_func ("/testPadLeft", testPadLeft);
    Test.add_func ("/testPadRight", testPadRight);
    Test.add_func ("/testCenter", testCenter);
    Test.add_func ("/testIndexOf", testIndexOf);
    Test.add_func ("/testLastIndexOf", testLastIndexOf);
    Test.add_func ("/testCount", testCount);
    Test.add_func ("/testJoin", testJoin);
    Test.add_func ("/testSplit", testSplit);
    Test.add_func ("/testSubstring", testSubstring);
    Test.add_func ("/testCapitalize", testCapitalize);
    Test.add_func ("/testToCamelCase", testToCamelCase);
    Test.add_func ("/testToSnakeCase", testToSnakeCase);
    Test.add_func ("/testToKebabCase", testToKebabCase);
    Test.add_func ("/testToPascalCase", testToPascalCase);
    Test.add_func ("/testTitle", testTitle);
    Test.add_func ("/testCompareTo", testCompareTo);
    Test.add_func ("/testCompareIgnoreCase", testCompareIgnoreCase);
    Test.add_func ("/testEqualsIgnoreCase", testEqualsIgnoreCase);
    Test.add_func ("/testLines", testLines);
    Test.add_func ("/testWords", testWords);
    Test.add_func ("/testTruncate", testTruncate);
    Test.add_func ("/testWrap", testWrap);
    Test.run ();
}

void testIsNullOrEmpty () {
    string str = null;
    assert (Strings.isNullOrEmpty (str) == true);
    assert (Strings.isNullOrEmpty ("") == true);
    assert (Strings.isNullOrEmpty ("test") == false);
    assert (Strings.isNullOrEmpty (" ") == false);
}

void testIsBlank () {
    string nullStr = null;
    assert (Strings.isBlank (nullStr) == true);
    assert (Strings.isBlank ("") == true);
    assert (Strings.isBlank ("   ") == true);
    assert (Strings.isBlank (" \t \n ") == true);
    assert (Strings.isBlank (" hi ") == false);
    assert (Strings.isBlank ("a") == false);
}

void testIsNumeric () {
    string nullStr = null;
    assert (Strings.isNumeric (nullStr) == false);
    assert (Strings.isNumeric ("") == false);
    assert (Strings.isNumeric ("12345") == true);
    assert (Strings.isNumeric ("0") == true);
    assert (Strings.isNumeric ("12.3") == false);
    assert (Strings.isNumeric ("12a") == false);
    assert (Strings.isNumeric ("-1") == false);
}

void testIsAlpha () {
    string nullStr = null;
    assert (Strings.isAlpha (nullStr) == false);
    assert (Strings.isAlpha ("") == false);
    assert (Strings.isAlpha ("Hello") == true);
    assert (Strings.isAlpha ("abc") == true);
    assert (Strings.isAlpha ("ABC") == true);
    assert (Strings.isAlpha ("Hello1") == false);
    assert (Strings.isAlpha ("Hello World") == false);
}

void testIsAlphaNumeric () {
    string nullStr = null;
    assert (Strings.isAlphaNumeric (nullStr) == false);
    assert (Strings.isAlphaNumeric ("") == false);
    assert (Strings.isAlphaNumeric ("Hello123") == true);
    assert (Strings.isAlphaNumeric ("abc") == true);
    assert (Strings.isAlphaNumeric ("123") == true);
    assert (Strings.isAlphaNumeric ("Hello 123") == false);
    assert (Strings.isAlphaNumeric ("abc!") == false);
}

void testTrimSpace () {
    assert (Strings.trimSpace ("   Dungeon of regalias    ") == "Dungeon of regalias");
    assert (Strings.trimSpace (" \t  Dungeon of regalias") == "Dungeon of regalias");
    assert (Strings.trimSpace ("Dungeon of regalias  \t  ") == "Dungeon of regalias");
    assert (Strings.trimSpace ("Dungeon of regalias") == "Dungeon of regalias");
}

void testTrimLeft () {
    string nullStr = null;
    assert (Strings.trimLeft (nullStr, "x") == "");
    assert (Strings.trimLeft ("", "x") == "");
    assert (Strings.trimLeft ("xxyhello", "xy") == "hello");
    assert (Strings.trimLeft ("hello", "xy") == "hello");
    assert (Strings.trimLeft ("xxx", "x") == "");
}

void testTrimRight () {
    string nullStr = null;
    assert (Strings.trimRight (nullStr, "x") == "");
    assert (Strings.trimRight ("", "x") == "");
    assert (Strings.trimRight ("helloxyy", "xy") == "hello");
    assert (Strings.trimRight ("hello", "xy") == "hello");
    assert (Strings.trimRight ("xxx", "x") == "");
}

void testTrimPrefix () {
    string nullStr = null;
    assert (Strings.trimPrefix (nullStr, "x") == "");
    assert (Strings.trimPrefix ("", "x") == "");
    assert (Strings.trimPrefix ("HelloWorld", "Hello") == "World");
    assert (Strings.trimPrefix ("HelloWorld", "Bye") == "HelloWorld");
    assert (Strings.trimPrefix ("Hello", "Hello") == "");
}

void testTrimSuffix () {
    string nullStr = null;
    assert (Strings.trimSuffix (nullStr, "x") == "");
    assert (Strings.trimSuffix ("", "x") == "");
    assert (Strings.trimSuffix ("HelloWorld", "World") == "Hello");
    assert (Strings.trimSuffix ("HelloWorld", "Bye") == "HelloWorld");
    assert (Strings.trimSuffix ("Hello", "Hello") == "");
}

void testContains () {
    string nullStr = null;
    assert (Strings.contains (nullStr, nullStr) == false);
    assert (Strings.contains ("Dungeon of regalias", nullStr) == false);
    assert (Strings.contains (nullStr, "Dungeon of regalias") == false);
    assert (Strings.contains ("Dungeon of regalias", "") == false);
    assert (Strings.contains ("", "Dungeon of regalias") == false);
    assert (Strings.contains ("Dungeon of regalias", "geon") == true);
}

void testStartsWith () {
    string nullStr = null;
    assert (Strings.startsWith (nullStr, "x") == false);
    assert (Strings.startsWith ("", "x") == false);
    assert (Strings.startsWith ("hello", nullStr) == false);
    assert (Strings.startsWith ("HelloWorld", "Hello") == true);
    assert (Strings.startsWith ("HelloWorld", "World") == false);
    assert (Strings.startsWith ("Hello", "Hello") == true);
}

void testEndsWith () {
    string nullStr = null;
    assert (Strings.endsWith (nullStr, "x") == false);
    assert (Strings.endsWith ("", "x") == false);
    assert (Strings.endsWith ("hello", nullStr) == false);
    assert (Strings.endsWith ("HelloWorld", "World") == true);
    assert (Strings.endsWith ("HelloWorld", "Hello") == false);
    assert (Strings.endsWith ("World", "World") == true);
}

void testToUpperCase () {
    string nullStr = null;
    assert (Strings.toUpperCase (nullStr) == "");
    assert (Strings.toUpperCase ("") == "");
    assert (Strings.toUpperCase ("hello") == "HELLO");
    assert (Strings.toUpperCase ("Hello World") == "HELLO WORLD");
    assert (Strings.toUpperCase ("HELLO") == "HELLO");
}

void testToLowerCase () {
    string nullStr = null;
    assert (Strings.toLowerCase (nullStr) == "");
    assert (Strings.toLowerCase ("") == "");
    assert (Strings.toLowerCase ("HELLO") == "hello");
    assert (Strings.toLowerCase ("Hello World") == "hello world");
    assert (Strings.toLowerCase ("hello") == "hello");
}

void testReplace () {
    string nullStr = null;
    assert (Strings.replace (nullStr, "a", "b") == "");
    assert (Strings.replace ("", "a", "b") == "");
    assert (Strings.replace ("hello world", "world", "vala") == "hello vala");
    assert (Strings.replace ("aaa", "a", "bb") == "bbbbbb");
    assert (Strings.replace ("hello", "xyz", "abc") == "hello");
}

void testRepeat () {
    string nullStr = null;
    assert (Strings.repeat (nullStr, 3) == "");
    assert (Strings.repeat ("", 3) == "");
    assert (Strings.repeat ("ab", 3) == "ababab");
    assert (Strings.repeat ("x", 1) == "x");
    assert (Strings.repeat ("x", 0) == "");
    assert (Strings.repeat ("x", -1) == "");
}

void testReverse () {
    string nullStr = null;
    assert (Strings.reverse (nullStr) == "");
    assert (Strings.reverse ("") == "");
    assert (Strings.reverse ("hello") == "olleh");
    assert (Strings.reverse ("a") == "a");
    assert (Strings.reverse ("ab") == "ba");
}

void testPadLeft () {
    string nullStr = null;
    assert (Strings.padLeft (nullStr, 5, '0') == "00000");
    assert (Strings.padLeft ("42", 5, '0') == "00042");
    assert (Strings.padLeft ("hello", 5, '0') == "hello");
    assert (Strings.padLeft ("hello", 3, '0') == "hello");
    assert (Strings.padLeft ("", 3, 'x') == "xxx");
}

void testPadRight () {
    string nullStr = null;
    assert (Strings.padRight (nullStr, 5, '.') == ".....");
    assert (Strings.padRight ("hi", 5, '.') == "hi...");
    assert (Strings.padRight ("hello", 5, '.') == "hello");
    assert (Strings.padRight ("hello", 3, '.') == "hello");
    assert (Strings.padRight ("", 3, 'x') == "xxx");
}

void testCenter () {
    string nullStr = null;
    assert (Strings.center (nullStr, 5, '*') == "*****");
    assert (Strings.center ("hi", 6, '*') == "**hi**");
    assert (Strings.center ("hi", 7, '*') == "**hi***");
    assert (Strings.center ("hello", 5, '*') == "hello");
    assert (Strings.center ("hello", 3, '*') == "hello");
}

void testIndexOf () {
    string nullStr = null;
    assert (Strings.indexOf (nullStr, "x") == -1);
    assert (Strings.indexOf ("", "x") == -1);
    assert (Strings.indexOf ("hello", nullStr) == -1);
    assert (Strings.indexOf ("hello world", "world") == 6);
    assert (Strings.indexOf ("hello", "xyz") == -1);
    assert (Strings.indexOf ("hello", "hello") == 0);
}

void testLastIndexOf () {
    string nullStr = null;
    assert (Strings.lastIndexOf (nullStr, "x") == -1);
    assert (Strings.lastIndexOf ("", "x") == -1);
    assert (Strings.lastIndexOf ("hello", nullStr) == -1);
    assert (Strings.lastIndexOf ("hello hello", "hello") == 6);
    assert (Strings.lastIndexOf ("hello", "xyz") == -1);
    assert (Strings.lastIndexOf ("abcabc", "abc") == 3);
}

void testCount () {
    string nullStr = null;
    assert (Strings.count (nullStr, "x") == 0);
    assert (Strings.count ("", "x") == 0);
    assert (Strings.count ("hello", nullStr) == 0);
    assert (Strings.count ("abcabc", "abc") == 2);
    assert (Strings.count ("hello", "xyz") == 0);
    assert (Strings.count ("aaa", "a") == 3);
    assert (Strings.count ("aaaa", "aa") == 2);
}

void testJoin () {
    assert (Strings.join (", ", {"a", "b", "c"}) == "a, b, c");
    assert (Strings.join ("-", {"hello"}) == "hello");
    assert (Strings.join (",", {}) == "");
}

void testSplit () {
    string nullStr = null;
    string[] empty = Strings.split (nullStr, ",");
    assert (empty.length == 0);

    string[] parts = Strings.split ("a,b,c", ",");
    assert (parts.length == 3);
    assert (parts[0] == "a");
    assert (parts[1] == "b");
    assert (parts[2] == "c");

    string[] single = Strings.split ("hello", ",");
    assert (single.length == 1);
    assert (single[0] == "hello");
}

void testSubstring () {
    string nullStr = null;
    assert (Strings.substring (nullStr, 0, 5) == "");
    assert (Strings.substring ("", 0, 5) == "");
    assert (Strings.substring ("hello world", 0, 5) == "hello");
    assert (Strings.substring ("hello world", 6, 11) == "world");
    assert (Strings.substring ("hello", -1, 3) == "hel");
    assert (Strings.substring ("hello", 0, 100) == "hello");
    assert (Strings.substring ("hello", 3, 2) == "");
}

void testCapitalize () {
    string nullStr = null;
    assert (Strings.capitalize (nullStr) == "");
    assert (Strings.capitalize ("") == "");
    assert (Strings.capitalize ("hello") == "Hello");
    assert (Strings.capitalize ("Hello") == "Hello");
    assert (Strings.capitalize ("h") == "H");
    assert (Strings.capitalize ("a long sentence") == "A long sentence");
}

void testToCamelCase () {
    string nullStr = null;
    assert (Strings.toCamelCase (nullStr) == "");
    assert (Strings.toCamelCase ("") == "");
    assert (Strings.toCamelCase ("hello_world") == "helloWorld");
    assert (Strings.toCamelCase ("Hello World") == "helloWorld");
    assert (Strings.toCamelCase ("hello-world") == "helloWorld");
    assert (Strings.toCamelCase ("hello") == "hello");
}

void testToSnakeCase () {
    string nullStr = null;
    assert (Strings.toSnakeCase (nullStr) == "");
    assert (Strings.toSnakeCase ("") == "");
    assert (Strings.toSnakeCase ("helloWorld") == "hello_world");
    assert (Strings.toSnakeCase ("HelloWorld") == "hello_world");
    assert (Strings.toSnakeCase ("hello-world") == "hello_world");
    assert (Strings.toSnakeCase ("hello") == "hello");
}

void testToKebabCase () {
    string nullStr = null;
    assert (Strings.toKebabCase (nullStr) == "");
    assert (Strings.toKebabCase ("") == "");
    assert (Strings.toKebabCase ("helloWorld") == "hello-world");
    assert (Strings.toKebabCase ("Hello World") == "hello-world");
}

void testToPascalCase () {
    string nullStr = null;
    assert (Strings.toPascalCase (nullStr) == "");
    assert (Strings.toPascalCase ("") == "");
    assert (Strings.toPascalCase ("hello_world") == "HelloWorld");
    assert (Strings.toPascalCase ("hello world") == "HelloWorld");
}

void testTitle () {
    string nullStr = null;
    assert (Strings.title (nullStr) == "");
    assert (Strings.title ("") == "");
    assert (Strings.title ("hello world") == "Hello World");
    assert (Strings.title ("hello") == "Hello");
    assert (Strings.title ("HELLO WORLD") == "HELLO WORLD");
}

void testCompareTo () {
    string nullStr = null;
    assert (Strings.compareTo (nullStr, nullStr) == 0);
    assert (Strings.compareTo (nullStr, "a") < 0);
    assert (Strings.compareTo ("a", nullStr) > 0);
    assert (Strings.compareTo ("abc", "abc") == 0);
    assert (Strings.compareTo ("abc", "abd") < 0);
    assert (Strings.compareTo ("abd", "abc") > 0);
}

void testCompareIgnoreCase () {
    string nullStr = null;
    assert (Strings.compareIgnoreCase (nullStr, nullStr) == 0);
    assert (Strings.compareIgnoreCase (nullStr, "a") < 0);
    assert (Strings.compareIgnoreCase ("a", nullStr) > 0);
    assert (Strings.compareIgnoreCase ("ABC", "abc") == 0);
    assert (Strings.compareIgnoreCase ("abc", "ABD") < 0);
}

void testEqualsIgnoreCase () {
    string nullStr = null;
    assert (Strings.equalsIgnoreCase (nullStr, nullStr) == true);
    assert (Strings.equalsIgnoreCase ("Hello", "hello") == true);
    assert (Strings.equalsIgnoreCase ("Hello", "World") == false);
}

void testLines () {
    string nullStr = null;
    assert (Strings.lines (nullStr).length == 0);
    assert (Strings.lines ("").length == 0);

    string[] result = Strings.lines ("a\nb\nc");
    assert (result.length == 3);
    assert (result[0] == "a");
    assert (result[1] == "b");
    assert (result[2] == "c");

    string[] single = Strings.lines ("hello");
    assert (single.length == 1);
    assert (single[0] == "hello");
}

void testWords () {
    string nullStr = null;
    assert (Strings.words (nullStr).length == 0);
    assert (Strings.words ("").length == 0);

    string[] result = Strings.words ("  hello   world  ");
    assert (result.length == 2);
    assert (result[0] == "hello");
    assert (result[1] == "world");

    string[] single = Strings.words ("hello");
    assert (single.length == 1);
    assert (single[0] == "hello");
}

void testTruncate () {
    string nullStr = null;
    assert (Strings.truncate (nullStr, 5, "...") == "");
    assert (Strings.truncate ("", 5, "...") == "");
    assert (Strings.truncate ("Hello World", 8, "...") == "Hello...");
    assert (Strings.truncate ("Hello", 10, "...") == "Hello");
    assert (Strings.truncate ("Hello", 5, "...") == "Hello");
    assert (Strings.truncate ("Hello World", 3, "...") == "...");
}

void testWrap () {
    string nullStr = null;
    assert (Strings.wrap (nullStr, 3) == "");
    assert (Strings.wrap ("", 3) == "");
    assert (Strings.wrap ("abcdef", 3) == "abc\ndef");
    assert (Strings.wrap ("ab", 5) == "ab");
    assert (Strings.wrap ("abcdefghi", 3) == "abc\ndef\nghi");
}
