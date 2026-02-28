using Vala.Crypto;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/uuid/testV4", testV4);
    Test.add_func ("/uuid/testParseValid", testParseValid);
    Test.add_func ("/uuid/testParseUpperCase", testParseUpperCase);
    Test.add_func ("/uuid/testParseInvalid", testParseInvalid);
    Test.run ();
}

void testV4 () {
    Vala.Crypto.Uuid uuid = Vala.Crypto.Uuid.v4 ();
    string text = uuid.toString ();
    assert (GLib.Uuid.string_is_valid (text) == true);
    assert (text.substring (14, 1) == "4");

    string variant = text.substring (19, 1).down ();
    assert (variant == "8" || variant == "9" || variant == "a" || variant == "b");
}

void testParseValid () {
    Vala.Crypto.Uuid ? uuid = Vala.Crypto.Uuid.parse ("550e8400-e29b-41d4-a716-446655440000");
    assert (uuid != null);
    assert (uuid.toString () == "550e8400-e29b-41d4-a716-446655440000");
}

void testParseUpperCase () {
    Vala.Crypto.Uuid ? uuid = Vala.Crypto.Uuid.parse ("550E8400-E29B-41D4-A716-446655440000");
    assert (uuid != null);
    assert (uuid.toString () == "550e8400-e29b-41d4-a716-446655440000");
}

void testParseInvalid () {
    assert (Vala.Crypto.Uuid.parse ("") == null);
    assert (Vala.Crypto.Uuid.parse ("not-a-uuid") == null);
    assert (Vala.Crypto.Uuid.parse ("550e8400-e29b-41d4-a716-44665544zzzz") == null);
}
