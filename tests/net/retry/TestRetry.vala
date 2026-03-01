using Vala.Net;
using Vala.Collections;
using Vala.Time;

errordomain RetryTestError {
    FAIL
}

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/net/retry/testRetryImmediateSuccess", testRetryImmediateSuccess);
    Test.add_func ("/net/retry/testRetryEventuallySuccess", testRetryEventuallySuccess);
    Test.add_func ("/net/retry/testRetryStopsByPredicate", testRetryStopsByPredicate);
    Test.add_func ("/net/retry/testRetryResult", testRetryResult);
    Test.add_func ("/net/retry/testRetryVoid", testRetryVoid);
    Test.add_func ("/net/retry/testRetryVoidFailure", testRetryVoidFailure);
    Test.add_func ("/net/retry/testHttpStatusRetry503", testHttpStatusRetry503);
    Test.add_func ("/net/retry/testHttpStatusRetry404", testHttpStatusRetry404);
    Test.add_func ("/net/retry/testNetworkDefault", testNetworkDefault);
    Test.add_func ("/net/retry/testIoDefault", testIoDefault);
    Test.add_func ("/net/retry/testInvalidConfigurations", testInvalidConfigurations);
    Test.run ();
}

Retry mustRetryWithFixedDelay (int attempts, Duration delay) {
    var retry = new Retry ();
    try {
        retry.withMaxAttempts (attempts)
         .withFixedDelay (delay);
    } catch (RetryError e) {
        assert_not_reached ();
    }
    return retry;
}

void testRetryImmediateSuccess () {
    Retry retry = mustRetryWithFixedDelay (3, Duration.ofSeconds (0));
    int calls = 0;

    bool ok = retry.retry (() => {
        calls++;
        return true;
    });

    assert (ok == true);
    assert (calls == 1);
}

void testRetryEventuallySuccess () {
    Retry retry = mustRetryWithFixedDelay (4, Duration.ofSeconds (0));
    int calls = 0;

    bool ok = retry.retry (() => {
        calls++;
        return calls >= 3;
    });

    assert (ok == true);
    assert (calls == 3);
}

void testRetryStopsByPredicate () {
    Retry retry = mustRetryWithFixedDelay (5, Duration.ofSeconds (0))
                   .withRetryOn ((reason) => {
        return false;
    });
    int calls = 0;

    bool ok = retry.retry (() => {
        calls++;
        return false;
    });

    assert (ok == false);
    assert (calls == 1);
}

void testRetryResult () {
    Retry retry = mustRetryWithFixedDelay (3, Duration.ofSeconds (0));
    int calls = 0;

    string ? result = retry.retryResult<string ?> (() => {
        calls++;
        if (calls < 2) {
            return null;
        }
        return "ok";
    });

    assert (result == "ok");
    assert (calls == 2);
}

void testRetryVoid () {
    Retry retry = mustRetryWithFixedDelay (3, Duration.ofSeconds (0));
    int calls = 0;

    bool ok = retry.retryVoid (() => {
        calls++;
        if (calls < 2) {
            throw new RetryTestError.FAIL ("temporary");
        }
    });

    assert (ok == true);
    assert (calls == 2);
}

void testRetryVoidFailure () {
    Retry retry = mustRetryWithFixedDelay (2, Duration.ofSeconds (0));
    int calls = 0;

    bool ok = retry.retryVoid (() => {
        calls++;
        throw new RetryTestError.FAIL ("permanent");
    });

    assert (ok == false);
    assert (calls == 2);
}

void testHttpStatusRetry503 () {
    var codes = new ArrayList<int> ();
    codes.add (503);

    Retry retry = mustRetryWithFixedDelay (3, Duration.ofSeconds (0))
                   .httpStatusRetry (codes);

    int calls = 0;
    bool ok = retry.retryVoid (() => {
        calls++;
        if (calls == 1) {
            throw new RetryTestError.FAIL ("HTTP 503 Service Unavailable");
        }
    });

    assert (ok == true);
    assert (calls == 2);
}

void testHttpStatusRetry404 () {
    var codes = new ArrayList<int> ();
    codes.add (503);

    Retry retry = mustRetryWithFixedDelay (3, Duration.ofSeconds (0))
                   .httpStatusRetry (codes);

    int calls = 0;
    bool ng = retry.retryVoid (() => {
        calls++;
        throw new RetryTestError.FAIL ("HTTP 404 Not Found");
    });

    assert (ng == false);
    assert (calls == 1);
}

void testNetworkDefault () {
    Retry retry = Retry.networkDefault ();
    try {
        retry.withMaxAttempts (2)
         .withFixedDelay (Duration.ofSeconds (0));
    } catch (RetryError e) {
        assert_not_reached ();
    }
    int callbacks = 0;

    retry.onRetry ((attempt, reason, delayMillis) => {
        callbacks++;
        assert (attempt == 1);
        assert (delayMillis >= 0);
    });

    int calls = 0;
    bool ok = retry.retry (() => {
        calls++;
        return calls == 2;
    });

    assert (ok == true);
    assert (callbacks == 1);
}

void testIoDefault () {
    Retry retry = Retry.ioDefault ();
    try {
        retry.withMaxAttempts (2)
         .withFixedDelay (Duration.ofSeconds (0));
    } catch (RetryError e) {
        assert_not_reached ();
    }

    int calls = 0;
    bool ok = retry.retry (() => {
        calls++;
        return false;
    });

    assert (ok == false);
    assert (calls == 2);
}

void testInvalidConfigurations () {
    var retry = new Retry ();

    bool maxAttemptsThrown = false;
    try {
        retry.withMaxAttempts (0);
    } catch (RetryError e) {
        maxAttemptsThrown = true;
        assert (e is RetryError.INVALID_ARGUMENT);
    }
    assert (maxAttemptsThrown);

    bool backoffInitialThrown = false;
    try {
        retry.withBackoff (Duration.ofSeconds (-1), Duration.ofSeconds (1));
    } catch (RetryError e) {
        backoffInitialThrown = true;
        assert (e is RetryError.INVALID_ARGUMENT);
    }
    assert (backoffInitialThrown);

    bool backoffRangeThrown = false;
    try {
        retry.withBackoff (Duration.ofSeconds (2), Duration.ofSeconds (1));
    } catch (RetryError e) {
        backoffRangeThrown = true;
        assert (e is RetryError.INVALID_ARGUMENT);
    }
    assert (backoffRangeThrown);

    bool backoffMaxThrown = false;
    try {
        retry.withBackoff (Duration.ofSeconds (1), Duration.ofSeconds (-1));
    } catch (RetryError e) {
        backoffMaxThrown = true;
        assert (e is RetryError.INVALID_ARGUMENT);
    }
    assert (backoffMaxThrown);

    bool fixedDelayThrown = false;
    try {
        retry.withFixedDelay (Duration.ofSeconds (-1));
    } catch (RetryError e) {
        fixedDelayThrown = true;
        assert (e is RetryError.INVALID_ARGUMENT);
    }
    assert (fixedDelayThrown);
}
