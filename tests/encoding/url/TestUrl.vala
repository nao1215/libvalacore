using Vala.Encoding;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/url/testEncode", testEncode);
    Test.add_func ("/url/testDecode", testDecode);
    Test.add_func ("/url/testRoundTrip", testRoundTrip);
    Test.add_func ("/url/testInvalidDecode", testInvalidDecode);
    Test.run ();
}

void testEncode () {
    assert (Url.encode ("a b+c") == "a%20b%2Bc");
}

void testDecode () {
    assert (Url.decode ("a%20b%2Bc") == "a b+c");
}

void testRoundTrip () {
    string original = "Hello / こんにちは";
    string encoded = Url.encode (original);
    string decoded = Url.decode (encoded);
    assert (decoded == original);
}

void testInvalidDecode () {
    assert (Url.decode ("%ZZ") == "");
    assert (Url.decode ("%") == "");
    assert (Url.decode ("%A") == "");
    assert (Url.decode ("%1G") == "");
    assert (Url.decode ("%20%ZZ") == "");
}
