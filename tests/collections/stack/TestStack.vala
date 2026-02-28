using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testPushAndPop", testPushAndPop);
    Test.add_func ("/testPeek", testPeek);
    Test.add_func ("/testSize", testSize);
    Test.add_func ("/testIsEmpty", testIsEmpty);
    Test.add_func ("/testClear", testClear);
    Test.add_func ("/testPopEmpty", testPopEmpty);
    Test.add_func ("/testPeekEmpty", testPeekEmpty);
    Test.add_func ("/testLifoOrder", testLifoOrder);
    Test.run ();
}

void testPushAndPop () {
    var stack = new Stack<string> ();
    stack.push ("a");
    stack.push ("b");
    assert (stack.pop () == "b");
    assert (stack.pop () == "a");
}

void testPeek () {
    var stack = new Stack<string> ();
    stack.push ("x");
    assert (stack.peek () == "x");
    /* Peek does not remove */
    assert (stack.size () == 1);
}

void testSize () {
    var stack = new Stack<string> ();
    assert (stack.size () == 0);
    stack.push ("a");
    assert (stack.size () == 1);
    stack.push ("b");
    assert (stack.size () == 2);
    stack.pop ();
    assert (stack.size () == 1);
}

void testIsEmpty () {
    var stack = new Stack<string> ();
    assert (stack.isEmpty () == true);
    stack.push ("a");
    assert (stack.isEmpty () == false);
    stack.pop ();
    assert (stack.isEmpty () == true);
}

void testClear () {
    var stack = new Stack<string> ();
    stack.push ("a");
    stack.push ("b");
    stack.push ("c");
    stack.clear ();
    assert (stack.isEmpty ());
    assert (stack.size () == 0);
}

void testPopEmpty () {
    var stack = new Stack<string> ();
    assert (stack.pop () == null);
}

void testPeekEmpty () {
    var stack = new Stack<string> ();
    assert (stack.peek () == null);
}

void testLifoOrder () {
    var stack = new Stack<string> ();
    stack.push ("1");
    stack.push ("2");
    stack.push ("3");
    assert (stack.pop () == "3");
    assert (stack.pop () == "2");
    assert (stack.pop () == "1");
    assert (stack.pop () == null);
}
