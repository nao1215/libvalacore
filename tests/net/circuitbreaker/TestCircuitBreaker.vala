using Vala.Net;
using Vala.Time;
using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/net/circuitbreaker/testOpenAfterThreshold", testOpenAfterThreshold);
    Test.add_func ("/net/circuitbreaker/testOpenShortCircuit", testOpenShortCircuit);
    Test.add_func ("/net/circuitbreaker/testHalfOpenToClosed", testHalfOpenToClosed);
    Test.add_func ("/net/circuitbreaker/testHalfOpenFailureReopens", testHalfOpenFailureReopens);
    Test.add_func ("/net/circuitbreaker/testStateChangeCallback", testStateChangeCallback);
    Test.add_func ("/net/circuitbreaker/testReset", testReset);
    Test.add_func ("/net/circuitbreaker/testInvalidConfiguration", testInvalidConfiguration);
    Test.run ();
}

CircuitBreaker mustBreaker (string name) {
    CircuitBreaker ? breaker = null;
    try {
        breaker = new CircuitBreaker (name);
    } catch (CircuitBreakerError e) {
        assert_not_reached ();
    }
    if (breaker == null) {
        assert_not_reached ();
    }
    return breaker;
}

void testOpenAfterThreshold () {
    var cb = mustBreaker ("api");
    try {
        cb.withFailureThreshold (2);
    } catch (CircuitBreakerError e) {
        assert_not_reached ();
    }

    assert (cb.state () == CircuitState.CLOSED);

    Result<string, string> r1 = cb.call<string> (() => {
        return Result.error<string, string> ("failed");
    });
    Result<string, string> r2 = cb.call<string> (() => {
        return Result.error<string, string> ("failed");
    });

    assert (r1.isError ());
    assert (r2.isError ());
    assert (cb.state () == CircuitState.OPEN);
}

void testOpenShortCircuit () {
    var cb = mustBreaker ("api");
    try {
        cb.withFailureThreshold (1)
         .withOpenTimeout (Duration.ofSeconds (10));
    } catch (CircuitBreakerError e) {
        assert_not_reached ();
    }

    cb.call<string> (() => { return Result.error<string, string> ("boom"); });
    assert (cb.state () == CircuitState.OPEN);

    int calls = 0;
    Result<string, string> blocked = cb.call<string> (() => {
        calls++;
        return Result.ok<string, string> ("ok");
    });

    assert (blocked.isError ());
    assert (calls == 0);
}

void testHalfOpenToClosed () {
    var cb = mustBreaker ("api");
    try {
        cb.withFailureThreshold (1)
         .withSuccessThreshold (1)
         .withOpenTimeout (Duration.ofSeconds (0));
    } catch (CircuitBreakerError e) {
        assert_not_reached ();
    }

    cb.call<string> (() => {
        return Result.error<string, string> ("first attempt failed");
    });

    Result<string, string> ok = cb.call<string> (() => {
        return Result.ok<string, string> ("ok");
    });

    assert (ok.isOk ());
    assert (ok.unwrap () == "ok");
    assert (cb.state () == CircuitState.CLOSED);
}

void testHalfOpenFailureReopens () {
    var cb = mustBreaker ("api");
    try {
        cb.withFailureThreshold (1)
         .withOpenTimeout (Duration.ofSeconds (1));
    } catch (CircuitBreakerError e) {
        assert_not_reached ();
    }

    cb.call<string> (() => {
        return Result.error<string, string> ("initial failure");
    });
    assert (cb.state () == CircuitState.OPEN);
    Posix.usleep (1100 * 1000);
    assert (cb.state () == CircuitState.HALF_OPEN);

    int calls = 0;
    Result<string, string> result = cb.call<string> (() => {
        calls++;
        return Result.error<string, string> ("half-open probe failed");
    });

    assert (result.isError ());
    assert (calls == 1);
    assert (cb.state () == CircuitState.OPEN);
}

void testStateChangeCallback () {
    var cb = mustBreaker ("api");
    try {
        cb.withFailureThreshold (1)
         .withOpenTimeout (Duration.ofSeconds (0));
    } catch (CircuitBreakerError e) {
        assert_not_reached ();
    }

    int transitions = 0;
    cb.onStateChange ((from, to) => {
        transitions++;
        assert (from != to);
    });

    cb.call<string> (() => { return Result.error<string, string> ("failed"); });
    cb.call<string> (() => { return Result.ok<string, string> ("ok"); });

    assert (transitions >= 2);
}

void testReset () {
    var cb = mustBreaker ("api");
    try {
        cb.withFailureThreshold (2);
    } catch (CircuitBreakerError e) {
        assert_not_reached ();
    }

    cb.recordFailure ();
    assert (cb.failureCount () == 1);

    cb.reset ();

    assert (cb.state () == CircuitState.CLOSED);
    assert (cb.failureCount () == 0);
    assert (cb.name () == "api");
}

void testInvalidConfiguration () {
    bool nameThrown = false;
    try {
        new CircuitBreaker ("");
    } catch (CircuitBreakerError e) {
        nameThrown = true;
        assert (e is CircuitBreakerError.INVALID_ARGUMENT);
    }
    assert (nameThrown);

    var cb = mustBreaker ("api");

    bool failureThresholdThrown = false;
    try {
        cb.withFailureThreshold (0);
    } catch (CircuitBreakerError e) {
        failureThresholdThrown = true;
        assert (e is CircuitBreakerError.INVALID_ARGUMENT);
    }
    assert (failureThresholdThrown);

    bool successThresholdThrown = false;
    try {
        cb.withSuccessThreshold (0);
    } catch (CircuitBreakerError e) {
        successThresholdThrown = true;
        assert (e is CircuitBreakerError.INVALID_ARGUMENT);
    }
    assert (successThresholdThrown);

    bool openTimeoutThrown = false;
    try {
        cb.withOpenTimeout (Duration.ofSeconds (-1));
    } catch (CircuitBreakerError e) {
        openTimeoutThrown = true;
        assert (e is CircuitBreakerError.INVALID_ARGUMENT);
    }
    assert (openTimeoutThrown);
}
