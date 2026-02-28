using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/collections/lists/testPartitionString", testPartitionString);
    Test.add_func ("/collections/lists/testChunkString", testChunkString);
    Test.add_func ("/collections/lists/testChunkStringRemainder", testChunkStringRemainder);
    Test.add_func ("/collections/lists/testZipString", testZipString);
    Test.add_func ("/collections/lists/testZipWithIndexString", testZipWithIndexString);
    Test.add_func ("/collections/lists/testFlattenString", testFlattenString);
    Test.add_func ("/collections/lists/testGroupByString", testGroupByString);
    Test.add_func ("/collections/lists/testDistinctString", testDistinctString);
    Test.add_func ("/collections/lists/testReverseString", testReverseString);
    Test.add_func ("/collections/lists/testSlidingString", testSlidingString);
    Test.add_func ("/collections/lists/testInterleaveString", testInterleaveString);
    Test.add_func ("/collections/lists/testFrequencyString", testFrequencyString);
    Test.add_func ("/collections/lists/testEmptyList", testEmptyList);
    Test.run ();
}

ArrayList<string> sl (string[] items) {
    var list = new ArrayList<string> (GLib.str_equal);
    foreach (string s in items) {
        list.add (s);
    }
    return list;
}

void testPartitionString () {
    var list = sl ({ "apple", "banana", "avocado", "cherry" });
    var pair = Lists.partitionString (list, (s) => {
        return s.has_prefix ("a");
    });
    ArrayList<string> matching = (ArrayList<string>) pair.first ();
    ArrayList<string> rest = (ArrayList<string>) pair.second ();
    assert (matching.size () == 2);
    assert (rest.size () == 2);
    assert (matching.get (0) == "apple");
    assert (matching.get (1) == "avocado");
    assert (rest.get (0) == "banana");
}

void testChunkString () {
    var list = sl ({ "a", "b", "c", "d", "e", "f" });
    var chunks = Lists.chunkString (list, 2);
    assert (chunks.size () == 3);
    ArrayList<string> c0 = (ArrayList<string>) chunks.get (0);
    assert (c0.size () == 2);
    assert (c0.get (0) == "a");
    assert (c0.get (1) == "b");
    ArrayList<string> c2 = (ArrayList<string>) chunks.get (2);
    assert (c2.get (0) == "e");
}

void testChunkStringRemainder () {
    var list = sl ({ "a", "b", "c", "d", "e" });
    var chunks = Lists.chunkString (list, 3);
    assert (chunks.size () == 2);
    ArrayList<string> c0 = (ArrayList<string>) chunks.get (0);
    ArrayList<string> c1 = (ArrayList<string>) chunks.get (1);
    assert (c0.size () == 3);
    assert (c1.size () == 2);
    assert (c1.get (0) == "d");
}

void testZipString () {
    var a = sl ({ "a", "b", "c" });
    var b = sl ({ "1", "2" });
    var pairs = Lists.zipString (a, b);
    assert (pairs.size () == 2);
    Pair<string, string> p0 = (Pair<string, string>) pairs.get (0);
    Pair<string, string> p1 = (Pair<string, string>) pairs.get (1);
    assert ((string) p0.first () == "a");
    assert ((string) p0.second () == "1");
    assert ((string) p1.first () == "b");
    assert ((string) p1.second () == "2");
}

void testZipWithIndexString () {
    var list = sl ({ "x", "y", "z" });
    var indexed = Lists.zipWithIndexString (list);
    assert (indexed.size () == 3);
    Pair<int, string> i0 = (Pair<int, string>) indexed.get (0);
    Pair<int, string> i2 = (Pair<int, string>) indexed.get (2);
    assert ((string) i0.second () == "x");
    assert ((string) i2.second () == "z");
}

void testFlattenString () {
    var nested = new ArrayList<ArrayList<string> > ();
    nested.add (sl ({ "a", "b" }));
    nested.add (sl ({ "c" }));
    nested.add (sl ({ "d", "e", "f" }));
    var flat = Lists.flattenString (nested);
    assert (flat.size () == 6);
    assert (flat.get (0) == "a");
    assert (flat.get (5) == "f");
}

void testGroupByString () {
    var list = sl ({ "apple", "avocado", "banana", "blueberry", "cherry" });
    var groups = Lists.groupByString (list, (s) => {
        return s.substring (0, 1);
    });
    assert (groups.containsKey ("a"));
    ArrayList<string> aGroup = (ArrayList<string>) groups.get ("a");
    ArrayList<string> bGroup = (ArrayList<string>) groups.get ("b");
    ArrayList<string> cGroup = (ArrayList<string>) groups.get ("c");
    assert (aGroup.size () == 2);
    assert (bGroup.size () == 2);
    assert (cGroup.size () == 1);
}

void testDistinctString () {
    var list = sl ({ "a", "b", "a", "c", "b", "d" });
    var result = Lists.distinctString (list);
    assert (result.size () == 4);
    assert (result.get (0) == "a");
    assert (result.get (1) == "b");
    assert (result.get (2) == "c");
    assert (result.get (3) == "d");
}

void testReverseString () {
    var list = sl ({ "a", "b", "c" });
    var result = Lists.reverseString (list);
    assert (result.size () == 3);
    assert (result.get (0) == "c");
    assert (result.get (1) == "b");
    assert (result.get (2) == "a");
}

void testSlidingString () {
    var list = sl ({ "a", "b", "c", "d" });
    var windows = Lists.slidingString (list, 2);
    assert (windows.size () == 3);
    ArrayList<string> w0 = (ArrayList<string>) windows.get (0);
    ArrayList<string> w1 = (ArrayList<string>) windows.get (1);
    ArrayList<string> w2 = (ArrayList<string>) windows.get (2);
    assert (w0.get (0) == "a");
    assert (w0.get (1) == "b");
    assert (w1.get (0) == "b");
    assert (w1.get (1) == "c");
    assert (w2.get (0) == "c");
    assert (w2.get (1) == "d");
}

void testInterleaveString () {
    var a = sl ({ "1", "3", "5" });
    var b = sl ({ "2", "4" });
    var result = Lists.interleaveString (a, b);
    assert (result.size () == 5);
    assert (result.get (0) == "1");
    assert (result.get (1) == "2");
    assert (result.get (2) == "3");
    assert (result.get (3) == "4");
    assert (result.get (4) == "5");
}

void testFrequencyString () {
    var list = sl ({ "a", "b", "a", "c", "a", "b" });
    var freq = Lists.frequencyString (list);
    assert (freq.get ("a") == 3);
    assert (freq.get ("b") == 2);
    assert (freq.get ("c") == 1);
}

void testEmptyList () {
    var empty = sl ({});
    assert (Lists.chunkString (empty, 3).size () == 0);
    assert (Lists.distinctString (empty).size () == 0);
    assert (Lists.reverseString (empty).size () == 0);
    assert (Lists.flattenString (new ArrayList<ArrayList<string> > ()).size () == 0);

    var pair = Lists.partitionString (empty, (s) => { return true; });
    ArrayList<string> matching = (ArrayList<string>) pair.first ();
    ArrayList<string> rest = (ArrayList<string>) pair.second ();
    assert (matching.size () == 0);
    assert (rest.size () == 0);
}
