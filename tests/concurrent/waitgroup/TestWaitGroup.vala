using Vala.Concurrent;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/concurrent/waitgroup/testBasic", testBasic);
    Test.add_func ("/concurrent/waitgroup/testWaitBlocksUntilDone", testWaitBlocksUntilDone);
    Test.add_func ("/concurrent/waitgroup/testDoneUnderflowNoOp", testDoneUnderflowNoOp);
    Test.add_func ("/concurrent/waitgroup/testWaitForNonBlocking", testWaitForNonBlocking);
    Test.add_func ("/concurrent/waitgroup/testWaitForTimeout", testWaitForTimeout);
    Test.add_func ("/concurrent/waitgroup/testWaitForSuccessBeforeTimeout", testWaitForSuccessBeforeTimeout);
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

    Test.expect_message (
        null,
        GLib.LogLevelFlags.LEVEL_WARNING,
        "*WaitGroup counter cannot be negative*"
    );
    wg.done ();
    Test.assert_expected_messages ();
    wg.wait ();

    wg.add (1);
    wg.done ();
    wg.wait ();
}

void testWaitForNonBlocking () {
    Vala.Concurrent.WaitGroup wg = new Vala.Concurrent.WaitGroup ();

    var ready = wg.waitFor (0);
    assert (ready.isOk ());

    wg.add (1);
    var timeout = wg.waitFor (0);
    assert (timeout.isError ());
    GLib.Error timeout_error = timeout.unwrapError ();
    assert (timeout_error is WaitGroupError.TIMEOUT);
}

void testWaitForTimeout () {
    Vala.Concurrent.WaitGroup wg = new Vala.Concurrent.WaitGroup ();
    wg.add (1);

    var waited = wg.waitFor (10);
    assert (waited.isError ());
    GLib.Error err = waited.unwrapError ();
    assert (err is WaitGroupError.TIMEOUT);
    assert (err.message.index_of ("timeout=10ms") >= 0);
}

void testWaitForSuccessBeforeTimeout () {
    Vala.Concurrent.WaitGroup wg = new Vala.Concurrent.WaitGroup ();
    wg.add (1);

    Thread<void *> worker = new Thread<void *> ("worker-waitfor", () => {
        Posix.usleep (10000);
        wg.done ();
        return null;
    });

    var waited = wg.waitFor (1000);
    worker.join ();
    assert (waited.isOk ());
}
