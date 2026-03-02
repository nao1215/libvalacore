using Vala.Conv;
using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/conv/convert/testToInt", testToInt);
    Test.add_func ("/conv/convert/testToInt64", testToInt64);
    Test.add_func ("/conv/convert/testToDouble", testToDouble);
    Test.add_func ("/conv/convert/testToBool", testToBool);
    Test.add_func ("/conv/convert/testToString", testToString);
    Test.add_func ("/conv/convert/testToBase", testToBase);
    Test.run ();
}

void testToInt () {
    assert (unwrapInt (Convert.toInt ("42")) == 42);
    assert (unwrapInt (Convert.toInt ("-7")) == -7);
    assertParseErrorInt (Convert.toInt ("abc"));
}

void testToInt64 () {
    assert (unwrapInt64 (Convert.toInt64 ("9223372036854775807")) == int64.MAX);
    assertParseErrorInt64 (Convert.toInt64 ("x"));
}

void testToDouble () {
    double pi = unwrapDouble (Convert.toDouble ("3.14"));
    double minus = unwrapDouble (Convert.toDouble ("-2.5"));
    assert (GLib.Math.fabs (pi - 3.14) < 1e-9);
    assert (GLib.Math.fabs (minus + 2.5) < 1e-9);
    assertParseErrorDouble (Convert.toDouble ("abc"));
}

void testToBool () {
    assert (unwrapBool (Convert.toBool ("true")) == true);
    assert (unwrapBool (Convert.toBool ("FALSE")) == false);
    assert (unwrapBool (Convert.toBool ("1")) == true);
    assert (unwrapBool (Convert.toBool ("0")) == false);
    assertParseErrorBool (Convert.toBool ("yes"));
}

void testToString () {
    assert (Convert.intToString (123) == "123");
    assert (Convert.doubleToString (3.14159, 2) == "3.14");
    assert (Convert.doubleToString (3.9, -1) == "4");
    assert (Convert.boolToString (true) == "true");
}

void testToBase () {
    assert (Convert.intToHex (255) == "ff");
    assert (Convert.intToHex (-255) == "-ff");
    assert (Convert.intToOctal (8) == "10");
    assert (Convert.intToOctal (-8) == "-10");
    assert (Convert.intToBinary (5) == "101");
    assert (Convert.intToBinary (-5) == "-101");
    assert (Convert.intToBinary (0) == "0");
}

int unwrapInt (Result<int, GLib.Error> result) {
    assert (result.isOk ());
    return result.unwrap ();
}

int64 unwrapInt64 (Result<int64 ?, GLib.Error> result) {
    assert (result.isOk ());
    return result.unwrap ();
}

double unwrapDouble (Result<double ?, GLib.Error> result) {
    assert (result.isOk ());
    return result.unwrap ();
}

bool unwrapBool (Result<bool, GLib.Error> result) {
    assert (result.isOk ());
    return result.unwrap ();
}

void assertParseErrorInt (Result<int, GLib.Error> result) {
    assert (result.isError ());
    assert (result.unwrapError () is Vala.Conv.ConvertError.PARSE);
}

void assertParseErrorInt64 (Result<int64 ?, GLib.Error> result) {
    assert (result.isError ());
    assert (result.unwrapError () is Vala.Conv.ConvertError.PARSE);
}

void assertParseErrorDouble (Result<double ?, GLib.Error> result) {
    assert (result.isError ());
    assert (result.unwrapError () is Vala.Conv.ConvertError.PARSE);
}

void assertParseErrorBool (Result<bool, GLib.Error> result) {
    assert (result.isError ());
    assert (result.unwrapError () is Vala.Conv.ConvertError.PARSE);
}
