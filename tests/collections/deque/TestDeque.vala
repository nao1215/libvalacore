using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/testAddFirst", testAddFirst);
    Test.add_func ("/testAddLast", testAddLast);
    Test.add_func ("/testRemoveFirst", testRemoveFirst);
    Test.add_func ("/testRemoveFirstEmpty", testRemoveFirstEmpty);
    Test.add_func ("/testRemoveLast", testRemoveLast);
    Test.add_func ("/testRemoveLastEmpty", testRemoveLastEmpty);
    Test.add_func ("/testPeekFirst", testPeekFirst);
    Test.add_func ("/testPeekFirstEmpty", testPeekFirstEmpty);
    Test.add_func ("/testPeekLast", testPeekLast);
    Test.add_func ("/testPeekLastEmpty", testPeekLastEmpty);
    Test.add_func ("/testSize", testSize);
    Test.add_func ("/testIsEmpty", testIsEmpty);
    Test.add_func ("/testContains", testContains);
    Test.add_func ("/testContainsEmpty", testContainsEmpty);
    Test.add_func ("/testClear", testClear);
    Test.add_func ("/testToArray", testToArray);
    Test.add_func ("/testForEach", testForEach);
    Test.add_func ("/testFifoPattern", testFifoPattern);
    Test.add_func ("/testLifoPattern", testLifoPattern);

    Test.run ();
}

void testAddFirst () {
    var deque = new Deque<string>(GLib.str_equal);
    deque.addFirst ("a");
    deque.addFirst ("b");
    deque.addFirst ("c");

    assert (deque.peekFirst () == "c");
    assert (deque.peekLast () == "a");
    assert (deque.size () == 3);
}

void testAddLast () {
    var deque = new Deque<string>(GLib.str_equal);
    deque.addLast ("a");
    deque.addLast ("b");
    deque.addLast ("c");

    assert (deque.peekFirst () == "a");
    assert (deque.peekLast () == "c");
    assert (deque.size () == 3);
}

void testRemoveFirst () {
    var deque = new Deque<string>(GLib.str_equal);
    deque.addLast ("a");
    deque.addLast ("b");
    deque.addLast ("c");

    assert (deque.removeFirst () == "a");
    assert (deque.size () == 2);
    assert (deque.removeFirst () == "b");
    assert (deque.removeFirst () == "c");
    assert (deque.isEmpty ());
}

void testRemoveFirstEmpty () {
    var deque = new Deque<string>(GLib.str_equal);
    assert (deque.removeFirst () == null);
}

void testRemoveLast () {
    var deque = new Deque<string>(GLib.str_equal);
    deque.addLast ("a");
    deque.addLast ("b");
    deque.addLast ("c");

    assert (deque.removeLast () == "c");
    assert (deque.size () == 2);
    assert (deque.removeLast () == "b");
    assert (deque.removeLast () == "a");
    assert (deque.isEmpty ());
}

void testRemoveLastEmpty () {
    var deque = new Deque<string>(GLib.str_equal);
    assert (deque.removeLast () == null);
}

void testPeekFirst () {
    var deque = new Deque<string>(GLib.str_equal);
    deque.addLast ("a");
    deque.addLast ("b");

    assert (deque.peekFirst () == "a");
    assert (deque.size () == 2);
}

void testPeekFirstEmpty () {
    var deque = new Deque<string>(GLib.str_equal);
    assert (deque.peekFirst () == null);
}

void testPeekLast () {
    var deque = new Deque<string>(GLib.str_equal);
    deque.addLast ("a");
    deque.addLast ("b");

    assert (deque.peekLast () == "b");
    assert (deque.size () == 2);
}

void testPeekLastEmpty () {
    var deque = new Deque<string>(GLib.str_equal);
    assert (deque.peekLast () == null);
}

void testSize () {
    var deque = new Deque<string>(GLib.str_equal);
    assert (deque.size () == 0);

    deque.addLast ("a");
    assert (deque.size () == 1);

    deque.addFirst ("b");
    assert (deque.size () == 2);

    deque.removeFirst ();
    assert (deque.size () == 1);
}

void testIsEmpty () {
    var deque = new Deque<string>(GLib.str_equal);
    assert (deque.isEmpty ());

    deque.addLast ("a");
    assert (!deque.isEmpty ());

    deque.removeFirst ();
    assert (deque.isEmpty ());
}

void testContains () {
    var deque = new Deque<string>(GLib.str_equal);
    deque.addLast ("apple");
    deque.addLast ("banana");
    deque.addLast ("cherry");

    assert (deque.contains ("apple"));
    assert (deque.contains ("banana"));
    assert (deque.contains ("cherry"));
    assert (!deque.contains ("grape"));
}

void testContainsEmpty () {
    var deque = new Deque<string>(GLib.str_equal);
    assert (!deque.contains ("anything"));
}

void testClear () {
    var deque = new Deque<string>(GLib.str_equal);
    deque.addLast ("a");
    deque.addLast ("b");
    deque.addLast ("c");
    assert (deque.size () == 3);

    deque.clear ();
    assert (deque.isEmpty ());
    assert (deque.size () == 0);
}

void testToArray () {
    var deque = new Deque<string>(GLib.str_equal);
    deque.addLast ("a");
    deque.addLast ("b");
    deque.addLast ("c");

    string[] arr = deque.toArray ();
    assert (arr.length == 3);
    assert (arr[0] == "a");
    assert (arr[1] == "b");
    assert (arr[2] == "c");

    // empty deque
    var empty = new Deque<string>(GLib.str_equal);
    string[] emptyArr = empty.toArray ();
    assert (emptyArr.length == 0);
}

void testForEach () {
    var deque = new Deque<string>(GLib.str_equal);
    deque.addLast ("a");
    deque.addLast ("b");
    deque.addLast ("c");

    var collected = new ArrayList<string>(GLib.str_equal);
    deque.forEach ((s) => {
        collected.add (s);
    });

    assert (collected.size () == 3);
    assert (collected.get (0) == "a");
    assert (collected.get (1) == "b");
    assert (collected.get (2) == "c");
}

void testFifoPattern () {
    var deque = new Deque<string>(GLib.str_equal);
    deque.addLast ("1");
    deque.addLast ("2");
    deque.addLast ("3");

    assert (deque.removeFirst () == "1");
    assert (deque.removeFirst () == "2");
    assert (deque.removeFirst () == "3");
}

void testLifoPattern () {
    var deque = new Deque<string>(GLib.str_equal);
    deque.addFirst ("1");
    deque.addFirst ("2");
    deque.addFirst ("3");

    assert (deque.removeFirst () == "3");
    assert (deque.removeFirst () == "2");
    assert (deque.removeFirst () == "1");
}
