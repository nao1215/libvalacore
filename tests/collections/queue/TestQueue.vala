using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testEnqueueAndDequeue", testEnqueueAndDequeue);
    Test.add_func ("/testPeek", testPeek);
    Test.add_func ("/testSize", testSize);
    Test.add_func ("/testIsEmpty", testIsEmpty);
    Test.add_func ("/testClear", testClear);
    Test.add_func ("/testDequeueEmpty", testDequeueEmpty);
    Test.add_func ("/testPeekEmpty", testPeekEmpty);
    Test.add_func ("/testFifoOrder", testFifoOrder);
    Test.run ();
}

void testEnqueueAndDequeue () {
    var queue = new Vala.Collections.Queue<string> ();
    queue.enqueue ("a");
    queue.enqueue ("b");
    assert (queue.dequeue () == "a");
    assert (queue.dequeue () == "b");
}

void testPeek () {
    var queue = new Vala.Collections.Queue<string> ();
    queue.enqueue ("x");
    assert (queue.peek () == "x");
    /* Peek does not remove */
    assert (queue.size () == 1);
}

void testSize () {
    var queue = new Vala.Collections.Queue<string> ();
    assert (queue.size () == 0);
    queue.enqueue ("a");
    assert (queue.size () == 1);
    queue.enqueue ("b");
    assert (queue.size () == 2);
    queue.dequeue ();
    assert (queue.size () == 1);
}

void testIsEmpty () {
    var queue = new Vala.Collections.Queue<string> ();
    assert (queue.isEmpty () == true);
    queue.enqueue ("a");
    assert (queue.isEmpty () == false);
    queue.dequeue ();
    assert (queue.isEmpty () == true);
}

void testClear () {
    var queue = new Vala.Collections.Queue<string> ();
    queue.enqueue ("a");
    queue.enqueue ("b");
    queue.enqueue ("c");
    queue.clear ();
    assert (queue.isEmpty ());
    assert (queue.size () == 0);
}

void testDequeueEmpty () {
    var queue = new Vala.Collections.Queue<string> ();
    assert (queue.dequeue () == null);
}

void testPeekEmpty () {
    var queue = new Vala.Collections.Queue<string> ();
    assert (queue.peek () == null);
}

void testFifoOrder () {
    var queue = new Vala.Collections.Queue<string> ();
    queue.enqueue ("1");
    queue.enqueue ("2");
    queue.enqueue ("3");
    assert (queue.dequeue () == "1");
    assert (queue.dequeue () == "2");
    assert (queue.dequeue () == "3");
    assert (queue.dequeue () == null);
}
