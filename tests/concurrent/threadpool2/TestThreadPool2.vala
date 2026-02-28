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

    Test.run ();
}

void testSubmit () {
    var pool = new Vala.Concurrent.ThreadPool (2);
    Future<int> future = pool.submit<int> (() => {
        return 42;
    });

    assert (future.@await () == 42);
    assert (future.isSuccess () == true);

    pool.shutdown ();
    assert (pool.isShutdown () == true);
}

void testExecute () {
    var pool = new Vala.Concurrent.ThreadPool (2);
    var wg = new WaitGroup ();
    int counter = 0;

    wg.add (2);

    pool.execute (() => {
        counter++;
        wg.done ();
    });

    pool.execute (() => {
        counter++;
        wg.done ();
    });

    wg.wait ();
    assert (counter == 2);

    pool.shutdown ();
}

void testInvokeAll () {
    var pool = new Vala.Concurrent.ThreadPool (3);

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
    var pool = new Vala.Concurrent.ThreadPool (1);
    pool.shutdown ();

    Future<int> rejected = pool.submit<int> (() => {
        return 1;
    });

    rejected.@await ();
    assert (rejected.isFailed () == true);
    assert (rejected.error () == "thread pool is shut down");
}

void testShutdownNow () {
    var pool = new Vala.Concurrent.ThreadPool (2);

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
