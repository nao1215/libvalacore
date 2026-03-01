using Vala.Collections;
using Vala.Concurrent;
using Vala.Time;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/concurrent/future/testRunAwait", testRunAwait);
    Test.add_func ("/concurrent/future/testCompleted", testCompleted);
    Test.add_func ("/concurrent/future/testFailed", testFailed);
    Test.add_func ("/concurrent/future/testAwaitTimeout", testAwaitTimeout);
    Test.add_func ("/concurrent/future/testAwaitTimeoutSuccess", testAwaitTimeoutSuccess);
    Test.add_func ("/concurrent/future/testAwaitTimeoutInvalid", testAwaitTimeoutInvalid);
    Test.add_func ("/concurrent/future/testMap", testMap);
    Test.add_func ("/concurrent/future/testFlatMap", testFlatMap);
    Test.add_func ("/concurrent/future/testRecover", testRecover);
    Test.add_func ("/concurrent/future/testOnComplete", testOnComplete);
    Test.add_func ("/concurrent/future/testTimeout", testTimeout);
    Test.add_func ("/concurrent/future/testTimeoutInvalid", testTimeoutInvalid);
    Test.add_func ("/concurrent/future/testCancel", testCancel);
    Test.add_func ("/concurrent/future/testOrElse", testOrElse);
    Test.add_func ("/concurrent/future/testAll", testAll);
    Test.add_func ("/concurrent/future/testAllFailure", testAllFailure);
    Test.add_func ("/concurrent/future/testAny", testAny);
    Test.add_func ("/concurrent/future/testRace", testRace);
    Test.add_func ("/concurrent/future/testDelayed", testDelayed);
    Test.add_func ("/concurrent/future/testDelayedInvalid", testDelayedInvalid);
    Test.add_func ("/concurrent/future/testAllSettled", testAllSettled);

    Test.run ();
}

void testRunAwait () {
    Future<int> future = Future.run<int> (() => {
        return 42;
    });

    int ? value = future.@await ();
    assert (value != null);
    assert (value == 42);
    assert (future.isDone () == true);
    assert (future.isSuccess () == true);
    assert (future.isFailed () == false);
}

void testCompleted () {
    Future<string> future = Future<string>.completed<string> ("ok");

    assert (future.isDone () == true);
    assert (future.isSuccess () == true);
    assert (future.@await () == "ok");
}

void testFailed () {
    Future<int> future = Future<int>.failed<int> ("boom");

    assert (future.isDone () == true);
    assert (future.isSuccess () == false);
    assert (future.isFailed () == true);
    assert (future.error () == "boom");
    future.@await ();
    assert (future.isSuccess () == false);
}

void testAwaitTimeout () {
    Future<int> future = Future.run<int> (() => {
        Thread.usleep (200 * 1000);
        return 1;
    });

    future.awaitTimeout (Duration.ofSeconds (0));
    assert (future.isDone () == false);
}

void testAwaitTimeoutSuccess () {
    Future<int> future = Future.run<int> (() => {
        return 5;
    });

    int ? value = future.awaitTimeout (Duration.ofSeconds (1));
    assert (value == 5);
}

void testAwaitTimeoutInvalid () {
    Future<string> future = Future<string>.completed<string> ("ok");

    string ? value = future.awaitTimeout (Duration.ofSeconds (-1));
    assert (value == null);
    assert (future.isDone () == true);
    assert (future.isSuccess () == true);
    assert (future.@await () == "ok");
}

void testMap () {
    Future<int> future = Future<int>.completed<int> (21);

    Future<int> mapped = future.map<int> ((value) => {
        return value * 2;
    });

    assert (mapped.@await () == 42);
    assert (mapped.isSuccess () == true);
}

void testFlatMap () {
    Future<int> source = Future<int>.completed<int> (10);

    Future<string> chained = source.flatMap<string> ((value) => {
        return Future<string>.completed<string> ("v=%d".printf (value));
    });

    assert (chained.@await () == "v=10");
    assert (chained.isSuccess () == true);
}

void testRecover () {
    Future<int> source = Future<int>.failed<int> ("bad");

    Future<int> recovered = source.recover ((message) => {
        return message.length;
    });

    assert (recovered.@await () == 3);
    assert (recovered.isSuccess () == true);
}

void testOnComplete () {
    var wg = new WaitGroup ();
    wg.add (1);

    int called = 0;
    int captured = 0;

    Future<int> future = Future<int>.completed<int> (9);

    future.onComplete ((value) => {
        called++;
        captured = value;
        wg.done ();
    });

    wg.wait ();

    assert (called == 1);
    assert (captured == 9);
}

void testTimeout () {
    Future<int> source = Future.run<int> (() => {
        Thread.usleep (150 * 1000);
        return 7;
    });

    Future<int> wrapped = source.timeout (Duration.ofSeconds (0));
    wrapped.@await ();

    assert (wrapped.isDone () == true);
    assert (wrapped.isFailed () == true);
    assert (wrapped.error () == "timeout");
}

void testTimeoutInvalid () {
    Future<int> source = Future<int>.completed<int> (1);

    Future<int> wrapped = source.timeout (Duration.ofSeconds (-1));
    wrapped.@await ();
    assert (wrapped.isFailed () == true);
    assert (wrapped.error () == "timeout must be non-negative");
}

void testCancel () {
    Future<int> source = Future.run<int> (() => {
        Thread.usleep (200 * 1000);
        return 77;
    });

    assert (source.cancel () == true);
    source.@await ();

    assert (source.isDone () == true);
    assert (source.isCancelled () == true);
    assert (source.isSuccess () == false);
    assert (source.isFailed () == false);
    assert (source.error () == "cancelled");
}

void testOrElse () {
    Future<int> ok = Future<int>.completed<int> (3);

    Future<int> bad = Future<int>.failed<int> ("x");

    assert (ok.orElse (100) == 3);
    assert (bad.orElse (100) == 100);
}

void testAll () {
    var list = new ArrayList<Future<int> > ();
    list.add (Future<int>.completed<int> (1));
    list.add (Future<int>.completed<int> (2));
    list.add (Future<int>.completed<int> (3));

    Future<ArrayList<int> > combined = Future<int>.all<int> (list);

    ArrayList<int> ? values = combined.@await ();

    assert (values != null);
    assert (combined.isSuccess () == true);
    assert (values.size () == 3);
    assert (values.get (0) == 1);
    assert (values.get (1) == 2);
    assert (values.get (2) == 3);
}

void testAllFailure () {
    var list = new ArrayList<Future<int> > ();
    list.add (Future<int>.completed<int> (1));
    list.add (Future<int>.failed<int> ("boom"));

    Future<ArrayList<int> > combined = Future<int>.all<int> (list);

    assert (combined.@await () == null);
    assert (combined.isFailed () == true);
    assert (combined.error () == "boom");
}

void testAny () {
    var list = new ArrayList<Future<int> > ();
    list.add (Future.run<int> (() => {
        Thread.usleep (150 * 1000);
        return 1;
    }));
    list.add (Future.run<int> (() => {
        Thread.usleep (30 * 1000);
        return 2;
    }));

    Future<int> first = Future<int>.any<int> (list);

    int ? value = first.@await ();

    assert (value != null);
    assert (value == 2);
}

void testRace () {
    var list = new ArrayList<Future<string> > ();
    list.add (Future.run<string> (() => {
        Thread.usleep (80 * 1000);
        return "slow";
    }));
    list.add (Future.run<string> (() => {
        Thread.usleep (20 * 1000);
        return "fast";
    }));

    Future<string> first = Future<string>.race<string> (list);

    assert (first.@await () == "fast");
}

void testDelayed () {
    Future<int> delayed = Future<int>.delayed<int> (Duration.ofSeconds (0), () => {
        return 11;
    });

    assert (delayed.@await () == 11);
}

void testDelayedInvalid () {
    Future<int> delayed = Future<int>.delayed<int> (Duration.ofSeconds (-1), () => {
        return 11;
    });

    delayed.@await ();
    assert (delayed.isFailed () == true);
    assert (delayed.error () == "delay must be non-negative");
}

void testAllSettled () {
    Future<int> cancelled = Future.run<int> (() => {
        Thread.usleep (100 * 1000);
        return 10;
    });
    cancelled.cancel ();

    var list = new ArrayList<Future<int> > ();
    list.add (Future<int>.completed<int> (1));
    list.add (Future<int>.failed<int> ("e"));
    list.add (cancelled);

    Future<ArrayList<Future<int> > > settledFuture = Future<int>.allSettled<int> (list);

    ArrayList<Future<int> > ? settled = settledFuture.@await ();

    assert (settled != null);
    assert (settled.size () == 3);
    assert (settled.get (0).isSuccess () == true);
    assert (settled.get (1).isFailed () == true);
    assert (settled.get (2).isCancelled () == true);
}
