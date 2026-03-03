using Vala.Net;
using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/net/url/testParse", testParse);
    Test.add_func ("/net/url/testParseWithoutOptionalParts", testParseWithoutOptionalParts);
    Test.add_func ("/net/url/testParseInvalid", testParseInvalid);
    Test.run ();
}

void testParse () {
    Result<Vala.Net.Url, GLib.Error> parsed = Vala.Net.Url.parse (
        "https://example.com:8443/path/to?a=1&b=2#top"
    );
    assert (parsed.isOk ());
    Vala.Net.Url url = parsed.unwrap ();

    assert (url.scheme () == "https");
    assert (url.host () == "example.com");
    assert (url.port () == 8443);
    assert (url.path () == "/path/to");
    assert (url.query () == "a=1&b=2");
    assert (url.fragment () == "top");
    assert (url.toString () == "https://example.com:8443/path/to?a=1&b=2#top");
}

void testParseWithoutOptionalParts () {
    Result<Vala.Net.Url, GLib.Error> parsed = Vala.Net.Url.parse ("http://localhost/test");
    assert (parsed.isOk ());
    Vala.Net.Url url = parsed.unwrap ();

    assert (url.scheme () == "http");
    assert (url.host () == "localhost");
    assert (url.port () == -1);
    assert (url.path () == "/test");
    assert (url.query () == "");
    assert (url.fragment () == "");
}

void testParseInvalid () {
    Result<Vala.Net.Url, GLib.Error> malformed = Vala.Net.Url.parse ("not a url");
    assert (malformed.isError ());
    assert (malformed.unwrapError () is NetUrlError.PARSE);

    Result<Vala.Net.Url, GLib.Error> missingScheme = Vala.Net.Url.parse ("://missing");
    assert (missingScheme.isError ());
    assert (missingScheme.unwrapError () is NetUrlError.PARSE);

    Result<Vala.Net.Url, GLib.Error> empty = Vala.Net.Url.parse ("");
    assert (empty.isError ());
    assert (empty.unwrapError () is NetUrlError.INVALID_ARGUMENT);
}
