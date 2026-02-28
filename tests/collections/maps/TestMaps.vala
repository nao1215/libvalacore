using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/collections/maps/testMergeString", testMergeString);
    Test.add_func ("/collections/maps/testMergeStringOverride", testMergeStringOverride);
    Test.add_func ("/collections/maps/testFilterString", testFilterString);
    Test.add_func ("/collections/maps/testMapValuesString", testMapValuesString);
    Test.add_func ("/collections/maps/testMapKeysString", testMapKeysString);
    Test.add_func ("/collections/maps/testInvertString", testInvertString);
    Test.add_func ("/collections/maps/testGetOrDefaultString", testGetOrDefaultString);
    Test.add_func ("/collections/maps/testComputeIfAbsentString", testComputeIfAbsentString);
    Test.add_func ("/collections/maps/testKeysString", testKeysString);
    Test.add_func ("/collections/maps/testValuesString", testValuesString);
    Test.add_func ("/collections/maps/testEntriesString", testEntriesString);
    Test.add_func ("/collections/maps/testFromPairsString", testFromPairsString);
    Test.add_func ("/collections/maps/testIsEmptyString", testIsEmptyString);
    Test.add_func ("/collections/maps/testEmptyMap", testEmptyMap);
    Test.run ();
}

HashMap<string, string> sm (string[] keys, string[] values) {
    var map = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
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

void testMapValuesString () {
    var map = sm ({ "name", "city" }, { "alice", "tokyo" });
    var upper = Maps.mapValuesString (map, (v) => { return v.up (); });
    assert (upper.size () == 2);
    assert (upper.get ("name") == "ALICE");
    assert (upper.get ("city") == "TOKYO");
}

void testMapKeysString () {
    var map = sm ({ "Name", "City" }, { "Alice", "Tokyo" });
    var lower = Maps.mapKeysString (map, (k) => { return k.down (); });
    assert (lower.size () == 2);
    assert (lower.get ("name") == "Alice");
    assert (lower.get ("city") == "Tokyo");
}

void testInvertString () {
    var map = sm ({ "a", "b", "c" }, { "1", "2", "3" });
    var inv = Maps.invertString (map);
    assert (inv.size () == 3);
    assert (inv.get ("1") == "a");
    assert (inv.get ("2") == "b");
    assert (inv.get ("3") == "c");
}

void testGetOrDefaultString () {
    var map = sm ({ "host" }, { "localhost" });
    assert (Maps.getOrDefaultString (map, "host", "0.0.0.0") == "localhost");
    assert (Maps.getOrDefaultString (map, "port", "8080") == "8080");
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
