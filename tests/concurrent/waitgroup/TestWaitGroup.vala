using Vala.Concurrent;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/concurrent/waitgroup/testBasic", testBasic);
    Test.add_func ("/concurrent/waitgroup/testWaitBlocksUntilDone", testWaitBlocksUntilDone);
    Test.run ();
}

void testBasic () {
    Vala.Concurrent.WaitGroup wg = new Vala.Concurrent.WaitGroup ();
    int completed = 0;

    wg.add (2);

    Thread<void*> t1 = new Thread<void*> ("worker1", () => {
        Posix.usleep (20000);
        completed++;
        wg.done ();
        return null;
    });

    Thread<void*> t2 = new Thread<void*> ("worker2", () => {
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

    Thread<void*> worker = new Thread<void*> ("worker", () => {
        Posix.usleep (50000);
        worker_done = true;
        wg.done ();
        return null;
    });

    wg.wait ();
    worker.join ();

    assert (worker_done == true);
}
