using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/collections/maps/testMergeString", testMergeString);
    Test.add_func ("/collections/maps/testMergeGeneric", testMergeGeneric);
    Test.add_func ("/collections/maps/testMergeStringOverride", testMergeStringOverride);
    Test.add_func ("/collections/maps/testFilterString", testFilterString);
    Test.add_func ("/collections/maps/testFilterGeneric", testFilterGeneric);
    Test.add_func ("/collections/maps/testMapValuesString", testMapValuesString);
    Test.add_func ("/collections/maps/testMapValuesGeneric", testMapValuesGeneric);
    Test.add_func ("/collections/maps/testMapKeysString", testMapKeysString);
    Test.add_func ("/collections/maps/testMapKeysGeneric", testMapKeysGeneric);
    Test.add_func ("/collections/maps/testInvertString", testInvertString);
    Test.add_func ("/collections/maps/testInvertGeneric", testInvertGeneric);
    Test.add_func ("/collections/maps/testGetOrDefaultString", testGetOrDefaultString);
    Test.add_func ("/collections/maps/testGetOrDefaultGeneric", testGetOrDefaultGeneric);
    Test.add_func ("/collections/maps/testComputeIfAbsentString", testComputeIfAbsentString);
    Test.add_func ("/collections/maps/testComputeIfAbsentGeneric", testComputeIfAbsentGeneric);
    Test.add_func ("/collections/maps/testKeysGeneric", testKeysGeneric);
    Test.add_func ("/collections/maps/testValuesGeneric", testValuesGeneric);
    Test.add_func ("/collections/maps/testEntriesGeneric", testEntriesGeneric);
    Test.add_func ("/collections/maps/testFromPairsGeneric", testFromPairsGeneric);
    Test.add_func ("/collections/maps/testIsEmptyGeneric", testIsEmptyGeneric);
    Test.add_func ("/collections/maps/testKeysString", testKeysString);
    Test.add_func ("/collections/maps/testValuesString", testValuesString);
    Test.add_func ("/collections/maps/testEntriesString", testEntriesString);
    Test.add_func ("/collections/maps/testFromPairsString", testFromPairsString);
    Test.add_func ("/collections/maps/testIsEmptyString", testIsEmptyString);
    Test.add_func ("/collections/maps/testEmptyMap", testEmptyMap);
    Test.run ();
}

HashMap<string, string> sm (string[] keys, string[] values) {
    assert (keys.length == values.length);
    var map = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    for (int i = 0; i < keys.length; i++) {
        map.put (keys[i], values[i]);
    }
    return map;
}

HashMap<string, int> sim (string[] keys, int[] values) {
    assert (keys.length == values.length);
    var map = new HashMap<string, int> (GLib.str_hash, GLib.str_equal);
    for (int i = 0; i < keys.length; i++) {
        map.put (keys[i], values[i]);
    }
    return map;
}

void testMergeString () {
    var a = sm ({ "a", "b" }, { "1", "2" });
    var b = sm ({ "c", "d" }, { "3", "4" });
    var merged = Maps.mergeString (a, b);
    assert (merged.size () == 4);
    assert (merged.get ("a") == "1");
    assert (merged.get ("b") == "2");
    assert (merged.get ("c") == "3");
    assert (merged.get ("d") == "4");
}

void testMergeGeneric () {
    var a = sim ({ "a", "b" }, { 1, 2 });
    var b = sim ({ "b", "c" }, { 9, 3 });
    var merged = Maps.merge<string, int> (a, b, GLib.str_hash, GLib.str_equal);
    assert (merged.size () == 3);
    int ? aVal = merged.get ("a");
    int ? bVal = merged.get ("b");
    int ? cVal = merged.get ("c");
    assert (aVal != null && aVal == 1);
    assert (bVal != null && bVal == 9);
    assert (cVal != null && cVal == 3);
}

void testMergeStringOverride () {
    var defaults = sm ({ "theme", "lang" }, { "light", "en" });
    var overrides = sm ({ "theme" }, { "dark" });
    var config = Maps.mergeString (defaults, overrides);
    assert (config.size () == 2);
    assert (config.get ("theme") == "dark");
    assert (config.get ("lang") == "en");
}

void testFilterString () {
    var map = sm ({ "name", "age", "note" }, { "Alice", "30", "" });
    var filtered = Maps.filterString (map, (k, v) => {
        return v.length > 0;
    });
    assert (filtered.size () == 2);
    assert (filtered.containsKey ("name"));
    assert (filtered.containsKey ("age"));
    assert (!filtered.containsKey ("note"));
}

void testFilterGeneric () {
    var map = sim ({ "one", "two", "three" }, { 1, 2, 3 });
    var filtered = Maps.filter<string, int> (
        map,
        (k, v) => {
        return v >= 2;
    },
        GLib.str_hash,
        GLib.str_equal
    );
    assert (filtered.size () == 2);
    assert (!filtered.containsKey ("one"));
    assert (filtered.containsKey ("two"));
    assert (filtered.containsKey ("three"));
}

void testMapValuesString () {
    var map = sm ({ "name", "city" }, { "alice", "tokyo" });
    var upper = Maps.mapValuesString (map, (v) => { return v.up (); });
    assert (upper.size () == 2);
    assert (upper.get ("name") == "ALICE");
    assert (upper.get ("city") == "TOKYO");
}

void testMapValuesGeneric () {
    var map = sim ({ "a", "bb" }, { 1, 2 });
    var labels = Maps.mapValues<string, int, string> (
        map,
        (v) => {
        return "v=%d".printf (v);
    },
        GLib.str_hash,
        GLib.str_equal
    );
    assert (labels.size () == 2);
    assert (labels.get ("a") == "v=1");
    assert (labels.get ("bb") == "v=2");
}

void testMapKeysString () {
    var map = sm ({ "Name", "City" }, { "Alice", "Tokyo" });
    var lower = Maps.mapKeysString (map, (k) => { return k.down (); });
    assert (lower.size () == 2);
    assert (lower.get ("name") == "Alice");
    assert (lower.get ("city") == "Tokyo");
}

void testMapKeysGeneric () {
    var map = sim ({ "a", "bb" }, { 1, 2 });
    var remapped = Maps.mapKeys<string, int, int> (
        map,
        (k) => {
        return k.length;
    },
        GLib.direct_hash,
        GLib.direct_equal
    );
    assert (remapped.size () == 2);
    int ? len1 = remapped.get (1);
    int ? len2 = remapped.get (2);
    assert (len1 != null && len1 == 1);
    assert (len2 != null && len2 == 2);
}

void testInvertString () {
    var map = sm ({ "a", "b", "c" }, { "1", "2", "3" });
    var inv = Maps.invertString (map);
    assert (inv.size () == 3);
    assert (inv.get ("1") == "a");
    assert (inv.get ("2") == "b");
    assert (inv.get ("3") == "c");
}

void testInvertGeneric () {
    var map = sim ({ "x", "y" }, { 10, 20 });
    var inv = Maps.invert<string, int> (map, GLib.direct_hash, GLib.direct_equal);
    assert (inv.size () == 2);
    assert (inv.get (10) == "x");
    assert (inv.get (20) == "y");
}

void testGetOrDefaultString () {
    var map = sm ({ "host" }, { "localhost" });
    assert (Maps.getOrDefaultString (map, "host", "0.0.0.0") == "localhost");
    assert (Maps.getOrDefaultString (map, "port", "8080") == "8080");
}

void testGetOrDefaultGeneric () {
    var map = sim ({ "host" }, { 80 });
    assert (Maps.getOrDefault<string, int> (map, "host", 8080) == 80);
    assert (Maps.getOrDefault<string, int> (map, "port", 8080) == 8080);
}

void testComputeIfAbsentString () {
    var map = sm ({ "existing" }, { "value" });
    var val1 = Maps.computeIfAbsentString (map, "existing", () => {
        return "should not compute";
    });
    assert (val1 == "value");

    var val2 = Maps.computeIfAbsentString (map, "new_key", () => {
        return "computed";
    });
    assert (val2 == "computed");
    assert (map.get ("new_key") == "computed");
    assert (map.size () == 2);
}

void testComputeIfAbsentGeneric () {
    var map = sim ({ "exists" }, { 7 });
    int val1 = Maps.computeIfAbsent<string, int> (map, "exists", () => {
        return 99;
    });
    int val2 = Maps.computeIfAbsent<string, int> (map, "new", () => {
        return 42;
    });
    assert (val1 == 7);
    assert (val2 == 42);
    int ? newVal = map.get ("new");
    assert (newVal != null && newVal == 42);
}

void testKeysGeneric () {
    var map = sim ({ "a", "b", "c" }, { 1, 2, 3 });
    var keyList = Maps.keys<string, int> (map);
    assert (keyList.size () == 3);
    bool foundA = false;
    bool foundB = false;
    bool foundC = false;
    for (int i = 0; i < (int) keyList.size (); i++) {
        string key = keyList.get (i);
        if (key == "a") {
            foundA = true;
        } else if (key == "b") {
            foundB = true;
        } else if (key == "c") {
            foundC = true;
        }
    }
    assert (foundA && foundB && foundC);
}

void testValuesGeneric () {
    var map = sim ({ "a", "b", "c" }, { 1, 2, 3 });
    var valList = Maps.values<string, int> (map);
    assert (valList.size () == 3);
    bool found1 = false;
    bool found2 = false;
    bool found3 = false;
    for (int i = 0; i < (int) valList.size (); i++) {
        int value = valList.get (i);
        if (value == 1) {
            found1 = true;
        } else if (value == 2) {
            found2 = true;
        } else if (value == 3) {
            found3 = true;
        }
    }
    assert (found1 && found2 && found3);
}

void testEntriesGeneric () {
    var map = sim ({ "a", "b" }, { 1, 2 });
    var entries = Maps.entries<string, int> (map);
    assert (entries.size () == 2);
    bool foundA = false;
    bool foundB = false;
    for (int i = 0; i < (int) entries.size (); i++) {
        Pair<string, int> e = (Pair<string, int>) entries.get (i);
        if ((string) e.first () == "a" && (int) e.second () == 1) {
            foundA = true;
        }
        if ((string) e.first () == "b" && (int) e.second () == 2) {
            foundB = true;
        }
    }
    assert (foundA);
    assert (foundB);
}

void testFromPairsGeneric () {
    var pairs = new ArrayList<Pair<string, int> > ();
    pairs.add (new Pair<string, int> ("x", 10));
    pairs.add (new Pair<string, int> ("y", 20));
    var map = Maps.fromPairs<string, int> (pairs, GLib.str_hash, GLib.str_equal);
    assert (map.size () == 2);
    int ? x = map.get ("x");
    int ? y = map.get ("y");
    assert (x != null && x == 10);
    assert (y != null && y == 20);
}

void testIsEmptyGeneric () {
    var empty = new HashMap<string, int> (GLib.str_hash, GLib.str_equal);
    assert (Maps.isEmpty<string, int> (empty));
    empty.put ("a", 1);
    assert (!Maps.isEmpty<string, int> (empty));
}

void testKeysString () {
    var map = sm ({ "a", "b", "c" }, { "1", "2", "3" });
    var keyList = Maps.keysString (map);
    assert (keyList.size () == 3);
    assert (keyList.contains ("a"));
    assert (keyList.contains ("b"));
    assert (keyList.contains ("c"));
}

void testValuesString () {
    var map = sm ({ "a", "b", "c" }, { "1", "2", "3" });
    var valList = Maps.valuesString (map);
    assert (valList.size () == 3);
    assert (valList.contains ("1"));
    assert (valList.contains ("2"));
    assert (valList.contains ("3"));
}

void testEntriesString () {
    var map = sm ({ "a", "b" }, { "1", "2" });
    var entries = Maps.entriesString (map);
    assert (entries.size () == 2);
    bool foundA = false;
    bool foundB = false;
    for (int i = 0; i < (int) entries.size (); i++) {
        Pair<string, string> e = (Pair<string, string>) entries.get (i);
        if ((string) e.first () == "a" && (string) e.second () == "1") {
            foundA = true;
        }
        if ((string) e.first () == "b" && (string) e.second () == "2") {
            foundB = true;
        }
    }
    assert (foundA);
    assert (foundB);
}

void testFromPairsString () {
    var pairs = new ArrayList<Pair<string, string> > ();
    pairs.add (new Pair<string, string> ("x", "10"));
    pairs.add (new Pair<string, string> ("y", "20"));
    pairs.add (new Pair<string, string> ("z", "30"));
    var map = Maps.fromPairsString (pairs);
    assert (map.size () == 3);
    assert (map.get ("x") == "10");
    assert (map.get ("y") == "20");
    assert (map.get ("z") == "30");
}

void testIsEmptyString () {
    var empty = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    assert (Maps.isEmptyString (empty));

    var map = sm ({ "a" }, { "1" });
    assert (!Maps.isEmptyString (map));
}

void testEmptyMap () {
    var empty = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    assert (Maps.mergeString (empty, empty).size () == 0);
    assert (Maps.filterString (empty, (k, v) => { return true; }).size () == 0);
    assert (Maps.mapValuesString (empty, (v) => { return v; }).size () == 0);
    assert (Maps.mapKeysString (empty, (k) => { return k; }).size () == 0);
    assert (Maps.invertString (empty).size () == 0);
    assert (Maps.keysString (empty).size () == 0);
    assert (Maps.valuesString (empty).size () == 0);
    assert (Maps.entriesString (empty).size () == 0);
    assert (Maps.fromPairsString (new ArrayList<Pair<string, string> > ()).size () == 0);
    assert (Maps.isEmptyString (empty));
}
