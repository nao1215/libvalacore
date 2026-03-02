using Vala.Encoding;
using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/base64/testConstruct", testConstruct);
    Test.add_func ("/base64/testEncode", testEncode);
    Test.add_func ("/base64/testDecode", testDecode);
    Test.add_func ("/base64/testEncodeString", testEncodeString);
    Test.add_func ("/base64/testDecodeString", testDecodeString);
    Test.add_func ("/base64/testEmpty", testEmpty);
    Test.add_func ("/base64/testInvalid", testInvalid);
    Test.run ();
}

void testConstruct () {
    var codec = new Vala.Encoding.Base64 ();
    assert (codec != null);
}

void testEncode () {
    uint8[] data = { 0x48, 0x65, 0x6C, 0x6C, 0x6F };
    assert (Vala.Encoding.Base64.encode (data) == "SGVsbG8=");
}

void testDecode () {
    uint8[] decoded = unwrapBytes (Vala.Encoding.Base64.decode ("SGVsbG8="));
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
    Result<string, GLib.Error> decoded = Vala.Encoding.Base64.decodeString ("aGVsbG8=");
    assert (decoded.isOk ());
    assert (decoded.unwrap () == "hello");
}

void testEmpty () {
    uint8[] empty = {};
    assert (Vala.Encoding.Base64.encode (empty) == "");
    assert (unwrapBytes (Vala.Encoding.Base64.decode ("")).length == 0);
    Result<string, GLib.Error> decoded = Vala.Encoding.Base64.decodeString ("");
    assert (decoded.isOk ());
    assert (decoded.unwrap () == "");
}

void testInvalid () {
    Result<GLib.Bytes, GLib.Error> invalidLength = Vala.Encoding.Base64.decode ("A");
    assert (invalidLength.isError ());
    assert (invalidLength.unwrapError () is Base64Error.INVALID_ARGUMENT);

    Result<GLib.Bytes, GLib.Error> invalidChar = Vala.Encoding.Base64.decode ("AAAA*AAA");
    assert (invalidChar.isError ());
    assert (invalidChar.unwrapError () is Base64Error.PARSE);

    Result<GLib.Bytes, GLib.Error> invalidPadding = Vala.Encoding.Base64.decode ("A=AA");
    assert (invalidPadding.isError ());
    assert (invalidPadding.unwrapError () is Base64Error.PARSE);

    Result<string, GLib.Error> invalidString = Vala.Encoding.Base64.decodeString ("A");
    assert (invalidString.isError ());
    assert (invalidString.unwrapError () is Base64Error.INVALID_ARGUMENT);
}

uint8[] unwrapBytes (Result<GLib.Bytes, GLib.Error> result) {
    assert (result.isOk ());
    return copyBytes (result.unwrap ());
}

uint8[] copyBytes (GLib.Bytes bytes) {
    uint8[] raw = bytes.get_data ();
    uint8[] copied = new uint8[raw.length];
    for (int i = 0; i < raw.length; i++) {
        copied[i] = raw[i];
    }
    return copied;
}
