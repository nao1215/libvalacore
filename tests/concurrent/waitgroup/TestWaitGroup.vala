using Vala.Concurrent;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/concurrent/waitgroup/testBasic", testBasic);
    Test.add_func ("/concurrent/waitgroup/testWaitBlocksUntilDone", testWaitBlocksUntilDone);
    Test.add_func ("/concurrent/waitgroup/testDoneUnderflowNoOp", testDoneUnderflowNoOp);
    Test.run ();
}

void testBasic () {
    Vala.Concurrent.WaitGroup wg = new Vala.Concurrent.WaitGroup ();
    int completed = 0;

    wg.add (2);

    Thread<void *> t1 = new Thread<void *> ("worker1", () => {
        Posix.usleep (20000);
        completed++;
        wg.done ();
        return null;
    });

    Thread<void *> t2 = new Thread<void *> ("worker2", () => {
        Posix.usleep (20000);
        completed++;
        wg.done ();
        return null;
    });

    wg.wait ();
    t1.join ();
    t2.join ();

    assert (completed == 2);
}

void testWaitBlocksUntilDone () {
    Vala.Concurrent.WaitGroup wg = new Vala.Concurrent.WaitGroup ();
    bool worker_done = false;

    wg.add (1);

    Thread<void *> worker = new Thread<void *> ("worker", () => {
        Posix.usleep (50000);
        worker_done = true;
        wg.done ();
        return null;
    });

    wg.wait ();
    worker.join ();

    assert (worker_done == true);
}

void testDoneUnderflowNoOp () {
    Vala.Concurrent.WaitGroup wg = new Vala.Concurrent.WaitGroup ();

    int64 start = GLib.get_monotonic_time ();
    Test.expect_message (
        null,
        GLib.LogLevelFlags.LEVEL_WARNING,
        "*WaitGroup counter cannot be negative*"
    );
    wg.done ();
    Test.assert_expected_messages ();
    wg.wait ();
    int64 first_wait_millis = (GLib.get_monotonic_time () - start) / 1000;
    assert (first_wait_millis < 50);

    start = GLib.get_monotonic_time ();
    wg.add (1);
    wg.done ();
    wg.wait ();
    int64 second_wait_millis = (GLib.get_monotonic_time () - start) / 1000;
    assert (second_wait_millis < 50);
}
