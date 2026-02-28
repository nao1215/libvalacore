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
    Test.add_func ("/net/retry/testHttpStatusRetry", testHttpStatusRetry);
    Test.add_func ("/net/retry/testNetworkDefault", testNetworkDefault);
    Test.add_func ("/net/retry/testIoDefault", testIoDefault);
    Test.run ();
}

void testRetryImmediateSuccess () {
    Retry retry = new Retry ().withMaxAttempts (3)
                   .withFixedDelay (Duration.ofSeconds (0));
    int calls = 0;

    bool ok = retry.retry (() => {
        calls++;
        return true;
    });

    assert (ok == true);
    assert (calls == 1);
}

void testRetryEventuallySuccess () {
    Retry retry = new Retry ().withMaxAttempts (4)
                   .withFixedDelay (Duration.ofSeconds (0));
    int calls = 0;

    bool ok = retry.retry (() => {
        calls++;
        return calls >= 3;
    });

    assert (ok == true);
    assert (calls == 3);
}

void testRetryStopsByPredicate () {
    Retry retry = new Retry ().withMaxAttempts (5)
                   .withFixedDelay (Duration.ofSeconds (0))
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
    Retry retry = new Retry ().withMaxAttempts (3)
                   .withFixedDelay (Duration.ofSeconds (0));
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
    Retry retry = new Retry ().withMaxAttempts (3)
                   .withFixedDelay (Duration.ofSeconds (0));
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
    Retry retry = new Retry ().withMaxAttempts (2)
                   .withFixedDelay (Duration.ofSeconds (0));
    int calls = 0;

    bool ok = retry.retryVoid (() => {
        calls++;
        throw new RetryTestError.FAIL ("permanent");
    });

    assert (ok == false);
    assert (calls == 2);
}

void testHttpStatusRetry () {
    var codes = new ArrayList<int> ();
    codes.add (503);

    Retry retry = new Retry ().withMaxAttempts (3)
                   .withFixedDelay (Duration.ofSeconds (0))
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

    calls = 0;
    bool ng = retry.retryVoid (() => {
        calls++;
        throw new RetryTestError.FAIL ("HTTP 404 Not Found");
    });

    assert (ng == false);
    assert (calls == 1);
}

void testNetworkDefault () {
    Retry retry = Retry.networkDefault ().withMaxAttempts (2)
                   .withFixedDelay (Duration.ofSeconds (0));
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
    Retry retry = Retry.ioDefault ().withMaxAttempts (2)
                   .withFixedDelay (Duration.ofSeconds (0));

    int calls = 0;
    bool ok = retry.retry (() => {
        calls++;
        return false;
    });

    assert (ok == false);
    assert (calls == 2);
}
