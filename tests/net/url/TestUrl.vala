using Vala.Net;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/net/url/testParse", testParse);
    Test.add_func ("/net/url/testParseWithoutOptionalParts", testParseWithoutOptionalParts);
    Test.add_func ("/net/url/testParseInvalid", testParseInvalid);
    Test.run ();
}

void testParse () {
    Vala.Net.Url? url = Vala.Net.Url.parse ("https://example.com:8443/path/to?a=1&b=2#top");

    assert (url != null);
    assert (url.scheme () == "https");
    assert (url.host () == "example.com");
    assert (url.port () == 8443);
    assert (url.path () == "/path/to");
    assert (url.query () == "a=1&b=2");
    assert (url.fragment () == "top");
    assert (url.toString () == "https://example.com:8443/path/to?a=1&b=2#top");
}

void testParseWithoutOptionalParts () {
    Vala.Net.Url? url = Vala.Net.Url.parse ("http://localhost/test");

    assert (url != null);
    assert (url.scheme () == "http");
    assert (url.host () == "localhost");
    assert (url.port () == -1);
    assert (url.path () == "/test");
    assert (url.query () == "");
    assert (url.fragment () == "");
}

void testParseInvalid () {
    assert (Vala.Net.Url.parse ("not a url") == null);
    assert (Vala.Net.Url.parse ("://missing") == null);
}
