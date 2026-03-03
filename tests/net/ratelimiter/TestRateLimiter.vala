using Vala.Net;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/net/ratelimiter/testAllow", testAllow);
    Test.add_func ("/net/ratelimiter/testAllowN", testAllowN);
    Test.add_func ("/net/ratelimiter/testReserve", testReserve);
    Test.add_func ("/net/ratelimiter/testWait", testWait);
    Test.add_func ("/net/ratelimiter/testSetRateAndReset", testSetRateAndReset);
    Test.add_func ("/net/ratelimiter/testInvalidArguments", testInvalidArguments);
    Test.run ();
}

RateLimiter mustRateLimiter (int permits_per_second, int burst) {
    var created = RateLimiter.of (permits_per_second);
    assert (created.isOk ());
    RateLimiter limiter = created.unwrap ();

    var configured = limiter.withBurst (burst);
    assert (configured.isOk ());
    return limiter;
}

void assertInvalidArgument<T> (Vala.Collections.Result<T, GLib.Error> result, string expected_message) {
    assert (result.isError ());
    var err = result.unwrapError ();
    assert (err is RateLimiterError.INVALID_ARGUMENT);
    assert (err.message == expected_message);
}

void testAllow () {
    var limiter = mustRateLimiter (1, 1);

    assert (limiter.allow () == true);
    assert (limiter.allow () == false);
}

void testAllowN () {
    var limiter = mustRateLimiter (10, 3);

    var allow2 = limiter.allowN (2);
    assert (allow2.isOk ());
    assert (allow2.unwrap () == true);

    allow2 = limiter.allowN (2);
    assert (allow2.isOk ());
    assert (allow2.unwrap () == false);

    assert (limiter.availableTokens () <= 1);
}

void testReserve () {
    var limiter = mustRateLimiter (1, 1);

    assert (limiter.allow () == true);

    int64 reserve = limiter.reserve ();
    assert (reserve > 0);
    assert (reserve <= 1000);
}

void testWait () {
    var limiter = mustRateLimiter (100, 1);

    assert (limiter.allow () == true);

    int64 start = GLib.get_monotonic_time ();
    limiter.wait ();
    int64 elapsed_millis = (GLib.get_monotonic_time () - start) / 1000;

    assert (elapsed_millis >= 1);
    assert (elapsed_millis < 1000);
}

void testSetRateAndReset () {
    var limiter = mustRateLimiter (1, 1);

    assert (limiter.allow () == true);
    assert (limiter.allow () == false);

    var setRate = limiter.setRate (1000);
    assert (setRate.isOk ());
    assert (setRate.unwrap () == true);
    limiter.reset ();

    assert (limiter.allow () == true);
}

void testInvalidArguments () {
    var invalidCtor = RateLimiter.of (0);
    assertInvalidArgument<RateLimiter> (invalidCtor, "permitsPerSecond must be positive, got 0");

    var limiter = mustRateLimiter (1, 1);

    var invalidBurst = limiter.withBurst (0);
    assertInvalidArgument<RateLimiter> (invalidBurst, "permits must be positive, got 0");

    var invalidAllowN = limiter.allowN (0);
    assertInvalidArgument<bool> (invalidAllowN, "permits must be positive, got 0");

    var invalidWaitN = limiter.waitN (0);
    assertInvalidArgument<bool> (invalidWaitN, "permits must be positive, got 0");

    var impossibleWaitN = limiter.waitN (2);
    assertInvalidArgument<bool> (impossibleWaitN, "permits must not exceed burst capacity (1), got 2");

    var invalidSetRate = limiter.setRate (0);
    assertInvalidArgument<bool> (invalidSetRate, "permitsPerSecond must be positive, got 0");
}
