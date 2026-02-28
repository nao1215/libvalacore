using Vala.Lang;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/lang/threads/testConstruct", testConstruct);
    Test.add_func ("/lang/threads/testSleepMillis", testSleepMillis);
    Test.add_func ("/lang/threads/testSleepMillisNoop", testSleepMillisNoop);
    Test.run ();
}

void testConstruct () {
    Threads threads = new Threads ();
    assert (threads != null);
}

void testSleepMillis () {
    int64 start = GLib.get_monotonic_time ();
    Threads.sleepMillis (20);
    int64 elapsedMicros = GLib.get_monotonic_time () - start;

    assert (elapsedMicros >= 15000);
}

void testSleepMillisNoop () {
    int64 start = GLib.get_monotonic_time ();
    Threads.sleepMillis (0);
    Threads.sleepMillis (-1);
    int64 elapsedMicros = GLib.get_monotonic_time () - start;
    assert (elapsedMicros < 10000);
}
