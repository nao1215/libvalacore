using Vala.Net;
using Vala.Time;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/net/circuitbreaker/testOpenAfterThreshold", testOpenAfterThreshold);
    Test.add_func ("/net/circuitbreaker/testOpenShortCircuit", testOpenShortCircuit);
    Test.add_func ("/net/circuitbreaker/testHalfOpenToClosed", testHalfOpenToClosed);
    Test.add_func ("/net/circuitbreaker/testHalfOpenFailureReopens", testHalfOpenFailureReopens);
    Test.add_func ("/net/circuitbreaker/testStateChangeCallback", testStateChangeCallback);
    Test.add_func ("/net/circuitbreaker/testReset", testReset);
    Test.run ();
}

void testOpenAfterThreshold () {
    var cb = new CircuitBreaker ("api").withFailureThreshold (2);

    assert (cb.state () == CircuitState.CLOSED);

    string ? r1 = cb.call<string ?> (() => { return null; });
    string ? r2 = cb.call<string ?> (() => { return null; });

    assert (r1 == null);
    assert (r2 == null);
    assert (cb.state () == CircuitState.OPEN);
}

void testOpenShortCircuit () {
    var cb = new CircuitBreaker ("api").withFailureThreshold (1)
              .withOpenTimeout (Duration.ofSeconds (10));

    cb.call<string ?> (() => { return null; });
    assert (cb.state () == CircuitState.OPEN);

    int calls = 0;
    string ? blocked = cb.call<string> (() => {
        calls++;
        return "ok";
    });

    assert (blocked == null);
    assert (calls == 0);
}

void testHalfOpenToClosed () {
    var cb = new CircuitBreaker ("api").withFailureThreshold (1)
              .withSuccessThreshold (1)
              .withOpenTimeout (Duration.ofSeconds (0));

    cb.call<string ?> (() => { return null; });

    string ? ok = cb.call<string> (() => { return "ok"; });

    assert (ok == "ok");
    assert (cb.state () == CircuitState.CLOSED);
}

void testHalfOpenFailureReopens () {
    var cb = new CircuitBreaker ("api").withFailureThreshold (1)
              .withOpenTimeout (Duration.ofSeconds (1));

    cb.call<string ?> (() => { return null; });
    assert (cb.state () == CircuitState.OPEN);

    string ? result = cb.call<string ?> (() => { return "ok"; });

    assert (result == null); // still OPEN; call should be short-circuited
    assert (cb.state () == CircuitState.OPEN);
}

void testStateChangeCallback () {
    var cb = new CircuitBreaker ("api").withFailureThreshold (1)
              .withOpenTimeout (Duration.ofSeconds (0));

    int transitions = 0;
    cb.onStateChange ((from, to) => {
        transitions++;
        assert (from != to);
    });

    cb.withOpenTimeout (Duration.ofSeconds (0));
    cb.call<string ?> (() => { return null; });
    cb.call<string ?> (() => { return "ok"; });

    assert (transitions >= 2);
}

void testReset () {
    var cb = new CircuitBreaker ("api").withFailureThreshold (2);

    cb.recordFailure ();
    assert (cb.failureCount () == 1);

    cb.reset ();

    assert (cb.state () == CircuitState.CLOSED);
    assert (cb.failureCount () == 0);
    assert (cb.name () == "api");
}
