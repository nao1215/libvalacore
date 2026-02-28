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

    Test.run ();
}

void testBackground () {
    Context ctx = Context.background ();

    assert (ctx.isCancelled () == false);
    assert (ctx.error () == null);
    assert (ctx.remaining () == null);
}

void testCancel () {
    Context root = Context.background ();
    Context ctx = Context.withCancel (root);

    assert (ctx.isCancelled () == false);
    ctx.cancel ();

    assert (ctx.isCancelled () == true);
    assert (ctx.error () == "cancelled");
}

void testParentPropagation () {
    Context parent = Context.withCancel (Context.background ());
    Context child = Context.withCancel (parent);

    parent.cancel ();
    child.done ().receive ();

    assert (child.isCancelled () == true);
    assert (child.error () == "cancelled");
}

void testWithTimeout () {
    Context parent = Context.background ();
    Context ctx = Context.withTimeout (parent, Duration.ofSeconds (0));

    ctx.done ().receive ();
    assert (ctx.isCancelled () == true);
    assert (ctx.error () == "timeout");
}

void testWithDeadline () {
    Context parent = Context.background ();
    Vala.Time.DateTime now = Vala.Time.DateTime.now ();
    Context ctx = Context.withDeadline (parent, now);

    ctx.done ().receive ();
    assert (ctx.isCancelled () == true);
    assert (ctx.error () == "timeout");
}

void testRemaining () {
    Context ctx = Context.withTimeout (Context.background (), Duration.ofSeconds (2));
    Duration ? remaining = ctx.remaining ();

    assert (remaining != null);
    assert (remaining.toSeconds () >= 1);

    ctx.cancel ();
}

void testWithValue () {
    Context root = Context.background ();
    Context with_user = root.withValue ("user", "alice");
    Context with_trace = with_user.withValue ("trace", "t-123");

    assert (with_trace.value ("user") == "alice");
    assert (with_trace.value ("trace") == "t-123");
    assert (with_trace.value ("missing") == null);
}

void testDone () {
    Context ctx = Context.withCancel (Context.background ());

    ctx.cancel ();
    int signal = ctx.done ().receive ();

    assert (signal == 1 || signal == 0);
    assert (ctx.isCancelled () == true);
}
