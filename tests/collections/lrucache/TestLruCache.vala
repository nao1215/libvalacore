using Vala.Collections;
using Vala.Time;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/collections/lrucache/testPutGet", testPutGet);
    Test.add_func ("/collections/lrucache/testEviction", testEviction);
    Test.add_func ("/collections/lrucache/testUpdateExisting", testUpdateExisting);
    Test.add_func ("/collections/lrucache/testRemoveAndClear", testRemoveAndClear);
    Test.add_func ("/collections/lrucache/testTtlExpiration", testTtlExpiration);
    Test.add_func ("/collections/lrucache/testLoader", testLoader);
    Test.add_func ("/collections/lrucache/testStats", testStats);
    Test.run ();
}

void testPutGet () {
    var cache = new LruCache<string, string> (2, GLib.str_hash, GLib.str_equal);
    cache.put ("a", "1");
    cache.put ("b", "2");

    assert (cache.size () == 2);
    assert (cache.get ("a") == "1");
    assert (cache.get ("b") == "2");
}

void testEviction () {
    var cache = new LruCache<string, string> (2, GLib.str_hash, GLib.str_equal);
    cache.put ("a", "1");
    cache.put ("b", "2");

    assert (cache.get ("a") == "1"); // make a MRU
    cache.put ("c", "3");

    assert (cache.contains ("a"));
    assert (!cache.contains ("b"));
    assert (cache.contains ("c"));
}

void testUpdateExisting () {
    var cache = new LruCache<string, string> (2, GLib.str_hash, GLib.str_equal);
    cache.put ("a", "1");
    cache.put ("a", "2");

    assert (cache.size () == 1);
    assert (cache.get ("a") == "2");
}

void testRemoveAndClear () {
    var cache = new LruCache<string, string> (3, GLib.str_hash, GLib.str_equal);
    cache.put ("a", "1");
    cache.put ("b", "2");

    assert (cache.remove ("a") == true);
    assert (!cache.contains ("a"));
    assert (cache.size () == 1);

    cache.clear ();
    assert (cache.size () == 0);
    assert (!cache.contains ("b"));
}

void testTtlExpiration () {
    var cache = new LruCache<string, string> (2, GLib.str_hash, GLib.str_equal);
    cache.withTtl (Duration.ofSeconds (1));

    cache.put ("a", "1");
    Posix.usleep (1200000);

    assert (cache.get ("a") == null);
    assert (cache.size () == 0);
}

void testLoader () {
    var cache = new LruCache<string, string> (2, GLib.str_hash, GLib.str_equal);
    int load_calls = 0;

    cache.withLoader ((key) => {
        load_calls++;
        return key + "-value";
    });

    assert (cache.get ("x") == "x-value");
    assert (cache.get ("x") == "x-value");
    assert (load_calls == 1);
}

void testStats () {
    var cache = new LruCache<string, string> (2, GLib.str_hash, GLib.str_equal);
    cache.put ("a", "1");

    assert (cache.get ("a") == "1"); // hit
    assert (cache.get ("missing") == null); // miss

    Pair<int, int> stats = cache.stats ();
    assert (stats.first () == 1);
    assert (stats.second () == 1);
}
