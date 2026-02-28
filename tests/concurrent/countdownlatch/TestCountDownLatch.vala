using Vala.Concurrent;
using Vala.Time;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/concurrent/countdownlatch/testAwait", testAwait);
    Test.add_func ("/concurrent/countdownlatch/testAwaitTimeout", testAwaitTimeout);
    Test.add_func ("/concurrent/countdownlatch/testGetCount", testGetCount);
    Test.run ();
}

void testAwait () {
    Vala.Concurrent.CountDownLatch latch = new Vala.Concurrent.CountDownLatch (2);
    bool done1 = false;
    bool done2 = false;

    Thread<void *> t1 = new Thread<void *>("worker1", () => {
        Posix.usleep (20000);
        done1 = true;
        latch.countDown ();
        return null;
    });

    Thread<void *> t2 = new Thread<void *>("worker2", () => {
        Posix.usleep (30000);
        done2 = true;
        latch.countDown ();
        return null;
    });

    latch.@await ();
    t1.join ();
    t2.join ();

    assert (done1 == true);
    assert (done2 == true);
    assert (latch.getCount () == 0);
}

void testAwaitTimeout () {
    Vala.Concurrent.CountDownLatch latch = new Vala.Concurrent.CountDownLatch (1);

    bool result = latch.awaitTimeout (Duration.ofSeconds (0));
    assert (result == false);

    latch.countDown ();
    assert (latch.awaitTimeout (Duration.ofSeconds (1)) == true);
}

void testGetCount () {
    Vala.Concurrent.CountDownLatch latch = new Vala.Concurrent.CountDownLatch (2);

    assert (latch.getCount () == 2);
    latch.countDown ();
    assert (latch.getCount () == 1);
    latch.countDown ();
    assert (latch.getCount () == 0);
}
