using Vala.Encoding;
using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/url/testConstruct", testConstruct);
    Test.add_func ("/url/testEncode", testEncode);
    Test.add_func ("/url/testDecode", testDecode);
    Test.add_func ("/url/testRoundTrip", testRoundTrip);
    Test.add_func ("/url/testInvalidDecode", testInvalidDecode);
    Test.run ();
}

void testConstruct () {
    Url url = new Url ();
    assert (url != null);
}

void testEncode () {
    assert (Url.encode ("a b+c") == "a%20b%2Bc");
}

void testDecode () {
    Result<string, GLib.Error> decoded = Url.decode ("a%20b%2Bc");
    assert (decoded.isOk ());
    assert (decoded.unwrap () == "a b+c");
}

void testRoundTrip () {
    string original = "Hello / こんにちは";
    string encoded = Url.encode (original);
    Result<string, GLib.Error> decoded = Url.decode (encoded);
    assert (decoded.isOk ());
    assert (decoded.unwrap () == original);
}

void testInvalidDecode () {
    assertParseError ("%ZZ");
    assertParseError ("%");
    assertParseError ("%A");
    assertParseError ("%1G");
    assertParseError ("%20%ZZ");
}

void assertParseError (string input) {
    Result<string, GLib.Error> decoded = Url.decode (input);
    assert (decoded.isError ());
    assert (decoded.unwrapError () is UrlError.PARSE);
}
