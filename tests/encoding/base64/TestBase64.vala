using Vala.Encoding;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/base64/testEncode", testEncode);
    Test.add_func ("/base64/testDecode", testDecode);
    Test.add_func ("/base64/testEncodeString", testEncodeString);
    Test.add_func ("/base64/testDecodeString", testDecodeString);
    Test.add_func ("/base64/testEmpty", testEmpty);
    Test.run ();
}

void testEncode () {
    uint8[] data = { 0x48, 0x65, 0x6C, 0x6C, 0x6F };
    assert (Vala.Encoding.Base64.encode (data) == "SGVsbG8=");
}

void testDecode () {
    uint8[] decoded = Vala.Encoding.Base64.decode ("SGVsbG8=");
    assert (decoded.length == 5);
    assert (decoded[0] == 0x48);
    assert (decoded[1] == 0x65);
    assert (decoded[2] == 0x6C);
    assert (decoded[3] == 0x6C);
    assert (decoded[4] == 0x6F);
}

void testEncodeString () {
    assert (Vala.Encoding.Base64.encodeString ("hello") == "aGVsbG8=");
}

void testDecodeString () {
    assert (Vala.Encoding.Base64.decodeString ("aGVsbG8=") == "hello");
}

void testEmpty () {
    uint8[] empty = {};
    assert (Vala.Encoding.Base64.encode (empty) == "");
    assert (Vala.Encoding.Base64.decode ("").length == 0);
    assert (Vala.Encoding.Base64.decodeString ("") == "");
}
