using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/testConstructor", testConstructor);
    Test.add_func ("/testFirst", testFirst);
    Test.add_func ("/testSecond", testSecond);
    Test.add_func ("/testEquals", testEquals);
    Test.add_func ("/testEqualsNotEqual", testEqualsNotEqual);
    Test.add_func ("/testToString", testToString);
    Test.add_func ("/testImmutability", testImmutability);

    Test.run ();
}

void testConstructor () {
    var pair = new Pair<string, string> ("hello", "world");
    assert (pair.first () == "hello");
    assert (pair.second () == "world");
}

void testFirst () {
    var pair = new Pair<string, string> ("alpha", "beta");
    assert (pair.first () == "alpha");

    // calling first() multiple times returns same value
    assert (pair.first () == "alpha");
}

void testSecond () {
    var pair = new Pair<string, string> ("alpha", "beta");
    assert (pair.second () == "beta");

    // calling second() multiple times returns same value
    assert (pair.second () == "beta");
}

void testEquals () {
    var a = new Pair<string, string> ("x", "y");
    var b = new Pair<string, string> ("x", "y");
    assert (a.equals (b, GLib.str_equal, GLib.str_equal));

    // self equality
    assert (a.equals (a, GLib.str_equal, GLib.str_equal));
}

void testEqualsNotEqual () {
    var a = new Pair<string, string> ("x", "y");

    // different first
    var b = new Pair<string, string> ("z", "y");
    assert (!a.equals (b, GLib.str_equal, GLib.str_equal));

    // different second
    var c = new Pair<string, string> ("x", "z");
    assert (!a.equals (c, GLib.str_equal, GLib.str_equal));

    // both different
    var d = new Pair<string, string> ("a", "b");
    assert (!a.equals (d, GLib.str_equal, GLib.str_equal));
}

void testToString () {
    var pair = new Pair<string, string> ("hello", "world");
    assert (pair.toString () == "(hello, world)");
}

void testImmutability () {
    var pair = new Pair<string, string> ("a", "b");

    // original values unchanged after multiple accesses
    string f = pair.first ();
    string s = pair.second ();
    assert (f == "a");
    assert (s == "b");
    assert (pair.first () == "a");
    assert (pair.second () == "b");
}
