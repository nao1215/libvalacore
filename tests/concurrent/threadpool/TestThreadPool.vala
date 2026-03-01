using Vala.Concurrent;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/concurrent/threadpool/testCreateWithSize", testCreateWithSize);
    Test.add_func ("/concurrent/threadpool/testWithDefault", testWithDefault);
    Test.add_func ("/concurrent/threadpool/testSubmitInt", testSubmitInt);
    Test.add_func ("/concurrent/threadpool/testSubmitString", testSubmitString);
    Test.add_func ("/concurrent/threadpool/testSubmitBool", testSubmitBool);
    Test.add_func ("/concurrent/threadpool/testSubmitDouble", testSubmitDouble);
    Test.add_func ("/concurrent/threadpool/testExecute", testExecute);
    Test.add_func ("/concurrent/threadpool/testMultipleTasks", testMultipleTasks);
    Test.add_func ("/concurrent/threadpool/testShutdown", testShutdown);
    Test.add_func ("/concurrent/threadpool/testPoolSize", testPoolSize);
    Test.add_func ("/concurrent/threadpool/testIsDone", testIsDone);
    Test.add_func ("/concurrent/threadpool/testConcurrentSubmit", testConcurrentSubmit);
    Test.add_func ("/concurrent/threadpool/testInvalidPoolSize", testInvalidPoolSize);
    Test.run ();
}

WorkerPool mustWorkerPool (int poolSize) {
    WorkerPool ? pool = null;
    try {
        pool = new WorkerPool (poolSize);
    } catch (WorkerPoolError e) {
        assert_not_reached ();
    }
    if (pool == null) {
        assert_not_reached ();
    }
    return pool;
}

void testCreateWithSize () {
    var pool = mustWorkerPool (4);
    assert (pool.poolSize () == 4);
    assert (pool.isShutdown () == false);
    pool.shutdown ();
}

void testWithDefault () {
    var pool = WorkerPool.withDefault ();
    assert (pool.poolSize () >= 1);
    assert (pool.isShutdown () == false);
    pool.shutdown ();
}

void testSubmitInt () {
    var pool = mustWorkerPool (2);
    var promise = pool.submitInt (() => { return 42; });
    int result = promise.await ();
    assert (result == 42);
    pool.shutdown ();
}

void testSubmitString () {
    var pool = mustWorkerPool (2);
    var promise = pool.submitString (() => { return "hello"; });
    string result = promise.await ();
    assert (result == "hello");
    pool.shutdown ();
}

void testSubmitBool () {
    var pool = mustWorkerPool (2);
    var promise = pool.submitBool (() => { return true; });
    bool result = promise.await ();
    assert (result == true);

    var promise2 = pool.submitBool (() => { return false; });
    bool result2 = promise2.await ();
    assert (result2 == false);
    pool.shutdown ();
}

void testSubmitDouble () {
    var pool = mustWorkerPool (2);
    var promise = pool.submitDouble (() => { return 3.14; });
    double result = promise.await ();
    assert (result > 3.13 && result < 3.15);
    pool.shutdown ();
}

void testExecute () {
    var pool = mustWorkerPool (2);
    var wg = new WaitGroup ();
    int counter = 0;
    var mutex = new Vala.Concurrent.Mutex ();

    wg.add (1);
    pool.execute (() => {
        mutex.withLock (() => {
            counter++;
        });
        wg.done ();
    });

    wg.wait ();
    assert (counter == 1);
    pool.shutdown ();
}

void testMultipleTasks () {
    var pool = mustWorkerPool (4);

    var p1 = pool.submitInt (() => { return 1; });
    var p2 = pool.submitInt (() => { return 2; });
    var p3 = pool.submitInt (() => { return 3; });
    var p4 = pool.submitInt (() => { return 4; });

    int sum = p1.await () + p2.await () + p3.await () + p4.await ();
    assert (sum == 10);
    pool.shutdown ();
}

void testShutdown () {
    var pool = mustWorkerPool (2);
    assert (pool.isShutdown () == false);
    pool.shutdown ();
    assert (pool.isShutdown () == true);
}

void testPoolSize () {
    var pool = mustWorkerPool (8);
    assert (pool.poolSize () == 8);
    pool.shutdown ();
}

void testIsDone () {
    var pool = mustWorkerPool (2);
    var promise = pool.submitInt (() => { return 99; });
    promise.await ();
    assert (promise.isDone () == true);
    pool.shutdown ();
}

void testConcurrentSubmit () {
    var pool = mustWorkerPool (4);
    int total = 0;
    var mutex = new Vala.Concurrent.Mutex ();
    var wg = new WaitGroup ();

    for (int i = 0; i < 100; i++) {
        wg.add (1);
        pool.execute (() => {
            mutex.withLock (() => {
                total++;
            });
            wg.done ();
        });
    }

    wg.wait ();
    assert (total == 100);
    pool.shutdown ();
}

void testInvalidPoolSize () {
    bool thrown = false;
    try {
        new WorkerPool (0);
    } catch (WorkerPoolError e) {
        thrown = true;
        assert (e is WorkerPoolError.INVALID_ARGUMENT);
    }
    assert (thrown);
}
