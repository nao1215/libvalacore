using Vala.Net;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/net/ratelimiter/testAllow", testAllow);
    Test.add_func ("/net/ratelimiter/testAllowN", testAllowN);
    Test.add_func ("/net/ratelimiter/testReserve", testReserve);
    Test.add_func ("/net/ratelimiter/testWait", testWait);
    Test.add_func ("/net/ratelimiter/testSetRateAndReset", testSetRateAndReset);
    Test.run ();
}

void testAllow () {
    var limiter = new RateLimiter (1).withBurst (1);

    assert (limiter.allow () == true);
    assert (limiter.allow () == false);
}

void testAllowN () {
    var limiter = new RateLimiter (10).withBurst (3);

    assert (limiter.allowN (2) == true);
    assert (limiter.allowN (2) == false);
    assert (limiter.availableTokens () <= 1);
}

void testReserve () {
    var limiter = new RateLimiter (1).withBurst (1);

    assert (limiter.allow () == true);

    int64 reserve = limiter.reserve ();
    assert (reserve > 0);
    assert (reserve <= 1000);
}

void testWait () {
    var limiter = new RateLimiter (100).withBurst (1);

    assert (limiter.allow () == true);

    int64 start = GLib.get_monotonic_time ();
    limiter.wait ();
    int64 elapsed_millis = (GLib.get_monotonic_time () - start) / 1000;

    assert (elapsed_millis >= 1);
    assert (elapsed_millis < 1000);
}

void testSetRateAndReset () {
    var limiter = new RateLimiter (1).withBurst (1);

    assert (limiter.allow () == true);
    assert (limiter.allow () == false);

    limiter.setRate (1000);
    limiter.reset ();

    assert (limiter.allow () == true);
}
