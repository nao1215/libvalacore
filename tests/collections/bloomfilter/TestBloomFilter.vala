using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/collections/bloomfilter/testBasic", testBasic);
    Test.add_func ("/collections/bloomfilter/testAddAllAndStats", testAddAllAndStats);
    Test.add_func ("/collections/bloomfilter/testMerge", testMerge);
    Test.add_func ("/collections/bloomfilter/testSerialize", testSerialize);
    Test.add_func ("/collections/bloomfilter/testClear", testClear);

    Test.run ();
}

void testBasic () {
    var filter = new BloomFilter<string> (1000, 0.01);
    for (int i = 0; i < 500; i++) {
        filter.add ("key-%d".printf (i));
    }

    for (int i = 0; i < 500; i++) {
        assert (filter.mightContain ("key-%d".printf (i)) == true);
    }

    int falsePositives = 0;
    for (int i = 500; i < 1000; i++) {
        if (filter.mightContain ("key-%d".printf (i))) {
            falsePositives++;
        }
    }
    assert (falsePositives < 80);
}

void testAddAllAndStats () {
    var filter = new BloomFilter<string> (300, 0.02);
    var items = new ArrayList<string> (GLib.str_equal);
    for (int i = 0; i < 300; i++) {
        items.add ("item-%d".printf (i));
    }
    filter.addAll (items);

    assert (filter.bitSize () > 0);
    assert (filter.hashCount () > 0);

    double fpr = filter.estimatedFalsePositiveRate ();
    assert (fpr > 0.0);
    assert (fpr < 0.2);
}

void testMerge () {
    var left = new BloomFilter<string> (1000, 0.01);
    var right = new BloomFilter<string> (1000, 0.01);

    for (int i = 0; i < 300; i++) {
        left.add ("left-%d".printf (i));
        right.add ("right-%d".printf (i));
    }

    assert (left.merge (right) == true);

    for (int i = 0; i < 300; i++) {
        assert (left.mightContain ("left-%d".printf (i)) == true);
        assert (left.mightContain ("right-%d".printf (i)) == true);
    }
}

void testSerialize () {
    var source = new BloomFilter<string> (1000, 0.01);
    for (int i = 0; i < 200; i++) {
        source.add ("serialize-%d".printf (i));
    }

    uint8[] bytes = source.toBytes ();
    BloomFilter<string> ? restored = source.fromBytes (bytes);

    assert (restored != null);
    assert (restored.bitSize () == source.bitSize ());
    assert (restored.hashCount () == source.hashCount ());
    assert (restored.mightContain ("serialize-42") == true);

    uint8[] invalid = { 1, 2, 3 };
    assert (source.fromBytes (invalid) == null);
}

void testClear () {
    var filter = new BloomFilter<string> (1000, 0.01);
    filter.add ("x");
    assert (filter.mightContain ("x") == true);

    filter.clear ();
    assert (filter.mightContain ("x") == false);
}
