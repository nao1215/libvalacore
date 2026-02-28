using Vala.Conv;

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
    assert (Convert.toInt ("42") == 42);
    assert (Convert.toInt ("-7") == -7);
    assert (Convert.toInt ("abc") == null);
}

void testToInt64 () {
    assert (Convert.toInt64 ("9223372036854775807") == int64.MAX);
    assert (Convert.toInt64 ("x") == null);
}

void testToDouble () {
    double ? pi = Convert.toDouble ("3.14");
    double ? minus = Convert.toDouble ("-2.5");
    assert (pi != null);
    assert (minus != null);
    assert (GLib.Math.fabs ((double) pi - 3.14) < 1e-9);
    assert (GLib.Math.fabs ((double) minus + 2.5) < 1e-9);
    assert (Convert.toDouble ("abc") == null);
}

void testToBool () {
    assert (Convert.toBool ("true") == true);
    assert (Convert.toBool ("FALSE") == false);
    assert (Convert.toBool ("1") == true);
    assert (Convert.toBool ("0") == false);
    assert (Convert.toBool ("yes") == null);
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
