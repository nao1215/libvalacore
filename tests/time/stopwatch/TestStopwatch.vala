using Vala.Time;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/stopwatch/testStartStop", testStartStop);
    Test.add_func ("/stopwatch/testReset", testReset);
    Test.add_func ("/stopwatch/testStopWithoutStart", testStopWithoutStart);
    Test.add_func ("/stopwatch/testAccumulate", testAccumulate);
    Test.run ();
}

void testStartStop () {
    Stopwatch sw = new Stopwatch ();
    sw.start ();
    Posix.usleep (50000);
    sw.stop ();

    int64 elapsed = sw.elapsedMillis ();
    assert (elapsed >= 10);
    assert (elapsed < 2000);
}

void testReset () {
    Stopwatch sw = new Stopwatch ();
    sw.start ();
    Posix.usleep (30000);
    sw.stop ();

    assert (sw.elapsedMillis () > 0);
    sw.reset ();
    assert (sw.elapsedMillis () == 0);
    assert (sw.elapsed ().toMillis () == 0);
}

void testStopWithoutStart () {
    Stopwatch sw = new Stopwatch ();
    sw.stop ();
    assert (sw.elapsedMillis () == 0);
}

void testAccumulate () {
    Stopwatch sw = new Stopwatch ();

    sw.start ();
    Posix.usleep (20000);
    sw.stop ();
    int64 first = sw.elapsedMillis ();

    sw.start ();
    Posix.usleep (20000);
    sw.stop ();
    int64 second = sw.elapsedMillis ();

    assert (first >= 5);
    assert (second > first);
}
