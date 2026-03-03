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
    var created = Context.withCancel (parent);
    assert (created.isOk ());
    return created.unwrap ();
}

Context mustWithTimeout (Context parent, Duration timeout) {
    var created = Context.withTimeout (parent, timeout);
    assert (created.isOk ());
    return created.unwrap ();
}

Context mustWithDeadline (Context parent, Vala.Time.DateTime deadline) {
    var created = Context.withDeadline (parent, deadline);
    assert (created.isOk ());
    return created.unwrap ();
}

string ? mustValue (Context ctx, string key) {
    var result = ctx.value (key);
    assert (result.isOk ());
    return result.unwrap ();
}

Context mustWithValue (Context ctx, string key, string value) {
    var child = ctx.withValue (key, value);
    assert (child.isOk ());
    return child.unwrap ();
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
    var created = Context.withTimeout (Context.background (), Duration.ofSeconds (-1));
    assert (created.isError ());
    assert (created.unwrapError () is ContextError.INVALID_ARGUMENT);
    assert (created.unwrapError ().message == "timeout must be non-negative");
}

void testWithValueInvalidKey () {
    var child = Context.background ().withValue ("", "alice");
    assert (child.isError ());
    assert (child.unwrapError () is ContextError.INVALID_ARGUMENT);
    assert (child.unwrapError ().message == "key must not be empty");
}

void testValueInvalidKey () {
    var value = Context.background ().value ("");
    assert (value.isError ());
    assert (value.unwrapError () is ContextError.INVALID_ARGUMENT);
    assert (value.unwrapError ().message == "key must not be empty");
}
