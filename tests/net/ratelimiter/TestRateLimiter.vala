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
    RateLimiter ? limiter = null;
    try {
        limiter = new RateLimiter (permits_per_second);
        limiter.withBurst (burst);
    } catch (RateLimiterError e) {
        assert_not_reached ();
    }
    if (limiter == null) {
        assert_not_reached ();
    }
    return limiter;
}

void testAllow () {
    var limiter = mustRateLimiter (1, 1);

    assert (limiter.allow () == true);
    assert (limiter.allow () == false);
}

void testAllowN () {
    var limiter = mustRateLimiter (10, 3);

    try {
        assert (limiter.allowN (2) == true);
        assert (limiter.allowN (2) == false);
    } catch (RateLimiterError e) {
        assert_not_reached ();
    }
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

    try {
        limiter.setRate (1000);
    } catch (RateLimiterError e) {
        assert_not_reached ();
    }
    limiter.reset ();

    assert (limiter.allow () == true);
}

void testInvalidArguments () {
    bool ctorThrown = false;
    try {
        new RateLimiter (0);
    } catch (RateLimiterError e) {
        ctorThrown = true;
        assert (e is RateLimiterError.INVALID_ARGUMENT);
    }
    assert (ctorThrown);

    var limiter = mustRateLimiter (1, 1);

    bool burstThrown = false;
    try {
        limiter.withBurst (0);
    } catch (RateLimiterError e) {
        burstThrown = true;
        assert (e is RateLimiterError.INVALID_ARGUMENT);
    }
    assert (burstThrown);

    bool allowNThrown = false;
    try {
        limiter.allowN (0);
    } catch (RateLimiterError e) {
        allowNThrown = true;
        assert (e is RateLimiterError.INVALID_ARGUMENT);
    }
    assert (allowNThrown);

    bool waitNThrown = false;
    try {
        limiter.waitN (0);
    } catch (RateLimiterError e) {
        waitNThrown = true;
        assert (e is RateLimiterError.INVALID_ARGUMENT);
    }
    assert (waitNThrown);

    bool setRateThrown = false;
    try {
        limiter.setRate (0);
    } catch (RateLimiterError e) {
        setRateThrown = true;
        assert (e is RateLimiterError.INVALID_ARGUMENT);
    }
    assert (setRateThrown);
}
