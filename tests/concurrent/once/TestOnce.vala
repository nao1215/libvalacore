using Vala.Concurrent;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/concurrent/once/testSingleThread", testSingleThread);
    Test.add_func ("/concurrent/once/testMultiThread", testMultiThread);
    Test.run ();
}

void testSingleThread () {
    Vala.Concurrent.Once once = new Vala.Concurrent.Once ();
    int count = 0;

    once.doOnce (() => {
        count++;
    });
    once.doOnce (() => {
        count++;
    });

    assert (count == 1);
}

void testMultiThread () {
    Vala.Concurrent.Once once = new Vala.Concurrent.Once ();
    int count = 0;

    Thread<void*>[] workers = new Thread<void*>[10];
    for (int i = 0; i < workers.length; i++) {
        workers[i] = new Thread<void*> ("worker", () => {
            once.doOnce (() => {
                count++;
            });
            return null;
        });
    }

    for (int i = 0; i < workers.length; i++) {
        workers[i].join ();
    }

    assert (count == 1);
}
