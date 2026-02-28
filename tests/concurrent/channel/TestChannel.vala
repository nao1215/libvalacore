using Vala.Concurrent;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/concurrent/channel/testBufferedIntSendReceive", testBufferedIntSendReceive);
    Test.add_func ("/concurrent/channel/testUnbufferedIntSendReceive", testUnbufferedIntSendReceive);
    Test.add_func ("/concurrent/channel/testBufferedMultipleValues", testBufferedMultipleValues);
    Test.add_func ("/concurrent/channel/testTrySendInt", testTrySendInt);
    Test.add_func ("/concurrent/channel/testTryReceiveInt", testTryReceiveInt);
    Test.add_func ("/concurrent/channel/testCloseInt", testCloseInt);
    Test.add_func ("/concurrent/channel/testIntCapacityAndSize", testIntCapacityAndSize);
    Test.add_func ("/concurrent/channel/testBufferedStringSendReceive", testBufferedStringSendReceive);
    Test.add_func ("/concurrent/channel/testUnbufferedStringSendReceive", testUnbufferedStringSendReceive);
    Test.add_func ("/concurrent/channel/testTrySendString", testTrySendString);
    Test.add_func ("/concurrent/channel/testTryReceiveString", testTryReceiveString);
    Test.add_func ("/concurrent/channel/testCloseString", testCloseString);
    Test.add_func ("/concurrent/channel/testProducerConsumer", testProducerConsumer);
    Test.run ();
}

void testBufferedIntSendReceive () {
    var ch = ChannelInt.buffered (5);
    ch.send (42);
    int val = ch.receive ();
    assert (val == 42);
}

void testUnbufferedIntSendReceive () {
    var ch = new ChannelInt ();
    new Thread<void *> ("sender", () => {
        ch.send (99);
        return null;
    });
    int val = ch.receive ();
    assert (val == 99);
}

void testBufferedMultipleValues () {
    var ch = ChannelInt.buffered (3);
    ch.send (1);
    ch.send (2);
    ch.send (3);

    assert (ch.receive () == 1);
    assert (ch.receive () == 2);
    assert (ch.receive () == 3);
}

void testTrySendInt () {
    var ch = ChannelInt.buffered (1);
    assert (ch.trySend (10) == true);
    assert (ch.trySend (20) == false);
    ch.receive ();
    assert (ch.trySend (30) == true);
}

void testTryReceiveInt () {
    var ch = ChannelInt.buffered (5);
    assert (ch.tryReceive () == null);
    ch.send (7);
    IntBox ? box = ch.tryReceive ();
    assert (box != null);
    assert (box.value == 7);
    assert (ch.tryReceive () == null);
}

void testCloseInt () {
    var ch = ChannelInt.buffered (5);
    assert (ch.isClosed () == false);
    ch.close ();
    assert (ch.isClosed () == true);
}

void testIntCapacityAndSize () {
    var ch = ChannelInt.buffered (10);
    assert (ch.capacity () == 10);
    assert (ch.size () == 0);
    ch.send (1);
    ch.send (2);
    assert (ch.size () == 2);
    ch.receive ();
    assert (ch.size () == 1);

    var unbuffered = new ChannelInt ();
    assert (unbuffered.capacity () == 0);
}

void testBufferedStringSendReceive () {
    var ch = ChannelString.buffered (5);
    ch.send ("hello");
    string val = ch.receive ();
    assert (val == "hello");
}

void testUnbufferedStringSendReceive () {
    var ch = new ChannelString ();
    new Thread<void *> ("sender", () => {
        ch.send ("world");
        return null;
    });
    string val = ch.receive ();
    assert (val == "world");
}

void testTrySendString () {
    var ch = ChannelString.buffered (1);
    assert (ch.trySend ("a") == true);
    assert (ch.trySend ("b") == false);
    ch.receive ();
    assert (ch.trySend ("c") == true);
}

void testTryReceiveString () {
    var ch = ChannelString.buffered (5);
    assert (ch.tryReceive () == null);
    ch.send ("test");
    StringBox ? box = ch.tryReceive ();
    assert (box != null);
    assert (box.value == "test");
    assert (ch.tryReceive () == null);
}

void testCloseString () {
    var ch = ChannelString.buffered (5);
    assert (ch.isClosed () == false);
    ch.close ();
    assert (ch.isClosed () == true);
}

void testProducerConsumer () {
    var ch = ChannelInt.buffered (10);
    int sum = 0;
    var mutex = new Vala.Concurrent.Mutex ();
    var wg = new WaitGroup ();

    wg.add (1);
    new Thread<void *> ("producer", () => {
        for (int i = 1; i <= 10; i++) {
            ch.send (i);
        }
        ch.close ();
        return null;
    });

    new Thread<void *> ("consumer", () => {
        while (true) {
            IntBox ? box = ch.tryReceive ();
            if (box != null) {
                mutex.withLock (() => {
                    sum += box.value;
                });
            } else if (ch.isClosed ()) {
                break;
            } else {
                Thread.usleep (100);
            }
        }
        wg.done ();
        return null;
    });

    wg.wait ();
    assert (sum == 55);
}
