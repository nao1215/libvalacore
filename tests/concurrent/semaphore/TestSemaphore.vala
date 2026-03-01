using Vala.Concurrent;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/concurrent/semaphore/testAcquireRelease", testAcquireRelease);
    Test.add_func ("/concurrent/semaphore/testTryAcquire", testTryAcquire);
    Test.add_func ("/concurrent/semaphore/testAcquireBlocks", testAcquireBlocks);
    Test.add_func ("/concurrent/semaphore/testInvalidPermits", testInvalidPermits);
    Test.run ();
}

Semaphore mustSemaphore (int permits) {
    Semaphore ? sem = null;
    try {
        sem = new Semaphore (permits);
    } catch (SemaphoreError e) {
        assert_not_reached ();
    }
    if (sem == null) {
        assert_not_reached ();
    }
    return sem;
}

void testAcquireRelease () {
    Vala.Concurrent.Semaphore sem = mustSemaphore (1);

    assert (sem.availablePermits () == 1);
    sem.acquire ();
    assert (sem.availablePermits () == 0);
    sem.release ();
    assert (sem.availablePermits () == 1);
}

void testTryAcquire () {
    Vala.Concurrent.Semaphore sem = mustSemaphore (1);

    assert (sem.tryAcquire () == true);
    assert (sem.tryAcquire () == false);
    sem.release ();
    assert (sem.tryAcquire () == true);
}

void testAcquireBlocks () {
    Vala.Concurrent.Semaphore sem = mustSemaphore (0);
    GLib.Mutex stateMutex = GLib.Mutex ();
    GLib.Cond stateCond = GLib.Cond ();
    bool entered_wait = false;
    bool acquired = false;

    Thread<void *> worker = new Thread<void *> ("worker", () => {
        stateMutex.lock ();
        entered_wait = true;
        stateCond.signal ();
        stateMutex.unlock ();

        sem.acquire ();
        stateMutex.lock ();
        acquired = true;
        stateCond.signal ();
        stateMutex.unlock ();
        return null;
    });

    stateMutex.lock ();
    int64 timeout = GLib.get_monotonic_time () + 1000000;
    while (!entered_wait) {
        assert (stateCond.wait_until (stateMutex, timeout) == true);
    }
    assert (acquired == false);
    stateMutex.unlock ();

    sem.release ();
    worker.join ();

    stateMutex.lock ();
    assert (acquired == true);
    stateMutex.unlock ();
}

void testInvalidPermits () {
    bool thrown = false;
    try {
        new Semaphore (-1);
    } catch (SemaphoreError e) {
        thrown = true;
        assert (e is SemaphoreError.INVALID_ARGUMENT);
    }
    assert (thrown);
}
