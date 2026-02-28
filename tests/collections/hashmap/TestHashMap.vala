using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/testPutAndGet", testPutAndGet);
    Test.add_func ("/testGetMissing", testGetMissing);
    Test.add_func ("/testGetOrDefault", testGetOrDefault);
    Test.add_func ("/testPutOverwrite", testPutOverwrite);
    Test.add_func ("/testContainsKey", testContainsKey);
    Test.add_func ("/testContainsValue", testContainsValue);
    Test.add_func ("/testRemove", testRemove);
    Test.add_func ("/testRemoveMissing", testRemoveMissing);
    Test.add_func ("/testSize", testSize);
    Test.add_func ("/testIsEmpty", testIsEmpty);
    Test.add_func ("/testClear", testClear);
    Test.add_func ("/testKeys", testKeys);
    Test.add_func ("/testValues", testValues);
    Test.add_func ("/testForEach", testForEach);
    Test.add_func ("/testPutIfAbsent", testPutIfAbsent);
    Test.add_func ("/testMerge", testMerge);

    Test.run ();
}

void testPutAndGet () {
    var map = new HashMap<string, string>(GLib.str_hash, GLib.str_equal);
    map.put ("name", "Alice");
    assert (map.get ("name") == "Alice");

    map.put ("city", "Tokyo");
    assert (map.get ("city") == "Tokyo");
}

void testGetMissing () {
    var map = new HashMap<string, string>(GLib.str_hash, GLib.str_equal);
    assert (map.get ("missing") == null);

    map.put ("key", "value");
    assert (map.get ("other") == null);
}

void testGetOrDefault () {
    var map = new HashMap<string, string>(GLib.str_hash, GLib.str_equal);
    assert (map.getOrDefault ("missing", "fallback") == "fallback");

    map.put ("key", "value");
    assert (map.getOrDefault ("key", "fallback") == "value");
}

void testPutOverwrite () {
    var map = new HashMap<string, string>(GLib.str_hash, GLib.str_equal);
    map.put ("key", "first");
    assert (map.get ("key") == "first");

    map.put ("key", "second");
    assert (map.get ("key") == "second");
    assert (map.size () == 1);
}

void testContainsKey () {
    var map = new HashMap<string, string>(GLib.str_hash, GLib.str_equal);
    assert (!map.containsKey ("key"));

    map.put ("key", "value");
    assert (map.containsKey ("key"));
    assert (!map.containsKey ("other"));
}

void testContainsValue () {
    var map = new HashMap<string, string>(GLib.str_hash, GLib.str_equal);
    assert (!map.containsValue ("value", GLib.str_equal));

    map.put ("key", "value");
    assert (map.containsValue ("value", GLib.str_equal));
    assert (!map.containsValue ("other", GLib.str_equal));
}

void testRemove () {
    var map = new HashMap<string, string>(GLib.str_hash, GLib.str_equal);
    map.put ("a", "1");
    map.put ("b", "2");

    assert (map.remove ("a"));
    assert (!map.containsKey ("a"));
    assert (map.size () == 1);
}

void testRemoveMissing () {
    var map = new HashMap<string, string>(GLib.str_hash, GLib.str_equal);
    assert (!map.remove ("missing"));

    map.put ("key", "value");
    assert (!map.remove ("other"));
}

void testSize () {
    var map = new HashMap<string, string>(GLib.str_hash, GLib.str_equal);
    assert (map.size () == 0);

    map.put ("a", "1");
    assert (map.size () == 1);

    map.put ("b", "2");
    assert (map.size () == 2);

    map.put ("c", "3");
    assert (map.size () == 3);
}

void testIsEmpty () {
    var map = new HashMap<string, string>(GLib.str_hash, GLib.str_equal);
    assert (map.isEmpty ());

    map.put ("key", "value");
    assert (!map.isEmpty ());
}

void testClear () {
    var map = new HashMap<string, string>(GLib.str_hash, GLib.str_equal);
    map.put ("a", "1");
    map.put ("b", "2");
    map.put ("c", "3");

    map.clear ();
    assert (map.isEmpty ());
    assert (map.size () == 0);
}

void testKeys () {
    var map = new HashMap<string, string>(GLib.str_hash, GLib.str_equal);
    map.put ("a", "1");
    map.put ("b", "2");

    GLib.List<unowned string> k = map.keys ();
    assert (k.length () == 2);
}

void testValues () {
    var map = new HashMap<string, string>(GLib.str_hash, GLib.str_equal);
    map.put ("a", "1");
    map.put ("b", "2");

    GLib.List<unowned string> v = map.values ();
    assert (v.length () == 2);
}

void testForEach () {
    var map = new HashMap<string, string>(GLib.str_hash, GLib.str_equal);
    map.put ("a", "1");
    map.put ("b", "2");

    int count = 0;
    map.forEach ((k, v) => {
        count++;
    });
    assert (count == 2);
}

void testPutIfAbsent () {
    var map = new HashMap<string, string>(GLib.str_hash, GLib.str_equal);

    assert (map.putIfAbsent ("key", "first"));
    assert (map.get ("key") == "first");

    assert (!map.putIfAbsent ("key", "second"));
    assert (map.get ("key") == "first");
}

void testMerge () {
    var map1 = new HashMap<string, string>(GLib.str_hash, GLib.str_equal);
    map1.put ("a", "1");
    map1.put ("b", "2");

    var map2 = new HashMap<string, string>(GLib.str_hash, GLib.str_equal);
    map2.put ("c", "3");
    map2.put ("b", "overwritten");

    map1.merge (map2);
    assert (map1.size () == 3);
    assert (map1.get ("a") == "1");
    assert (map1.get ("b") == "overwritten");
    assert (map1.get ("c") == "3");
}
