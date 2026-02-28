using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/collections/hyperloglog/testCountEstimate", testCountEstimate);
    Test.add_func ("/collections/hyperloglog/testAddBytes", testAddBytes);
    Test.add_func ("/collections/hyperloglog/testMerge", testMerge);
    Test.add_func ("/collections/hyperloglog/testSerialize", testSerialize);
    Test.add_func ("/collections/hyperloglog/testClear", testClear);

    Test.run ();
}

void testCountEstimate () {
    var hll = new HyperLogLog (0.01);
    for (int i = 0; i < 10000; i++) {
        hll.add ("user-%d".printf (i));
    }
    for (int i = 0; i < 10000; i++) {
        hll.add ("user-%d".printf (i));
    }

    int64 estimate = hll.count ();
    assert (estimate > 9000);
    assert (estimate < 11000);
    assert (hll.errorRate () < 0.02);
    assert (hll.registerCount () > 0);
}

void testAddBytes () {
    var hll = new HyperLogLog (0.02);

    for (int i = 0; i < 2000; i++) {
        string value = "byte-%d".printf (i);
        hll.addBytes (value.data);
    }

    int64 estimate = hll.count ();
    assert (estimate > 1700);
    assert (estimate < 2300);
}

void testMerge () {
    var left = new HyperLogLog (0.01);
    var right = new HyperLogLog (0.01);

    for (int i = 0; i < 4000; i++) {
        left.add ("id-%d".printf (i));
    }
    for (int i = 3000; i < 7000; i++) {
        right.add ("id-%d".printf (i));
    }

    assert (left.merge (right) == true);
    int64 estimate = left.count ();
    assert (estimate > 6300);
    assert (estimate < 7700);
}

void testSerialize () {
    var source = new HyperLogLog (0.01);
    for (int i = 0; i < 5000; i++) {
        source.add ("serialize-%d".printf (i));
    }

    uint8[] bytes = source.toBytes ();
    HyperLogLog ? restored = HyperLogLog.fromBytes (bytes);

    assert (restored != null);
    int64 sourceCount = source.count ();
    int64 restoredCount = restored.count ();
    assert (restoredCount > 0);
    assert (restoredCount >= sourceCount - 100);
    assert (restoredCount <= sourceCount + 100);

    uint8[] invalid = { 2, 3, 4 };
    assert (HyperLogLog.fromBytes (invalid) == null);
}

void testClear () {
    var hll = new HyperLogLog ();
    for (int i = 0; i < 1000; i++) {
        hll.add ("x-%d".printf (i));
    }
    assert (hll.count () > 0);

    hll.clear ();
    assert (hll.count () == 0);
}
