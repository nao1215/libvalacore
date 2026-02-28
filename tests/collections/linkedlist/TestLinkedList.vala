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
    Test.add_func ("/testClear", testClear);
    Test.add_func ("/testContains", testContains);
    Test.add_func ("/testIndexOf", testIndexOf);
    Test.add_func ("/testGet", testGet);
    Test.add_func ("/testGetOutOfBounds", testGetOutOfBounds);
    Test.add_func ("/testForEach", testForEach);
    Test.add_func ("/testToArray", testToArray);
    Test.add_func ("/testUsedAsQueue", testUsedAsQueue);
    Test.add_func ("/testUsedAsStack", testUsedAsStack);

    Test.run ();
}

void testAddFirst () {
    var list = new LinkedList<string>(GLib.str_equal);
    list.addFirst ("a");
    list.addFirst ("b");
    list.addFirst ("c");

    assert (list.peekFirst () == "c");
    assert (list.peekLast () == "a");
    assert (list.size () == 3);
}

void testAddLast () {
    var list = new LinkedList<string>(GLib.str_equal);
    list.addLast ("a");
    list.addLast ("b");
    list.addLast ("c");

    assert (list.peekFirst () == "a");
    assert (list.peekLast () == "c");
    assert (list.size () == 3);
}

void testRemoveFirst () {
    var list = new LinkedList<string>(GLib.str_equal);
    list.addLast ("a");
    list.addLast ("b");
    list.addLast ("c");

    assert (list.removeFirst () == "a");
    assert (list.size () == 2);
    assert (list.removeFirst () == "b");
    assert (list.removeFirst () == "c");
    assert (list.isEmpty ());
}

void testRemoveFirstEmpty () {
    var list = new LinkedList<string>(GLib.str_equal);
    assert (list.removeFirst () == null);
}

void testRemoveLast () {
    var list = new LinkedList<string>(GLib.str_equal);
    list.addLast ("a");
    list.addLast ("b");
    list.addLast ("c");

    assert (list.removeLast () == "c");
    assert (list.size () == 2);
    assert (list.removeLast () == "b");
    assert (list.removeLast () == "a");
    assert (list.isEmpty ());
}

void testRemoveLastEmpty () {
    var list = new LinkedList<string>(GLib.str_equal);
    assert (list.removeLast () == null);
}

void testPeekFirst () {
    var list = new LinkedList<string>(GLib.str_equal);
    list.addLast ("a");
    list.addLast ("b");

    assert (list.peekFirst () == "a");
    assert (list.size () == 2);
}

void testPeekFirstEmpty () {
    var list = new LinkedList<string>(GLib.str_equal);
    assert (list.peekFirst () == null);
}

void testPeekLast () {
    var list = new LinkedList<string>(GLib.str_equal);
    list.addLast ("a");
    list.addLast ("b");

    assert (list.peekLast () == "b");
    assert (list.size () == 2);
}

void testPeekLastEmpty () {
    var list = new LinkedList<string>(GLib.str_equal);
    assert (list.peekLast () == null);
}

void testSize () {
    var list = new LinkedList<string>(GLib.str_equal);
    assert (list.size () == 0);

    list.addLast ("a");
    assert (list.size () == 1);

    list.addLast ("b");
    assert (list.size () == 2);

    list.removeFirst ();
    assert (list.size () == 1);
}

void testIsEmpty () {
    var list = new LinkedList<string>(GLib.str_equal);
    assert (list.isEmpty ());

    list.addLast ("a");
    assert (!list.isEmpty ());

    list.removeFirst ();
    assert (list.isEmpty ());
}

void testClear () {
    var list = new LinkedList<string>(GLib.str_equal);
    list.addLast ("a");
    list.addLast ("b");
    list.addLast ("c");
    assert (list.size () == 3);

    list.clear ();
    assert (list.isEmpty ());
    assert (list.size () == 0);
}

void testContains () {
    var list = new LinkedList<string>(GLib.str_equal);
    list.addLast ("apple");
    list.addLast ("banana");
    list.addLast ("cherry");

    assert (list.contains ("apple"));
    assert (list.contains ("banana"));
    assert (list.contains ("cherry"));
    assert (!list.contains ("grape"));

    // empty list
    var empty = new LinkedList<string>(GLib.str_equal);
    assert (!empty.contains ("x"));
}

void testIndexOf () {
    var list = new LinkedList<string>(GLib.str_equal);
    list.addLast ("a");
    list.addLast ("b");
    list.addLast ("c");
    list.addLast ("b");

    assert (list.indexOf ("a") == 0);
    assert (list.indexOf ("b") == 1);
    assert (list.indexOf ("c") == 2);
    assert (list.indexOf ("z") == -1);

    // empty list
    var empty = new LinkedList<string>(GLib.str_equal);
    assert (empty.indexOf ("x") == -1);
}

void testGet () {
    var list = new LinkedList<string>(GLib.str_equal);
    list.addLast ("a");
    list.addLast ("b");
    list.addLast ("c");

    assert (list.get (0) == "a");
    assert (list.get (1) == "b");
    assert (list.get (2) == "c");
}

void testGetOutOfBounds () {
    var list = new LinkedList<string>(GLib.str_equal);
    assert (list.get (0) == null);
    assert (list.get (-1) == null);

    list.addLast ("a");
    assert (list.get (1) == null);
    assert (list.get (100) == null);
}

void testForEach () {
    var list = new LinkedList<string>(GLib.str_equal);
    list.addLast ("a");
    list.addLast ("b");
    list.addLast ("c");

    var collected = new ArrayList<string>(GLib.str_equal);
    list.forEach ((s) => {
        collected.add (s);
    });

    assert (collected.size () == 3);
    assert (collected.get (0) == "a");
    assert (collected.get (1) == "b");
    assert (collected.get (2) == "c");
}

void testToArray () {
    var list = new LinkedList<string>(GLib.str_equal);
    list.addLast ("a");
    list.addLast ("b");
    list.addLast ("c");

    string[] arr = list.toArray ();
    assert (arr.length == 3);
    assert (arr[0] == "a");
    assert (arr[1] == "b");
    assert (arr[2] == "c");

    // empty list
    var empty = new LinkedList<string>(GLib.str_equal);
    string[] emptyArr = empty.toArray ();
    assert (emptyArr.length == 0);
}

void testUsedAsQueue () {
    var list = new LinkedList<string>(GLib.str_equal);
    list.addLast ("a");
    list.addLast ("b");
    list.addLast ("c");

    assert (list.removeFirst () == "a");
    assert (list.removeFirst () == "b");
    assert (list.removeFirst () == "c");
    assert (list.isEmpty ());
}

void testUsedAsStack () {
    var list = new LinkedList<string>(GLib.str_equal);
    list.addFirst ("a");
    list.addFirst ("b");
    list.addFirst ("c");

    assert (list.removeFirst () == "c");
    assert (list.removeFirst () == "b");
    assert (list.removeFirst () == "a");
    assert (list.isEmpty ());
}
