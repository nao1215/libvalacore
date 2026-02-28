using Vala.Regex;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/regex/pattern/testCompile", testCompile);
    Test.add_func ("/regex/pattern/testMatchesAndFind", testMatchesAndFind);
    Test.add_func ("/regex/pattern/testFindAll", testFindAll);
    Test.add_func ("/regex/pattern/testReplace", testReplace);
    Test.add_func ("/regex/pattern/testReplaceNamedGroup", testReplaceNamedGroup);
    Test.add_func ("/regex/pattern/testSplit", testSplit);
    Test.add_func ("/regex/pattern/testGroups", testGroups);
    Test.run ();
}

void testCompile () {
    Pattern ? ok = Pattern.compile ("\\d+");
    Pattern ? ng = Pattern.compile ("(");

    assert (ok != null);
    assert (ng == null);
}

void testMatchesAndFind () {
    Pattern ? p = Pattern.compile ("[a-z]+");
    assert (p != null);

    assert (p.matches ("abc") == true);
    assert (p.matches ("abc1") == false);
    assert (p.find ("abc1") == true);
    assert (p.find ("123") == false);
}

void testFindAll () {
    Pattern ? p = Pattern.compile ("\\d+");
    assert (p != null);

    string[] matches = p.findAll ("a1b22c333");
    assert (matches.length == 3);
    assert (matches[0] == "1");
    assert (matches[1] == "22");
    assert (matches[2] == "333");
}

void testReplace () {
    Pattern ? p = Pattern.compile ("\\d+");
    assert (p != null);

    assert (p.replaceFirst ("a1b22", "X") == "aXb22");
    assert (p.replaceAll ("a1b22", "X") == "aXbX");

    Pattern ? groups = Pattern.compile ("(\\d+)");
    assert (groups != null);
    assert (groups.replaceFirst ("a1b22", "[\\1]") == "a[1]b22");
    assert (groups.replaceAll ("a1b22", "[\\1]") == "a[1]b[22]");
}

void testReplaceNamedGroup () {
    Pattern ? p = Pattern.compile ("(?P<num>\\d+)");
    assert (p != null);
    assert (p.replaceFirst ("a1b22", "[\\g<num>]") == "a[1]b22");
    assert (p.replaceAll ("a1b22", "[\\g<num>]") == "a[1]b[22]");
}

void testSplit () {
    Pattern ? p = Pattern.compile (",\\s*");
    assert (p != null);

    string[] values = p.split ("a, b,c");
    assert (values.length == 3);
    assert (values[0] == "a");
    assert (values[1] == "b");
    assert (values[2] == "c");
}

void testGroups () {
    Pattern ? p = Pattern.compile ("(\\d+)-(\\w+)");
    assert (p != null);

    string[] groups = p.groups ("12-ab");
    assert (groups.length == 2);
    assert (groups[0] == "12");
    assert (groups[1] == "ab");

    string[] empty = p.groups ("xx");
    assert (empty.length == 0);
}
