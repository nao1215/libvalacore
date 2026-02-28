using Vala.Text;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/regex/testMatches", testMatches);
    Test.add_func ("/regex/testMatchesInvalidPattern", testMatchesInvalidPattern);
    Test.add_func ("/regex/testReplaceAll", testReplaceAll);
    Test.add_func ("/regex/testReplaceAllInvalidPattern", testReplaceAllInvalidPattern);
    Test.add_func ("/regex/testSplit", testSplit);
    Test.add_func ("/regex/testSplitInvalidPattern", testSplitInvalidPattern);
    Test.run ();
}

void testMatches () {
    assert (Vala.Text.Regex.matches ("abc123", "^[a-z]+[0-9]+$") == true);
    assert (Vala.Text.Regex.matches ("abc", "^[0-9]+$") == false);
}

void testMatchesInvalidPattern () {
    assert (Vala.Text.Regex.matches ("abc", "(") == false);
}

void testReplaceAll () {
    string replaced = Vala.Text.Regex.replaceAll ("abc123def456", "[0-9]+", "#");
    assert (replaced == "abc#def#");
}

void testReplaceAllInvalidPattern () {
    string original = "abc123";
    assert (Vala.Text.Regex.replaceAll (original, "(", "#") == original);
}

void testSplit () {
    string[] parts = Vala.Text.Regex.split ("a,b,,c", ",");
    assert (parts.length == 4);
    assert (parts[0] == "a");
    assert (parts[1] == "b");
    assert (parts[2] == "");
    assert (parts[3] == "c");
}

void testSplitInvalidPattern () {
    string[] parts = Vala.Text.Regex.split ("a,b,c", "(");
    assert (parts.length == 0);
}
