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
    bool reader_entered = false;

    rw.writeLock ();
    Thread<void *> reader = new Thread<void *>("reader", () => {
        rw.readLock ();
        reader_entered = true;
        rw.readUnlock ();
        return null;
    });

    Posix.usleep (30000);
    assert (reader_entered == false);

    rw.writeUnlock ();
    reader.join ();
    assert (reader_entered == true);
}
