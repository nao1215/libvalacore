using Vala.Encoding;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/hex/testEncode", testEncode);
    Test.add_func ("/hex/testDecode", testDecode);
    Test.add_func ("/hex/testDecodeUpperCase", testDecodeUpperCase);
    Test.add_func ("/hex/testEmpty", testEmpty);
    Test.add_func ("/hex/testInvalid", testInvalid);
    Test.run ();
}

void testEncode () {
    uint8[] data = { 0x48, 0x65, 0x6C, 0x6C, 0x6F };
    assert (Hex.encode (data) == "48656c6c6f");
}

void assertHelloBytes (uint8[] decoded) {
    assert (decoded.length == 5);
    assert (decoded[0] == 0x48);
    assert (decoded[1] == 0x65);
    assert (decoded[2] == 0x6C);
    assert (decoded[3] == 0x6C);
    assert (decoded[4] == 0x6F);
}

void testDecode () {
    uint8[] decoded = Hex.decode ("48656c6c6f");
    assertHelloBytes (decoded);
}

void testDecodeUpperCase () {
    uint8[] decoded = Hex.decode ("48656C6C6F");
    assertHelloBytes (decoded);
}

void testEmpty () {
    uint8[] empty = {};
    assert (Hex.encode (empty) == "");
    assert (Hex.decode ("").length == 0);
}

void testInvalid () {
    assert (Hex.decode ("0").length == 0);
    assert (Hex.decode ("GG").length == 0);
}
