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

T mustOk<T> (Vala.Collections.Result<T, GLib.Error> result) {
    assert (result.isOk ());
    return result.unwrap ();
}

int mustDoInt (SingleFlight group, string key, owned SingleFlightFunc<int> fn) {
    return mustOk<int> (group.@do<int> (key, fn));
}

CountDownLatch mustLatch (int count) {
    return mustOk<CountDownLatch> (CountDownLatch.of (count));
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
    var started = mustLatch (1);
    var release = mustLatch (1);
    var done = mustLatch (2);

    int called = 0;
    int first = 0;
    int second = 0;

    new GLib.Thread<void *> ("singleflight-test-1", () => {
        var result = group.@do<int> ("same-key", () => {
            called++;
            started.countDown ();
            release.@await ();
            return 7;
        });
        first = mustOk<int> (result);
        done.countDown ();
        return null;
    });

    started.@await ();

    new GLib.Thread<void *> ("singleflight-test-2", () => {
        var result = group.@do<int> ("same-key", () => {
            called += 100;
            return 999;
        });
        second = mustOk<int> (result);
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
    var started = mustLatch (1);
    var release = mustLatch (1);
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
    var started = mustLatch (1);
    var release = mustLatch (1);
    var done = mustLatch (1);

    new GLib.Thread<void *> ("singleflight-test-forget", () => {
        var result = group.@do<int> ("forget-key", () => {
            started.countDown ();
            release.@await ();
            return 1;
        });
        assert (mustOk<int> (result) == 1);
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
    var started = mustLatch (2);
    var release = mustLatch (1);

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
    var result = group.@do<int> ("", () => {
        return 0;
    });
    assert (result.isError ());
    assert (result.unwrapError () is SingleFlightError.INVALID_ARGUMENT);
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
    var started = mustLatch (1);
    var release = mustLatch (1);
    var done = mustLatch (1);

    new GLib.Thread<void *> ("singleflight-type-mismatch", () => {
        var result = group.@do<int> ("mixed-key", () => {
            started.countDown ();
            release.@await ();
            return 10;
        });
        assert (mustOk<int> (result) == 10);
        done.countDown ();
        return null;
    });

    started.@await ();

    var mismatch = group.@do<string> ("mixed-key", () => {
        return "x";
    });
    assert (mismatch.isError ());
    assert (mismatch.unwrapError () is SingleFlightError.TYPE_MISMATCH);

    release.countDown ();
    done.@await ();
}
