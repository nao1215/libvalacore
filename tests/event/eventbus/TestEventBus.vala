using Vala.Event;
using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/event/eventbus/testSubscribePublish", testSubscribePublish);
    Test.add_func ("/event/eventbus/testSubscribeOnce", testSubscribeOnce);
    Test.add_func ("/event/eventbus/testUnsubscribeAndClear", testUnsubscribeAndClear);
    Test.add_func ("/event/eventbus/testAsyncDispatch", testAsyncDispatch);
    Test.add_func ("/event/eventbus/testInvalidTopic", testInvalidTopic);
    Test.add_func ("/event/eventbus/testInvalidTopicAcrossApis", testInvalidTopicAcrossApis);

    Test.run ();
}

void testSubscribePublish () {
    var bus = new EventBus ();
    int sum = 0;

    var subscribed = bus.subscribe ("numbers", (value) => {
        sum += value.get_int32 ();
    });
    assert (subscribed.isOk ());

    var published1 = bus.publish ("numbers", new GLib.Variant.int32 (2));
    assert (published1.isOk ());
    assert (published1.unwrap () == true);

    var published2 = bus.publish ("numbers", new GLib.Variant.int32 (3));
    assert (published2.isOk ());
    assert (published2.unwrap () == true);

    assert (sum == 5);
}

void testSubscribeOnce () {
    var bus = new EventBus ();
    int count = 0;

    var subscribed = bus.subscribeOnce ("once", (eventData) => {
        count++;
    });
    assert (subscribed.isOk ());

    var published1 = bus.publish ("once", new GLib.Variant.string ("a"));
    assert (published1.isOk ());
    assert (published1.unwrap () == true);

    var published2 = bus.publish ("once", new GLib.Variant.string ("b"));
    assert (published2.isOk ());
    assert (published2.unwrap () == false);

    assert (count == 1);
}

void testUnsubscribeAndClear () {
    var bus = new EventBus ();
    int count = 0;

    var subscribedFlag = bus.subscribe ("flag", (value) => {
        count++;
    });
    assert (subscribedFlag.isOk ());

    var hasFlag = bus.hasSubscribers ("flag");
    assert (hasFlag.isOk ());
    assert (hasFlag.unwrap () == true);

    var unsubscribedFlag = bus.unsubscribe ("flag");
    assert (unsubscribedFlag.isOk ());
    assert (unsubscribedFlag.unwrap () == true);

    hasFlag = bus.hasSubscribers ("flag");
    assert (hasFlag.isOk ());
    assert (hasFlag.unwrap () == false);

    var publishNoSubscribers = bus.publish ("flag", new GLib.Variant.boolean (true));
    assert (publishNoSubscribers.isOk ());
    assert (publishNoSubscribers.unwrap () == false);
    assert (count == 0);

    var subscribedX = bus.subscribe ("x", (value) => {});
    assert (subscribedX.isOk ());
    var subscribedY = bus.subscribe ("y", (value) => {});
    assert (subscribedY.isOk ());

    bus.clear ();

    var hasX = bus.hasSubscribers ("x");
    assert (hasX.isOk ());
    assert (hasX.unwrap () == false);

    var hasY = bus.hasSubscribers ("y");
    assert (hasY.isOk ());
    assert (hasY.unwrap () == false);
}

void testAsyncDispatch () {
    var bus = new EventBus ().withAsync ();
    int count = 0;
    GLib.Mutex mutex = GLib.Mutex ();
    GLib.Cond cond = GLib.Cond ();

    var subscribed = bus.subscribe ("async", (value) => {
        mutex.lock ();
        count += value.get_int32 ();
        cond.signal ();
        mutex.unlock ();
    });
    assert (subscribed.isOk ());

    for (int i = 0; i < 10; i++) {
        var published = bus.publish ("async", new GLib.Variant.int32 (1));
        assert (published.isOk ());
        assert (published.unwrap () == true);
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
    var published = bus.publish ("", new GLib.Variant.string ("x"));
    assert (published.isError ());
    assert (published.unwrapError () is EventBusError.INVALID_ARGUMENT);
    assert (published.unwrapError ().message == "topic must not be empty");
}

void testInvalidTopicAcrossApis () {
    var bus = new EventBus ();

    Result<EventBus, GLib.Error> sub = bus.subscribe ("", (eventData) => {});
    assertInvalidTopicBusResult (sub);

    Result<EventBus, GLib.Error> subOnce = bus.subscribeOnce ("", (eventData) => {});
    assertInvalidTopicBusResult (subOnce);

    Result<bool, GLib.Error> has = bus.hasSubscribers ("");
    assertInvalidTopicBoolResult (has);

    Result<bool, GLib.Error> unsubscribed = bus.unsubscribe ("");
    assertInvalidTopicBoolResult (unsubscribed);
}

void assertInvalidTopicBusResult (Result<EventBus, GLib.Error> result) {
    assert (result.isError ());
    assert (result.unwrapError () is EventBusError.INVALID_ARGUMENT);
    assert (result.unwrapError ().message == "topic must not be empty");
}

void assertInvalidTopicBoolResult (Result<bool, GLib.Error> result) {
    assert (result.isError ());
    assert (result.unwrapError () is EventBusError.INVALID_ARGUMENT);
    assert (result.unwrapError ().message == "topic must not be empty");
}
