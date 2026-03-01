using Vala.Collections;
using Vala.Concurrent;
using Vala.Time;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/concurrent/threadpool2/testSubmit", testSubmit);
    Test.add_func ("/concurrent/threadpool2/testExecute", testExecute);
    Test.add_func ("/concurrent/threadpool2/testInvokeAll", testInvokeAll);
    Test.add_func ("/concurrent/threadpool2/testShutdownRejectsSubmit", testShutdownRejectsSubmit);
    Test.add_func ("/concurrent/threadpool2/testShutdownNow", testShutdownNow);
    Test.add_func ("/concurrent/threadpool2/testGlobal", testGlobal);
    Test.add_func ("/concurrent/threadpool2/testGo", testGo);
    Test.add_func ("/concurrent/threadpool2/testInvalidPoolSize", testInvalidPoolSize);

    Test.run ();
}

Vala.Concurrent.ThreadPool mustThreadPool (int poolSize) {
    Vala.Concurrent.ThreadPool ? pool = null;
    try {
        pool = new Vala.Concurrent.ThreadPool (poolSize);
    } catch (ThreadPoolError e) {
        assert_not_reached ();
    }
    if (pool == null) {
        assert_not_reached ();
    }
    return pool;
}

void testSubmit () {
    var pool = mustThreadPool (2);
    Future<int> future = pool.submit<int> (() => {
        return 42;
    });

    assert (future.@await () == 42);
    assert (future.isSuccess () == true);

    pool.shutdown ();
    assert (pool.isShutdown () == true);
}

void testExecute () {
    var pool = mustThreadPool (2);
    var wg = new WaitGroup ();
    int counter = 0;
    GLib.Mutex mutex = GLib.Mutex ();

    wg.add (2);

    pool.execute (() => {
        mutex.lock ();
        counter++;
        mutex.unlock ();
        wg.done ();
    });

    pool.execute (() => {
        mutex.lock ();
        counter++;
        mutex.unlock ();
        wg.done ();
    });

    wg.wait ();
    mutex.lock ();
    int total = counter;
    mutex.unlock ();
    assert (total == 2);

    pool.shutdown ();
}

void testInvokeAll () {
    var pool = mustThreadPool (3);

    var tasks = new ArrayList<ThreadPoolTaskFunc<int> > ();
    tasks.add (new ThreadPoolTaskFunc<int> (() => {
        return 1;
    }));
    tasks.add (new ThreadPoolTaskFunc<int> (() => {
        return 2;
    }));
    tasks.add (new ThreadPoolTaskFunc<int> (() => {
        return 3;
    }));

    ArrayList<Future<int> > futures = pool.invokeAll<int> (tasks);
    assert (futures.size () == 3);

    int sum = 0;
    for (int i = 0; i < futures.size (); i++) {
        Future<int> ? f = futures.get (i);
        assert (f != null);
        sum += f.@await ();
    }
    assert (sum == 6);

    pool.shutdown ();
}

void testShutdownRejectsSubmit () {
    var pool = mustThreadPool (1);
    pool.shutdown ();

    Future<int> rejected = pool.submit<int> (() => {
        return 1;
    });

    rejected.@await ();
    assert (rejected.isFailed () == true);
    assert (rejected.error () == "thread pool is shut down");
}

void testShutdownNow () {
    var pool = mustThreadPool (2);

    for (int i = 0; i < 10; i++) {
        pool.execute (() => {
            Thread.usleep (200 * 1000);
        });
    }

    pool.shutdownNow ();
    assert (pool.isShutdown () == true);
    assert (pool.awaitTermination (Duration.ofSeconds (1)) == true);
}

void testGlobal () {
    Vala.Concurrent.ThreadPool p1 = Vala.Concurrent.ThreadPool.global ();
    Vala.Concurrent.ThreadPool p2 = Vala.Concurrent.ThreadPool.global ();

    assert (p1 == p2);
}

void testGo () {
    var wg = new WaitGroup ();
    int called = 0;

    wg.add (1);
    Vala.Concurrent.ThreadPool.go (() => {
        called++;
        wg.done ();
    });

    wg.wait ();
    assert (called == 1);
}

void testInvalidPoolSize () {
    bool thrown = false;
    try {
        new Vala.Concurrent.ThreadPool (0);
    } catch (ThreadPoolError e) {
        thrown = true;
        assert (e is ThreadPoolError.INVALID_ARGUMENT);
    }
    assert (thrown);
}
