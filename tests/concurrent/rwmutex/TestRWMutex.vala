using Vala.Concurrent;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/concurrent/rwmutex/testReadLockUnlock", testReadLockUnlock);
    Test.add_func ("/concurrent/rwmutex/testWriteLockUnlock", testWriteLockUnlock);
    Test.add_func ("/concurrent/rwmutex/testReaderWaitsForWriter", testReaderWaitsForWriter);
    Test.run ();
}

void testReadLockUnlock () {
    Vala.Concurrent.RWMutex rw = new Vala.Concurrent.RWMutex ();
    rw.readLock ();
    rw.readUnlock ();
}

void testWriteLockUnlock () {
    Vala.Concurrent.RWMutex rw = new Vala.Concurrent.RWMutex ();
    rw.writeLock ();
    rw.writeUnlock ();
}

void testReaderWaitsForWriter () {
    Vala.Concurrent.RWMutex rw = new Vala.Concurrent.RWMutex ();
    GLib.Mutex stateMutex = GLib.Mutex ();
    GLib.Cond stateCond = GLib.Cond ();
    bool reader_ready = false;
    bool reader_entered = false;

    rw.writeLock ();
    Thread<void *> reader = new Thread<void *> ("reader", () => {
        stateMutex.lock ();
        reader_ready = true;
        stateCond.signal ();
        stateMutex.unlock ();

        rw.readLock ();
        stateMutex.lock ();
        reader_entered = true;
        stateCond.signal ();
        stateMutex.unlock ();
        rw.readUnlock ();
        return null;
    });

    stateMutex.lock ();
    int64 timeout = GLib.get_monotonic_time () + 1000000;
    while (!reader_ready) {
        assert (stateCond.wait_until (stateMutex, timeout) == true);
    }
    assert (reader_entered == false);
    stateMutex.unlock ();

    rw.writeUnlock ();
    reader.join ();

    stateMutex.lock ();
    assert (reader_entered == true);
    stateMutex.unlock ();
}
