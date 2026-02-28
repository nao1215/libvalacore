using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/collections/multimap/testPutGet", testPutGet);
    Test.add_func ("/collections/multimap/testRemove", testRemove);
    Test.add_func ("/collections/multimap/testClear", testClear);
    Test.run ();
}

void testPutGet () {
    MultiMap<string, string> map = new MultiMap<string, string> (
        GLib.str_hash,
        GLib.str_equal,
        GLib.str_equal
    );
    assert (map.isEmpty () == true);

    map.put ("lang", "vala");
    map.put ("lang", "go");
    map.put ("db", "sqlite");

    assert (map.size () == 2);
    assert (map.containsKey ("lang") == true);
    assert (map.containsKey ("missing") == false);

    ArrayList<string> langs = map.get ("lang");
    assert (langs.size () == 2);
    assert (langs.get (0) == "vala");
    assert (langs.get (1) == "go");

    ArrayList<string> missing = map.get ("missing");
    assert (missing.size () == 0);
}

void testRemove () {
    MultiMap<string, string> map = new MultiMap<string, string> (
        GLib.str_hash,
        GLib.str_equal,
        GLib.str_equal
    );

    map.put ("k", "v1");
    map.put ("k", "v2");

    assert (map.remove ("k", "unknown") == false);
    assert (map.remove ("k", "v1") == true);
    assert (map.get ("k").size () == 1);
    assert (map.remove ("k", "v2") == true);
    assert (map.containsKey ("k") == false);

    map.put ("x", "1");
    map.put ("x", "2");
    assert (map.removeAll ("x") == true);
    assert (map.removeAll ("x") == false);
}

void testClear () {
    MultiMap<string, string> map = new MultiMap<string, string> (
        GLib.str_hash,
        GLib.str_equal,
        GLib.str_equal
    );

    map.put ("a", "1");
    map.put ("b", "2");
    assert (map.size () == 2);
    map.clear ();
    assert (map.size () == 0);
    assert (map.isEmpty () == true);
}
