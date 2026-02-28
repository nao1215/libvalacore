using Vala.Io;
using Vala.Time;
using Vala.Lang;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/io/filelock/testTryAcquireAndRelease", testTryAcquireAndRelease);
    Test.add_func ("/io/filelock/testAcquireTimeout", testAcquireTimeout);
    Test.add_func ("/io/filelock/testAcquireAfterRelease", testAcquireAfterRelease);
    Test.add_func ("/io/filelock/testWithLock", testWithLock);
    Test.add_func ("/io/filelock/testOwnerPidUnavailable", testOwnerPidUnavailable);
    Test.add_func ("/io/filelock/testReleaseWithoutAcquire", testReleaseWithoutAcquire);
    Test.run ();
}

void testTryAcquireAndRelease () {
    Vala.Io.Path lockPath = new Vala.Io.Path ("/tmp/valacore/ut/filelock_try.lock");
    Files.remove (lockPath);

    var lock1 = new FileLock (lockPath);
    var lock2 = new FileLock (lockPath);

    assert (lock1.tryAcquire () == true);
    assert (lock1.isHeld () == true);

    int ? ownerPid = lock1.ownerPid ();
    assert (ownerPid != null);
    assert (ownerPid == (int) Posix.getpid ());

    assert (lock2.tryAcquire () == false);

    assert (lock1.release () == true);
    assert (lock1.isHeld () == false);

    assert (lock2.tryAcquire () == true);
    assert (lock2.release () == true);
}

void testAcquireTimeout () {
    Vala.Io.Path lockPath = new Vala.Io.Path ("/tmp/valacore/ut/filelock_timeout.lock");
    Files.remove (lockPath);

    var lock1 = new FileLock (lockPath);
    var lock2 = new FileLock (lockPath);

    assert (lock1.tryAcquire () == true);
    assert (lock2.acquireTimeout (Duration.ofSeconds (0)) == false);

    assert (lock1.release () == true);
}

void testAcquireAfterRelease () {
    Vala.Io.Path lockPath = new Vala.Io.Path ("/tmp/valacore/ut/filelock_wait.lock");
    Files.remove (lockPath);

    var lock1 = new FileLock (lockPath);
    var lock2 = new FileLock (lockPath);

    assert (lock1.tryAcquire () == true);

    GLib.Mutex releaseMutex = GLib.Mutex ();
    GLib.Cond releaseCond = GLib.Cond ();
    bool releaseRequested = false;

    Thread<void *> releaser = new Thread<void *> ("releaser", () => {
        releaseMutex.lock ();
        while (!releaseRequested) {
            releaseCond.wait (releaseMutex);
        }
        releaseMutex.unlock ();
        lock1.release ();
        return null;
    });

    releaseMutex.lock ();
    releaseRequested = true;
    releaseCond.signal ();
    releaseMutex.unlock ();

    int64 startMicros = GLib.get_monotonic_time ();
    assert (lock2.acquireTimeout (Duration.ofSeconds (1)) == true);
    int64 elapsedMillis = (GLib.get_monotonic_time () - startMicros) / 1000;

    assert (elapsedMillis < 1000);
    assert (lock2.release () == true);

    releaser.join ();
}

void testWithLock () {
    Vala.Io.Path lockPath = new Vala.Io.Path ("/tmp/valacore/ut/filelock_with.lock");
    Files.remove (lockPath);

    var lock = new FileLock (lockPath);
    bool called = false;

    bool ok = lock.withLock (() => {
        called = true;
        assert (Files.exists (lockPath) == true);
        return true;
    });

    assert (ok == true);
    assert (called == true);
    assert (lock.isHeld () == false);
    assert (Files.exists (lockPath) == false);
}

void testOwnerPidUnavailable () {
    Vala.Io.Path lockPath = new Vala.Io.Path ("/tmp/valacore/ut/filelock_missing.lock");
    Files.remove (lockPath);

    var lock = new FileLock (lockPath);
    assert (lock.ownerPid () == null);
}

void testReleaseWithoutAcquire () {
    Vala.Io.Path lockPath = new Vala.Io.Path ("/tmp/valacore/ut/filelock_release.lock");
    Files.remove (lockPath);

    var lock = new FileLock (lockPath);
    assert (lock.release () == false);
}
