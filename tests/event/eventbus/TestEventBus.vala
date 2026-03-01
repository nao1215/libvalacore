using Vala.Event;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/event/eventbus/testSubscribePublish", testSubscribePublish);
    Test.add_func ("/event/eventbus/testSubscribeOnce", testSubscribeOnce);
    Test.add_func ("/event/eventbus/testUnsubscribeAndClear", testUnsubscribeAndClear);
    Test.add_func ("/event/eventbus/testAsyncDispatch", testAsyncDispatch);
    Test.add_func ("/event/eventbus/testInvalidTopic", testInvalidTopic);

    Test.run ();
}

void testSubscribePublish () {
    var bus = new EventBus ();
    int sum = 0;

    try {
        bus.subscribe ("numbers", (value) => {
            sum += value.get_int32 ();
        });

        bus.publish ("numbers", new GLib.Variant.int32 (2));
        bus.publish ("numbers", new GLib.Variant.int32 (3));
        assert (sum == 5);
    } catch (EventBusError e) {
        assert_not_reached ();
    }
}

void testSubscribeOnce () {
    var bus = new EventBus ();
    int count = 0;

    try {
        bus.subscribeOnce ("once", (eventData) => {
            count++;
        });

        bus.publish ("once", new GLib.Variant.string ("a"));
        bus.publish ("once", new GLib.Variant.string ("b"));
        assert (count == 1);
    } catch (EventBusError e) {
        assert_not_reached ();
    }
}

void testUnsubscribeAndClear () {
    var bus = new EventBus ();
    int count = 0;

    try {
        bus.subscribe ("flag", (value) => {
            count++;
        });
        assert (bus.hasSubscribers ("flag") == true);

        bus.unsubscribe ("flag");
        assert (bus.hasSubscribers ("flag") == false);
        bus.publish ("flag", new GLib.Variant.boolean (true));
        assert (count == 0);

        bus.subscribe ("x", (value) => {});
        bus.subscribe ("y", (value) => {});
        bus.clear ();
        assert (bus.hasSubscribers ("x") == false);
        assert (bus.hasSubscribers ("y") == false);
    } catch (EventBusError e) {
        assert_not_reached ();
    }
}

void testAsyncDispatch () {
    var bus = new EventBus ().withAsync ();
    int count = 0;
    GLib.Mutex mutex = GLib.Mutex ();
    GLib.Cond cond = GLib.Cond ();

    try {
        bus.subscribe ("async", (value) => {
            mutex.lock ();
            count += value.get_int32 ();
            cond.signal ();
            mutex.unlock ();
        });

        for (int i = 0; i < 10; i++) {
            bus.publish ("async", new GLib.Variant.int32 (1));
        }
    } catch (EventBusError e) {
        assert_not_reached ();
    }

    int64 deadline = GLib.get_monotonic_time () + 2 * 1000 * 1000;
    mutex.lock ();
    while (count < 10) {
        if (!cond.wait_until (mutex, deadline)) {
            break;
        }
    }
    int total = count;
    mutex.unlock ();

    assert (total == 10);
}

void testInvalidTopic () {
    var bus = new EventBus ();
    bool thrown = false;
    try {
        bus.publish ("", new GLib.Variant.string ("x"));
    } catch (EventBusError e) {
        thrown = true;
        assert (e is EventBusError.INVALID_ARGUMENT);
    }
    assert (thrown);
}
