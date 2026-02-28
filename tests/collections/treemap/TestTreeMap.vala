using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/testPutAndGet", testPutAndGet);
    Test.add_func ("/testGetMissing", testGetMissing);
    Test.add_func ("/testPutOverwrite", testPutOverwrite);
    Test.add_func ("/testContainsKey", testContainsKey);
    Test.add_func ("/testRemove", testRemove);
    Test.add_func ("/testRemoveMissing", testRemoveMissing);
    Test.add_func ("/testFirstKey", testFirstKey);
    Test.add_func ("/testLastKey", testLastKey);
    Test.add_func ("/testFirstKeyLastKeyEmpty", testFirstKeyLastKeyEmpty);
    Test.add_func ("/testFloorKey", testFloorKey);
    Test.add_func ("/testCeilingKey", testCeilingKey);
    Test.add_func ("/testSubMap", testSubMap);
    Test.add_func ("/testSize", testSize);
    Test.add_func ("/testIsEmpty", testIsEmpty);
    Test.add_func ("/testClear", testClear);
    Test.add_func ("/testKeys", testKeys);
    Test.add_func ("/testForEach", testForEach);
    Test.add_func ("/testRemoveWithChildren", testRemoveWithChildren);

    Test.run ();
}

TreeMap<string, string> make_map () {
    return new TreeMap<string, string>((a, b) => {
        return strcmp (a, b);
    });
}

void testPutAndGet () {
    var map = make_map ();
    map.put ("b", "2");
    map.put ("a", "1");
    map.put ("c", "3");

    assert (map.get ("a") == "1");
    assert (map.get ("b") == "2");
    assert (map.get ("c") == "3");
}

void testGetMissing () {
    var map = make_map ();
    assert (map.get ("x") == null);

    map.put ("a", "1");
    assert (map.get ("z") == null);
}

void testPutOverwrite () {
    var map = make_map ();
    map.put ("key", "old");
    map.put ("key", "new");
    assert (map.get ("key") == "new");
    assert (map.size () == 1);
}

void testContainsKey () {
    var map = make_map ();
    map.put ("a", "1");
    assert (map.containsKey ("a"));
    assert (!map.containsKey ("b"));
}

void testRemove () {
    var map = make_map ();
    map.put ("a", "1");
    map.put ("b", "2");
    map.put ("c", "3");

    assert (map.remove ("b"));
    assert (!map.containsKey ("b"));
    assert (map.size () == 2);

    // remaining keys still accessible
    assert (map.get ("a") == "1");
    assert (map.get ("c") == "3");
}

void testRemoveMissing () {
    var map = make_map ();
    assert (!map.remove ("x"));

    map.put ("a", "1");
    assert (!map.remove ("z"));
    assert (map.size () == 1);
}

void testFirstKey () {
    var map = make_map ();
    map.put ("c", "3");
    map.put ("a", "1");
    map.put ("b", "2");

    assert (map.firstKey () == "a");
}

void testLastKey () {
    var map = make_map ();
    map.put ("a", "1");
    map.put ("c", "3");
    map.put ("b", "2");

    assert (map.lastKey () == "c");
}

void testFirstKeyLastKeyEmpty () {
    var map = make_map ();
    assert (map.firstKey () == null);
    assert (map.lastKey () == null);
}

void testFloorKey () {
    var map = make_map ();
    map.put ("a", "1");
    map.put ("c", "3");
    map.put ("e", "5");

    // exact match
    assert (map.floorKey ("c") == "c");

    // between keys
    assert (map.floorKey ("d") == "c");

    // below smallest
    assert (map.floorKey ("0") == null);

    // above largest
    assert (map.floorKey ("z") == "e");
}

void testCeilingKey () {
    var map = make_map ();
    map.put ("a", "1");
    map.put ("c", "3");
    map.put ("e", "5");

    // exact match
    assert (map.ceilingKey ("c") == "c");

    // between keys
    assert (map.ceilingKey ("b") == "c");

    // above largest
    assert (map.ceilingKey ("f") == null);

    // below smallest
    assert (map.ceilingKey ("0") == "a");
}

void testSubMap () {
    var map = make_map ();
    map.put ("a", "1");
    map.put ("b", "2");
    map.put ("c", "3");
    map.put ("d", "4");
    map.put ("e", "5");

    var sub = map.subMap ("b", "e");
    assert (sub.size () == 3);
    assert (sub.containsKey ("b"));
    assert (sub.containsKey ("c"));
    assert (sub.containsKey ("d"));
    assert (!sub.containsKey ("a"));
    assert (!sub.containsKey ("e"));

    // empty range
    var empty = map.subMap ("z", "z");
    assert (empty.isEmpty ());

    // full range
    var full = map.subMap ("a", "f");
    assert (full.size () == 5);
}

void testSize () {
    var map = make_map ();
    assert (map.size () == 0);

    map.put ("a", "1");
    assert (map.size () == 1);

    map.put ("b", "2");
    assert (map.size () == 2);

    // overwrite doesn't increase size
    map.put ("a", "x");
    assert (map.size () == 2);
}

void testIsEmpty () {
    var map = make_map ();
    assert (map.isEmpty ());

    map.put ("a", "1");
    assert (!map.isEmpty ());

    map.remove ("a");
    assert (map.isEmpty ());
}

void testClear () {
    var map = make_map ();
    map.put ("a", "1");
    map.put ("b", "2");
    map.put ("c", "3");

    map.clear ();
    assert (map.isEmpty ());
    assert (map.size () == 0);
    assert (map.get ("a") == null);
}

void testKeys () {
    var map = make_map ();
    map.put ("c", "3");
    map.put ("a", "1");
    map.put ("b", "2");

    var keys = map.keys ();
    assert (keys.size () == 3);
    assert (keys.get (0) == "a");
    assert (keys.get (1) == "b");
    assert (keys.get (2) == "c");

    // empty map
    var empty = make_map ();
    var emptyKeys = empty.keys ();
    assert (emptyKeys.size () == 0);
}

void testForEach () {
    var map = make_map ();
    map.put ("c", "3");
    map.put ("a", "1");
    map.put ("b", "2");

    var collected = new ArrayList<string>(GLib.str_equal);
    map.forEach ((k, v) => {
        collected.add (k);
    });

    // should be in sorted order
    assert (collected.size () == 3);
    assert (collected.get (0) == "a");
    assert (collected.get (1) == "b");
    assert (collected.get (2) == "c");
}

void testRemoveWithChildren () {
    var map = make_map ();
    // build a tree: d is root, b and f are children, a c e g are leaves
    map.put ("d", "4");
    map.put ("b", "2");
    map.put ("f", "6");
    map.put ("a", "1");
    map.put ("c", "3");
    map.put ("e", "5");
    map.put ("g", "7");

    // remove node with two children
    assert (map.remove ("b"));
    assert (map.size () == 6);
    assert (!map.containsKey ("b"));

    // all other keys intact
    assert (map.get ("a") == "1");
    assert (map.get ("c") == "3");
    assert (map.get ("d") == "4");
    assert (map.get ("e") == "5");

    // sorted order maintained
    var keys = map.keys ();
    assert (keys.get (0) == "a");
    assert (keys.get (1) == "c");
    assert (keys.get (2) == "d");
}
