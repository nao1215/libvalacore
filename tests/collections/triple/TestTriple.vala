using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/testConstructor", testConstructor);
    Test.add_func ("/testFirst", testFirst);
    Test.add_func ("/testSecond", testSecond);
    Test.add_func ("/testThird", testThird);
    Test.add_func ("/testEquals", testEquals);
    Test.add_func ("/testEqualsNotEqual", testEqualsNotEqual);
    Test.add_func ("/testToString", testToString);
    Test.add_func ("/testImmutability", testImmutability);

    Test.run ();
}

void testConstructor () {
    var triple = new Triple<string, string, string>("a", "b", "c");
    assert (triple.first () == "a");
    assert (triple.second () == "b");
    assert (triple.third () == "c");
}

void testFirst () {
    var triple = new Triple<string, string, string>("a", "b", "c");
    assert (triple.first () == "a");
    assert (triple.first () == "a");
}

void testSecond () {
    var triple = new Triple<string, string, string>("a", "b", "c");
    assert (triple.second () == "b");
    assert (triple.second () == "b");
}

void testThird () {
    var triple = new Triple<string, string, string>("a", "b", "c");
    assert (triple.third () == "c");
    assert (triple.third () == "c");
}

void testEquals () {
    var a = new Triple<string, string, string>("x", "y", "z");
    var b = new Triple<string, string, string>("x", "y", "z");
    assert (a.equals (b, GLib.str_equal, GLib.str_equal, GLib.str_equal));

    // self equality
    assert (a.equals (a, GLib.str_equal, GLib.str_equal, GLib.str_equal));
}

void testEqualsNotEqual () {
    var a = new Triple<string, string, string>("x", "y", "z");

    // different first
    var b = new Triple<string, string, string>("a", "y", "z");
    assert (!a.equals (b, GLib.str_equal, GLib.str_equal, GLib.str_equal));

    // different second
    var c = new Triple<string, string, string>("x", "a", "z");
    assert (!a.equals (c, GLib.str_equal, GLib.str_equal, GLib.str_equal));

    // different third
    var d = new Triple<string, string, string>("x", "y", "a");
    assert (!a.equals (d, GLib.str_equal, GLib.str_equal, GLib.str_equal));

    // all different
    var e = new Triple<string, string, string>("a", "b", "c");
    assert (!a.equals (e, GLib.str_equal, GLib.str_equal, GLib.str_equal));
}

void testToString () {
    var triple = new Triple<string, string, string>("a", "b", "c");
    assert (triple.toString () == "(a, b, c)");
}

void testImmutability () {
    var triple = new Triple<string, string, string>("a", "b", "c");

    string f = triple.first ();
    string s = triple.second ();
    string t = triple.third ();
    assert (f == "a");
    assert (s == "b");
    assert (t == "c");
    assert (triple.first () == "a");
    assert (triple.second () == "b");
    assert (triple.third () == "c");
}
