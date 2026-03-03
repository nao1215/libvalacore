using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/collections/bloomfilter/testBasic", testBasic);
    Test.add_func ("/collections/bloomfilter/testAddAllAndStats", testAddAllAndStats);
    Test.add_func ("/collections/bloomfilter/testMerge", testMerge);
    Test.add_func ("/collections/bloomfilter/testSerialize", testSerialize);
    Test.add_func ("/collections/bloomfilter/testClear", testClear);
    Test.add_func ("/collections/bloomfilter/testInvalidArguments", testInvalidArguments);

    Test.run ();
}

BloomFilter<string> createFilter (int expected_insertions = 1000, double false_positive_rate = 0.01) {
    var created = BloomFilter.of<string> (expected_insertions, false_positive_rate);
    assert (created.isOk ());
    return created.unwrap ();
}

void testBasic () {
    var filter = createFilter ();
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
    var filter = createFilter (300, 0.02);
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
    var left = createFilter ();
    var right = createFilter ();

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
    var source = createFilter ();
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
    var filter = createFilter ();
    filter.add ("x");
    assert (filter.mightContain ("x") == true);

    filter.clear ();
    assert (filter.mightContain ("x") == false);
}

void testInvalidArguments () {
    var invalidExpected = BloomFilter.of<string> (0, 0.01);
    assert (invalidExpected.isError ());
    var expectedErr = invalidExpected.unwrapError ();
    assert (expectedErr is BloomFilterError.INVALID_ARGUMENT);
    assert (expectedErr.message == "expectedInsertions must be positive");

    var invalidFpr = BloomFilter.of<string> (100, 1.0);
    assert (invalidFpr.isError ());
    var fprErr = invalidFpr.unwrapError ();
    assert (fprErr is BloomFilterError.INVALID_ARGUMENT);
    assert (fprErr.message == "falsePositiveRate must be in range (0, 1)");

    var nanFpr = BloomFilter.of<string> (100, double.NAN);
    assert (nanFpr.isError ());
    assert (nanFpr.unwrapError () is BloomFilterError.INVALID_ARGUMENT);
}
