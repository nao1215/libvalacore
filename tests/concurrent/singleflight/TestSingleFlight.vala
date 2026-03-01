using Vala.Concurrent;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/concurrent/singleflight/testDo", testDo);
    Test.add_func ("/concurrent/singleflight/testDoSharesExecution", testDoSharesExecution);
    Test.add_func ("/concurrent/singleflight/testDoFutureSharesExecution", testDoFutureSharesExecution);
    Test.add_func ("/concurrent/singleflight/testForget", testForget);
    Test.add_func ("/concurrent/singleflight/testClear", testClear);
    Test.add_func ("/concurrent/singleflight/testDoInvalidKey", testDoInvalidKey);
    Test.add_func ("/concurrent/singleflight/testDoFutureInvalidKey", testDoFutureInvalidKey);
    Test.add_func ("/concurrent/singleflight/testDoTypeMismatch", testDoTypeMismatch);

    Test.run ();
}

int mustDoInt (SingleFlight group, string key, owned SingleFlightFunc<int> fn) {
    int result = 0;
    bool succeeded = false;
    try {
        result = group.@do<int> (key, fn);
        succeeded = true;
    } catch (SingleFlightError e) {
        assert_not_reached ();
    }
    if (!succeeded) {
        assert_not_reached ();
    }
    return result;
}

void testDo () {
    var group = new SingleFlight ();
    int called = 0;

    int value = mustDoInt (group, "k1", () => {
        called++;
        return 42;
    });

    assert (value == 42);
    assert (called == 1);
    assert (group.inFlightCount () == 0);
}

void testDoSharesExecution () {
    var group = new SingleFlight ();
    var started = new CountDownLatch (1);
    var release = new CountDownLatch (1);
    var done = new CountDownLatch (2);

    int called = 0;
    int first = 0;
    int second = 0;

    new GLib.Thread<void *> ("singleflight-test-1", () => {
        try {
            first = group.@do<int> ("same-key", () => {
                called++;
                started.countDown ();
                release.@await ();
                return 7;
            });
        } catch (SingleFlightError e) {
            assert_not_reached ();
        }
        done.countDown ();
        return null;
    });

    started.@await ();

    new GLib.Thread<void *> ("singleflight-test-2", () => {
        try {
            second = group.@do<int> ("same-key", () => {
                called += 100;
                return 999;
            });
        } catch (SingleFlightError e) {
            assert_not_reached ();
        }
        done.countDown ();
        return null;
    });

    Thread.usleep (20 * 1000);
    assert (group.hasInFlight ("same-key") == true);
    assert (group.inFlightCount () == 1);

    release.countDown ();
    done.@await ();

    assert (called == 1);
    assert (first == 7);
    assert (second == 7);
    assert (group.hasInFlight ("same-key") == false);
    assert (group.inFlightCount () == 0);
}

void testDoFutureSharesExecution () {
    var group = new SingleFlight ();
    var started = new CountDownLatch (1);
    var release = new CountDownLatch (1);
    int called = 0;

    Future<int> first = group.doFuture<int> ("future-key", () => {
        called++;
        started.countDown ();
        release.@await ();
        return 55;
    });

    started.@await ();
    Future<int> second = group.doFuture<int> ("future-key", () => {
        called += 100;
        return 1;
    });

    Thread.usleep (20 * 1000);
    assert (group.hasInFlight ("future-key") == true);

    release.countDown ();

    assert (first.@await () == 55);
    assert (second.@await () == 55);
    assert (called == 1);
    assert (group.inFlightCount () == 0);
}

void testForget () {
    var group = new SingleFlight ();
    var started = new CountDownLatch (1);
    var release = new CountDownLatch (1);
    var done = new CountDownLatch (1);

    new GLib.Thread<void *> ("singleflight-test-forget", () => {
        try {
            group.@do<int> ("forget-key", () => {
                started.countDown ();
                release.@await ();
                return 1;
            });
        } catch (SingleFlightError e) {
            assert_not_reached ();
        }
        done.countDown ();
        return null;
    });

    started.@await ();
    assert (group.hasInFlight ("forget-key") == true);

    group.forget ("forget-key");
    assert (group.hasInFlight ("forget-key") == false);
    assert (group.inFlightCount () == 0);

    release.countDown ();
    done.@await ();
}

void testClear () {
    var group = new SingleFlight ();
    var started = new CountDownLatch (2);
    var release = new CountDownLatch (1);

    Future<int> first = group.doFuture<int> ("k1", () => {
        started.countDown ();
        release.@await ();
        return 1;
    });

    Future<int> second = group.doFuture<int> ("k2", () => {
        started.countDown ();
        release.@await ();
        return 2;
    });

    started.@await ();
    assert (group.inFlightCount () == 2);

    group.clear ();
    assert (group.inFlightCount () == 0);
    assert (group.hasInFlight ("k1") == false);
    assert (group.hasInFlight ("k2") == false);

    release.countDown ();
    assert (first.@await () == 1);
    assert (second.@await () == 2);
}

void testDoInvalidKey () {
    var group = new SingleFlight ();
    bool thrown = false;
    try {
        group.@do<int> ("", () => {
            return 0;
        });
    } catch (SingleFlightError e) {
        thrown = true;
        assert (e is SingleFlightError.INVALID_ARGUMENT);
    }
    assert (thrown);
}

void testDoFutureInvalidKey () {
    var group = new SingleFlight ();
    Future<int> future = group.doFuture<int> ("", () => {
        return 1;
    });
    future.@await ();
    assert (future.isFailed () == true);
    assert (future.error () == "key must not be empty");
}

void testDoTypeMismatch () {
    var group = new SingleFlight ();
    var started = new CountDownLatch (1);
    var release = new CountDownLatch (1);
    var done = new CountDownLatch (1);

    new GLib.Thread<void *> ("singleflight-type-mismatch", () => {
        try {
            group.@do<int> ("mixed-key", () => {
                started.countDown ();
                release.@await ();
                return 10;
            });
        } catch (SingleFlightError e) {
            assert_not_reached ();
        }
        done.countDown ();
        return null;
    });

    started.@await ();

    bool thrown = false;
    try {
        group.@do<string> ("mixed-key", () => {
            return "x";
        });
    } catch (SingleFlightError e) {
        thrown = true;
        assert (e is SingleFlightError.TYPE_MISMATCH);
    }
    assert (thrown);

    release.countDown ();
    done.@await ();
}
