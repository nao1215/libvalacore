using Vala.Concurrent;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/concurrent/mutex/testLockUnlock", testLockUnlock);
    Test.add_func ("/concurrent/mutex/testTryLock", testTryLock);
    Test.add_func ("/concurrent/mutex/testWithLock", testWithLock);
    Test.add_func ("/concurrent/mutex/testConcurrentIncrement", testConcurrentIncrement);
    Test.run ();
}

void testLockUnlock () {
    Vala.Concurrent.Mutex mutex = new Vala.Concurrent.Mutex ();
    mutex.lock ();
    mutex.unlock ();
}

void testTryLock () {
    Vala.Concurrent.Mutex mutex = new Vala.Concurrent.Mutex ();
    mutex.lock ();

    bool acquired = true;
    Thread<void*> worker = new Thread<void*> ("trylock", () => {
        acquired = mutex.tryLock ();
        if (acquired) {
            mutex.unlock ();
        }
        return null;
    });
    worker.join ();

    assert (acquired == false);
    mutex.unlock ();
}

void testWithLock () {
    Vala.Concurrent.Mutex mutex = new Vala.Concurrent.Mutex ();
    int value = 0;

    mutex.withLock (() => {
        value++;
    });

    assert (value == 1);
}

void testConcurrentIncrement () {
    Vala.Concurrent.Mutex mutex = new Vala.Concurrent.Mutex ();
    int value = 0;

    Thread<void*> t1 = new Thread<void*> ("worker1", () => {
        for (int i = 0; i < 1000; i++) {
            mutex.withLock (() => {
                value++;
            });
        }
        return null;
    });

    Thread<void*> t2 = new Thread<void*> ("worker2", () => {
        for (int i = 0; i < 1000; i++) {
            mutex.withLock (() => {
                value++;
            });
        }
        return null;
    });

    t1.join ();
    t2.join ();

    assert (value == 2000);
}
