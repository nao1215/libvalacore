using Vala.Concurrent;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/concurrent/semaphore/testAcquireRelease", testAcquireRelease);
    Test.add_func ("/concurrent/semaphore/testTryAcquire", testTryAcquire);
    Test.add_func ("/concurrent/semaphore/testAcquireBlocks", testAcquireBlocks);
    Test.add_func ("/concurrent/semaphore/testAcquireTimeoutNonBlocking", testAcquireTimeoutNonBlocking);
    Test.add_func ("/concurrent/semaphore/testAcquireTimeout", testAcquireTimeout);
    Test.add_func ("/concurrent/semaphore/testAcquireTimeoutInfinite", testAcquireTimeoutInfinite);
    Test.add_func ("/concurrent/semaphore/testInvalidPermits", testInvalidPermits);
    Test.run ();
}

Semaphore mustSemaphore (int permits) {
    var created = Semaphore.of (permits);
    assert (created.isOk ());
    return created.unwrap ();
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

void testAcquireTimeoutNonBlocking () {
    Vala.Concurrent.Semaphore sem = mustSemaphore (1);

    var acquired = sem.acquireTimeout (Vala.Time.Duration.ofSeconds (0));
    assert (acquired.isOk ());

    var timeout = sem.acquireTimeout (Vala.Time.Duration.ofSeconds (0));
    assert (timeout.isError ());
    GLib.Error err = timeout.unwrapError ();
    assert (err is SemaphoreError.TIMEOUT);
}

void testAcquireTimeout () {
    Vala.Concurrent.Semaphore sem = mustSemaphore (0);

    var timeout = sem.acquireTimeout (Vala.Time.Duration.ofSeconds (0));
    assert (timeout.isError ());
    assert (timeout.unwrapError ().message.index_of ("timeout=0ms") >= 0);

    Thread<void *> releaser = new Thread<void *> ("releaser", () => {
        Posix.usleep (10000);
        sem.release ();
        return null;
    });

    var acquired = sem.acquireTimeout (Vala.Time.Duration.ofSeconds (1));
    releaser.join ();
    assert (acquired.isOk ());
}

void testAcquireTimeoutInfinite () {
    Vala.Concurrent.Semaphore sem = mustSemaphore (0);

    Thread<void *> releaser = new Thread<void *> ("releaser-infinite", () => {
        Posix.usleep (10000);
        sem.release ();
        return null;
    });

    var acquired = sem.acquireTimeout (Vala.Time.Duration.ofSeconds (-1));
    releaser.join ();
    assert (acquired.isOk ());
}

void testInvalidPermits () {
    var created = Semaphore.of (-1);
    assert (created.isError ());
    assert (created.unwrapError () is SemaphoreError.INVALID_ARGUMENT);
    assert (created.unwrapError ().message == "permits must be non-negative");
}
