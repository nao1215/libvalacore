using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/collections/hyperloglog/testCountEstimate", testCountEstimate);
    Test.add_func ("/collections/hyperloglog/testAddBytes", testAddBytes);
    Test.add_func ("/collections/hyperloglog/testMerge", testMerge);
    Test.add_func ("/collections/hyperloglog/testSerialize", testSerialize);
    Test.add_func ("/collections/hyperloglog/testClear", testClear);
    Test.add_func ("/collections/hyperloglog/testInvalidArguments", testInvalidArguments);

    Test.run ();
}

HyperLogLog createEstimator (double error_rate = 0.01) {
    var created = HyperLogLog.of (error_rate);
    assert (created.isOk ());
    return created.unwrap ();
}

void testCountEstimate () {
    var hll = createEstimator (0.01);
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
    var hll = createEstimator (0.02);

    for (int i = 0; i < 2000; i++) {
        string value = "byte-%d".printf (i);
        hll.addBytes (value.data);
    }

    int64 estimate = hll.count ();
    assert (estimate > 1700);
    assert (estimate < 2300);
}

void testMerge () {
    var left = createEstimator (0.01);
    var right = createEstimator (0.01);

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
    var source = createEstimator (0.01);
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
    var hll = createEstimator ();
    for (int i = 0; i < 1000; i++) {
        hll.add ("x-%d".printf (i));
    }
    assert (hll.count () > 0);

    hll.clear ();
    assert (hll.count () == 0);
}

void testInvalidArguments () {
    var zero = HyperLogLog.of (0.0);
    assert (zero.isError ());
    assert (zero.unwrapError () is HyperLogLogError.INVALID_ARGUMENT);
    assert (zero.unwrapError ().message == "errorRate must be in range (0, 1)");

    var one = HyperLogLog.of (1.0);
    assert (one.isError ());
    assert (one.unwrapError () is HyperLogLogError.INVALID_ARGUMENT);
    assert (one.unwrapError ().message == "errorRate must be in range (0, 1)");

    var negative = HyperLogLog.of (-0.5);
    assert (negative.isError ());
    assert (negative.unwrapError () is HyperLogLogError.INVALID_ARGUMENT);
    assert (negative.unwrapError ().message == "errorRate must be in range (0, 1)");

    var larger = HyperLogLog.of (1.5);
    assert (larger.isError ());
    assert (larger.unwrapError () is HyperLogLogError.INVALID_ARGUMENT);
    assert (larger.unwrapError ().message == "errorRate must be in range (0, 1)");

    var nanRate = HyperLogLog.of (double.NAN);
    assert (nanRate.isError ());
    assert (nanRate.unwrapError () is HyperLogLogError.INVALID_ARGUMENT);
}
