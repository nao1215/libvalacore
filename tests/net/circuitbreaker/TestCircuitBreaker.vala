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
    var created = CircuitBreaker.of (name);
    assert (created.isOk ());
    return created.unwrap ();
}

void testOpenAfterThreshold () {
    var cb = mustBreaker ("api");
    var configured = cb.withFailureThreshold (2);
    assert (configured.isOk ());

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
    var configured = cb.withFailureThreshold (1);
    assert (configured.isOk ());
    configured = cb.withOpenTimeout (Duration.ofSeconds (10));
    assert (configured.isOk ());

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
    var configured = cb.withFailureThreshold (1);
    assert (configured.isOk ());
    configured = cb.withSuccessThreshold (1);
    assert (configured.isOk ());
    configured = cb.withOpenTimeout (Duration.ofSeconds (0));
    assert (configured.isOk ());

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
    var configured = cb.withFailureThreshold (1);
    assert (configured.isOk ());
    configured = cb.withOpenTimeout (Duration.ofSeconds (1));
    assert (configured.isOk ());

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
    var configured = cb.withFailureThreshold (1);
    assert (configured.isOk ());
    configured = cb.withOpenTimeout (Duration.ofSeconds (0));
    assert (configured.isOk ());

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
    var configured = cb.withFailureThreshold (2);
    assert (configured.isOk ());

    cb.recordFailure ();
    assert (cb.failureCount () == 1);

    cb.reset ();

    assert (cb.state () == CircuitState.CLOSED);
    assert (cb.failureCount () == 0);
    assert (cb.name () == "api");
}

void testInvalidConfiguration () {
    var invalidName = CircuitBreaker.of ("");
    assert (invalidName.isError ());
    var invalidNameErr = invalidName.unwrapError ();
    assert (invalidNameErr is CircuitBreakerError.INVALID_ARGUMENT);
    assert (invalidNameErr.message == "name must not be empty");

    var cb = mustBreaker ("api");

    var invalidFailureThreshold = cb.withFailureThreshold (0);
    assert (invalidFailureThreshold.isError ());
    var invalidFailureThresholdErr = invalidFailureThreshold.unwrapError ();
    assert (invalidFailureThresholdErr is CircuitBreakerError.INVALID_ARGUMENT);
    assert (invalidFailureThresholdErr.message == "n must be positive, got 0");

    var invalidSuccessThreshold = cb.withSuccessThreshold (0);
    assert (invalidSuccessThreshold.isError ());
    var invalidSuccessThresholdErr = invalidSuccessThreshold.unwrapError ();
    assert (invalidSuccessThresholdErr is CircuitBreakerError.INVALID_ARGUMENT);
    assert (invalidSuccessThresholdErr.message == "n must be positive, got 0");

    var invalidOpenTimeout = cb.withOpenTimeout (Duration.ofSeconds (-1));
    assert (invalidOpenTimeout.isError ());
    var invalidOpenTimeoutErr = invalidOpenTimeout.unwrapError ();
    assert (invalidOpenTimeoutErr is CircuitBreakerError.INVALID_ARGUMENT);
    assert (invalidOpenTimeoutErr.message == "timeout must be non-negative, got -1000");
}
