using Core;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testIsNullOrEmpty", testIsNullOrEmpty);
    Test.add_func ("/testTrimSpace", testTrimSpace);
    Test.run ();
}

void testIsNullOrEmpty () {
    string str = null;
    assert (Strings.isNullOrEmpty (str) == true);
    assert (Strings.isNullOrEmpty ("") == true);
    assert (Strings.isNullOrEmpty ("test") == false);
}

void testTrimSpace () {
    assert (Strings.trimSpace ("   Dungeon of regalias    ") == "Dungeon of regalias");
    assert (Strings.trimSpace (" \t  Dungeon of regalias") == "Dungeon of regalias");
    assert (Strings.trimSpace ("Dungeon of regalias  \t  ") == "Dungeon of regalias");
    assert (Strings.trimSpace ("Dungeon of regalias") == "Dungeon of regalias");
}