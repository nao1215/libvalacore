using Vala.Concurrent;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/concurrent/semaphore/testAcquireRelease", testAcquireRelease);
    Test.add_func ("/concurrent/semaphore/testTryAcquire", testTryAcquire);
    Test.add_func ("/concurrent/semaphore/testAcquireBlocks", testAcquireBlocks);
    Test.run ();
}

void testAcquireRelease () {
    Vala.Concurrent.Semaphore sem = new Vala.Concurrent.Semaphore (1);

    assert (sem.availablePermits () == 1);
    sem.acquire ();
    assert (sem.availablePermits () == 0);
    sem.release ();
    assert (sem.availablePermits () == 1);
}

void testTryAcquire () {
    Vala.Concurrent.Semaphore sem = new Vala.Concurrent.Semaphore (1);

    assert (sem.tryAcquire () == true);
    assert (sem.tryAcquire () == false);
    sem.release ();
    assert (sem.tryAcquire () == true);
}

void testAcquireBlocks () {
    Vala.Concurrent.Semaphore sem = new Vala.Concurrent.Semaphore (0);
    bool acquired = false;

    Thread<void*> worker = new Thread<void*> ("worker", () => {
        sem.acquire ();
        acquired = true;
        return null;
    });

    Posix.usleep (30000);
    assert (acquired == false);

    sem.release ();
    worker.join ();
    assert (acquired == true);
}
