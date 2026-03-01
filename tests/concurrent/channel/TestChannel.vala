using Vala.Concurrent;
using Vala.Collections;
using Vala.Time;

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
    Test.add_func ("/concurrent/channel/testReceiveAfterCloseEmpty", testReceiveAfterCloseEmpty);
    Test.add_func ("/concurrent/channel/testUnbufferedMultiSender", testUnbufferedMultiSender);
    Test.add_func ("/concurrent/channel/testGenericBufferedSendReceive", testGenericBufferedSendReceive);
    Test.add_func ("/concurrent/channel/testGenericTrySendTryReceive", testGenericTrySendTryReceive);
    Test.add_func ("/concurrent/channel/testGenericBufferedInvalidCapacity", testGenericBufferedInvalidCapacity);
    Test.add_func ("/concurrent/channel/testGenericReceiveTimeout", testGenericReceiveTimeout);
    Test.add_func ("/concurrent/channel/testGenericSelect", testGenericSelect);
    Test.add_func ("/concurrent/channel/testGenericSelectDelayedSend", testGenericSelectDelayedSend);
    Test.add_func ("/concurrent/channel/testGenericPipeline", testGenericPipeline);
    Test.add_func ("/concurrent/channel/testGenericFanInOut", testGenericFanInOut);
    Test.add_func ("/concurrent/channel/testGenericFanOutInvalidN", testGenericFanOutInvalidN);
    Test.run ();
}

Channel<T> mustBuffered<T> (int capacity) {
    Channel<T> ? channel = null;
    try {
        channel = Channel.buffered<T> (capacity);
    } catch (ChannelError e) {
        assert_not_reached ();
    }
    if (channel == null) {
        assert_not_reached ();
    }
    return channel;
}

ArrayList<Channel<T> > mustFanOut<T> (Channel<T> src, int n) {
    ArrayList<Channel<T> > ? channels = null;
    try {
        channels = Channel.fanOut<T> (src, n);
    } catch (ChannelError e) {
        assert_not_reached ();
    }
    if (channels == null) {
        assert_not_reached ();
    }
    return channels;
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

    new Thread<void *> ("producer", () => {
        for (int i = 1; i <= 10; i++) {
            ch.send (i);
        }
        ch.close ();
        return null;
    });

    wg.add (1);
    new Thread<void *> ("consumer", () => {
        while (true) {
            IntBox ? box = ch.tryReceive ();
            if (box != null) {
                mutex.withLock (() => {
                    sum += box.value;
                });
            } else if (ch.isClosed () && ch.size () == 0) {
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

void testReceiveAfterCloseEmpty () {
    var ch = ChannelInt.buffered (5);
    ch.close ();
    int val = ch.receive ();
    assert (val == 0);

    var sch = ChannelString.buffered (5);
    sch.close ();
    string sval = sch.receive ();
    assert (sval == "");
}

void testUnbufferedMultiSender () {
    var ch = new ChannelInt ();
    int total = 0;
    var mutex = new Vala.Concurrent.Mutex ();
    var wg = new WaitGroup ();

    wg.add (3);
    for (int t = 1; t <= 3; t++) {
        int tid = t;
        new Thread<void *> ("sender-%d".printf (tid), () => {
            ch.send (tid * 10);
            wg.done ();
            return null;
        });
    }

    for (int i = 0; i < 3; i++) {
        int val = ch.receive ();
        mutex.withLock (() => {
            total += val;
        });
    }

    wg.wait ();
    assert (total == 60);
}

void testGenericBufferedSendReceive () {
    var ch = mustBuffered<int> (3);
    ch.send (10);
    ch.send (20);
    int ? v1 = ch.receive ();
    int ? v2 = ch.receive ();
    assert (v1 != null && v1 == 10);
    assert (v2 != null && v2 == 20);
}

void testGenericTrySendTryReceive () {
    var ch = mustBuffered<string> (1);
    assert (ch.trySend ("a"));
    assert (!ch.trySend ("b"));
    string ? v = ch.tryReceive ();
    assert (v != null && v == "a");
    assert (ch.tryReceive () == null);
}

void testGenericBufferedInvalidCapacity () {
    bool thrown = false;
    try {
        Channel.buffered<int> (0);
    } catch (ChannelError e) {
        thrown = true;
        assert (e is ChannelError.INVALID_ARGUMENT);
    }
    assert (thrown);
}

void testGenericReceiveTimeout () {
    var ch = new Channel<string> ();
    string ? v = ch.receiveTimeout (Duration.ofSeconds (0));
    assert (v == null);
}

void testGenericSelect () {
    var ch1 = mustBuffered<int> (1);
    var ch2 = mustBuffered<int> (1);
    ch2.send (42);

    var channels = new ArrayList<Channel<int> > ();
    channels.add (ch1);
    channels.add (ch2);

    Pair<int, int> ? selected = Channel.select<int> (channels);
    assert (selected != null);
    if (selected != null) {
        assert ((int) selected.first () == 1);
        assert ((int) selected.second () == 42);
    }
}

void testGenericSelectDelayedSend () {
    var ch1 = mustBuffered<int> (1);
    var ch2 = mustBuffered<int> (1);
    var channels = new ArrayList<Channel<int> > ();
    channels.add (ch1);
    channels.add (ch2);

    var sender = new Thread<void> ("delayed-sender", () => {
        Thread.usleep (50 * 1000);
        ch1.send (7);
    });

    Pair<int, int> ? selected = Channel.select<int> (channels);
    sender.join ();
    assert (selected != null);
    if (selected != null) {
        assert ((int) selected.first () == 0);
        assert ((int) selected.second () == 7);
    }
}

void testGenericPipeline () {
    var inCh = mustBuffered<int> (4);
    var outCh = Channel.pipeline<int, int> (inCh, (n) => {
        return n * 2;
    });

    inCh.send (1);
    inCh.send (2);
    inCh.close ();

    int ? v1 = outCh.receiveTimeout (Duration.ofSeconds (1));
    int ? v2 = outCh.receiveTimeout (Duration.ofSeconds (1));
    assert (v1 != null && v2 != null);
    if (v1 != null && v2 != null) {
        assert (v1 + v2 == 6);
    }
}

void testGenericFanInOut () {
    var src = mustBuffered<int> (8);
    for (int i = 1; i <= 4; i++) {
        src.send (i);
    }
    src.close ();

    var outs = mustFanOut<int> (src, 2);
    var merged = Channel.fanIn<int> (outs);

    int sum = 0;
    for (int i = 0; i < 4; i++) {
        int ? v = merged.receiveTimeout (Duration.ofSeconds (1));
        assert (v != null);
        if (v != null) {
            sum += v;
        }
    }
    assert (sum == 10);
}

void testGenericFanOutInvalidN () {
    var src = new Channel<int> ();
    bool thrown = false;
    try {
        Channel.fanOut<int> (src, 0);
    } catch (ChannelError e) {
        thrown = true;
        assert (e is ChannelError.INVALID_ARGUMENT);
    }
    assert (thrown);
}
