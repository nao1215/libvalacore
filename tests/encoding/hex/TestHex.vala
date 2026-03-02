using Vala.Encoding;
using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/hex/testConstruct", testConstruct);
    Test.add_func ("/hex/testEncode", testEncode);
    Test.add_func ("/hex/testDecode", testDecode);
    Test.add_func ("/hex/testDecodeUpperCase", testDecodeUpperCase);
    Test.add_func ("/hex/testEmpty", testEmpty);
    Test.add_func ("/hex/testInvalid", testInvalid);
    Test.run ();
}

void testConstruct () {
    var codec = new Hex ();
    assert (codec != null);
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

uint8[] copyBytes (GLib.Bytes bytes) {
    uint8[] raw = bytes.get_data ();
    uint8[] copied = new uint8[raw.length];
    for (int i = 0; i < raw.length; i++) {
        copied[i] = raw[i];
    }
    return copied;
}

uint8[] unwrapBytes (Result<GLib.Bytes, GLib.Error> result) {
    assert (result.isOk ());
    return copyBytes (result.unwrap ());
}

void testDecode () {
    uint8[] decoded = unwrapBytes (Hex.decode ("48656c6c6f"));
    assertHelloBytes (decoded);
}

void testDecodeUpperCase () {
    uint8[] decoded = unwrapBytes (Hex.decode ("48656C6C6F"));
    assertHelloBytes (decoded);
}

void testEmpty () {
    uint8[] empty = {};
    assert (Hex.encode (empty) == "");
    uint8[] decoded = unwrapBytes (Hex.decode (""));
    assert (decoded.length == 0);
}

void testInvalid () {
    var odd = Hex.decode ("0");
    assert (odd.isError ());
    assert (odd.unwrapError () is HexError.INVALID_ARGUMENT);

    var badChar = Hex.decode ("GG");
    assert (badChar.isError ());
    assert (badChar.unwrapError () is HexError.PARSE);
}
