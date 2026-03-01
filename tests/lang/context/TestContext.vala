using Vala.Lang;
using Vala.Time;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/lang/context/testBackground", testBackground);
    Test.add_func ("/lang/context/testCancel", testCancel);
    Test.add_func ("/lang/context/testParentPropagation", testParentPropagation);
    Test.add_func ("/lang/context/testWithTimeout", testWithTimeout);
    Test.add_func ("/lang/context/testWithDeadline", testWithDeadline);
    Test.add_func ("/lang/context/testRemaining", testRemaining);
    Test.add_func ("/lang/context/testWithValue", testWithValue);
    Test.add_func ("/lang/context/testDone", testDone);
    Test.add_func ("/lang/context/testWithTimeoutInvalid", testWithTimeoutInvalid);
    Test.add_func ("/lang/context/testWithValueInvalidKey", testWithValueInvalidKey);
    Test.add_func ("/lang/context/testValueInvalidKey", testValueInvalidKey);

    Test.run ();
}

Context mustWithCancel (Context parent) {
    Context ? ctx = null;
    try {
        ctx = Context.withCancel (parent);
    } catch (ContextError e) {
        assert_not_reached ();
    }
    if (ctx == null) {
        assert_not_reached ();
    }
    return ctx;
}

Context mustWithTimeout (Context parent, Duration timeout) {
    Context ? ctx = null;
    try {
        ctx = Context.withTimeout (parent, timeout);
    } catch (ContextError e) {
        assert_not_reached ();
    }
    if (ctx == null) {
        assert_not_reached ();
    }
    return ctx;
}

Context mustWithDeadline (Context parent, Vala.Time.DateTime deadline) {
    Context ? ctx = null;
    try {
        ctx = Context.withDeadline (parent, deadline);
    } catch (ContextError e) {
        assert_not_reached ();
    }
    if (ctx == null) {
        assert_not_reached ();
    }
    return ctx;
}

string ? mustValue (Context ctx, string key) {
    string ? result = null;
    try {
        result = ctx.value (key);
    } catch (ContextError e) {
        assert_not_reached ();
    }
    return result;
}

Context mustWithValue (Context ctx, string key, string value) {
    Context ? child = null;
    try {
        child = ctx.withValue (key, value);
    } catch (ContextError e) {
        assert_not_reached ();
    }
    if (child == null) {
        assert_not_reached ();
    }
    return child;
}

void testBackground () {
    Context ctx = Context.background ();

    assert (ctx.isCancelled () == false);
    assert (ctx.error () == null);
    assert (ctx.remaining () == null);
}

void testCancel () {
    Context root = Context.background ();
    Context ctx = mustWithCancel (root);

    assert (ctx.isCancelled () == false);
    ctx.cancel ();

    assert (ctx.isCancelled () == true);
    assert (ctx.error () == "cancelled");
}

void testParentPropagation () {
    Context parent = mustWithCancel (Context.background ());
    Context child = mustWithCancel (parent);

    parent.cancel ();
    child.done ().receive ();

    assert (child.isCancelled () == true);
    assert (child.error () == "cancelled");
}

void testWithTimeout () {
    Context parent = Context.background ();
    Context ctx = mustWithTimeout (parent, Duration.ofSeconds (0));

    ctx.done ().receive ();
    assert (ctx.isCancelled () == true);
    assert (ctx.error () == "timeout");
}

void testWithDeadline () {
    Context parent = Context.background ();
    Vala.Time.DateTime now = Vala.Time.DateTime.now ();
    Context ctx = mustWithDeadline (parent, now);

    ctx.done ().receive ();
    assert (ctx.isCancelled () == true);
    assert (ctx.error () == "timeout");
}

void testRemaining () {
    Context ctx = mustWithTimeout (Context.background (), Duration.ofSeconds (2));
    Duration ? remaining = ctx.remaining ();

    assert (remaining != null);
    assert (remaining.toSeconds () >= 1);

    ctx.cancel ();
}

void testWithValue () {
    Context root = Context.background ();
    Context with_user = mustWithValue (root, "user", "alice");
    Context with_trace = mustWithValue (with_user, "trace", "t-123");

    assert (mustValue (with_trace, "user") == "alice");
    assert (mustValue (with_trace, "trace") == "t-123");
    assert (mustValue (with_trace, "missing") == null);
}

void testDone () {
    Context ctx = mustWithCancel (Context.background ());

    ctx.cancel ();
    int signal = ctx.done ().receive ();

    assert (signal == 1 || signal == 0);
    assert (ctx.isCancelled () == true);
}

void testWithTimeoutInvalid () {
    bool thrown = false;
    try {
        Context.withTimeout (Context.background (), Duration.ofSeconds (-1));
    } catch (ContextError e) {
        thrown = true;
        assert (e is ContextError.INVALID_ARGUMENT);
    }
    assert (thrown);
}

void testWithValueInvalidKey () {
    bool thrown = false;
    try {
        Context.background ().withValue ("", "alice");
    } catch (ContextError e) {
        thrown = true;
        assert (e is ContextError.INVALID_ARGUMENT);
    }
    assert (thrown);
}

void testValueInvalidKey () {
    bool thrown = false;
    try {
        Context.background ().value ("");
    } catch (ContextError e) {
        thrown = true;
        assert (e is ContextError.INVALID_ARGUMENT);
    }
    assert (thrown);
}
