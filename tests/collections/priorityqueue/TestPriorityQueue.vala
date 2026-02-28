using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/testAdd", testAdd);
    Test.add_func ("/testPoll", testPoll);
    Test.add_func ("/testPollEmpty", testPollEmpty);
    Test.add_func ("/testPeek", testPeek);
    Test.add_func ("/testPeekEmpty", testPeekEmpty);
    Test.add_func ("/testPollOrder", testPollOrder);
    Test.add_func ("/testRemove", testRemove);
    Test.add_func ("/testRemoveMissing", testRemoveMissing);
    Test.add_func ("/testContains", testContains);
    Test.add_func ("/testSize", testSize);
    Test.add_func ("/testIsEmpty", testIsEmpty);
    Test.add_func ("/testClear", testClear);
    Test.add_func ("/testToArray", testToArray);
    Test.add_func ("/testDuplicates", testDuplicates);
    Test.add_func ("/testSingleElement", testSingleElement);
    Test.add_func ("/testReverseOrder", testReverseOrder);

    Test.run ();
}

PriorityQueue<string> make_str_pq () {
    return new PriorityQueue<string> ((a, b) => {
        return strcmp (a, b);
    }, GLib.str_equal);
}

void testAdd () {
    var pq = make_str_pq ();
    pq.add ("b");
    assert (pq.size () == 1);

    pq.add ("a");
    assert (pq.size () == 2);

    // min element should be at head
    assert (pq.peek () == "a");
}

void testPoll () {
    var pq = make_str_pq ();
    pq.add ("c");
    pq.add ("a");
    pq.add ("b");

    assert (pq.poll () == "a");
    assert (pq.size () == 2);
    assert (pq.poll () == "b");
    assert (pq.poll () == "c");
    assert (pq.isEmpty ());
}

void testPollEmpty () {
    var pq = make_str_pq ();
    assert (pq.poll () == null);
}

void testPeek () {
    var pq = make_str_pq ();
    pq.add ("b");
    pq.add ("a");

    assert (pq.peek () == "a");
    assert (pq.size () == 2);

    // peek doesn't remove
    assert (pq.peek () == "a");
    assert (pq.size () == 2);
}

void testPeekEmpty () {
    var pq = make_str_pq ();
    assert (pq.peek () == null);
}

void testPollOrder () {
    var pq = make_str_pq ();
    pq.add ("delta");
    pq.add ("alpha");
    pq.add ("charlie");
    pq.add ("bravo");
    pq.add ("echo");

    assert (pq.poll () == "alpha");
    assert (pq.poll () == "bravo");
    assert (pq.poll () == "charlie");
    assert (pq.poll () == "delta");
    assert (pq.poll () == "echo");
}

void testRemove () {
    var pq = make_str_pq ();
    pq.add ("a");
    pq.add ("b");
    pq.add ("c");

    assert (pq.remove ("b"));
    assert (pq.size () == 2);
    assert (!pq.contains ("b"));

    // heap property maintained
    assert (pq.poll () == "a");
    assert (pq.poll () == "c");
}

void testRemoveMissing () {
    var pq = make_str_pq ();
    assert (!pq.remove ("x"));

    pq.add ("a");
    assert (!pq.remove ("z"));
    assert (pq.size () == 1);
}

void testContains () {
    var pq = make_str_pq ();
    pq.add ("apple");
    pq.add ("banana");

    assert (pq.contains ("apple"));
    assert (pq.contains ("banana"));
    assert (!pq.contains ("cherry"));

    // empty queue
    var empty = make_str_pq ();
    assert (!empty.contains ("x"));
}

void testSize () {
    var pq = make_str_pq ();
    assert (pq.size () == 0);

    pq.add ("a");
    assert (pq.size () == 1);

    pq.add ("b");
    assert (pq.size () == 2);

    pq.poll ();
    assert (pq.size () == 1);
}

void testIsEmpty () {
    var pq = make_str_pq ();
    assert (pq.isEmpty ());

    pq.add ("a");
    assert (!pq.isEmpty ());

    pq.poll ();
    assert (pq.isEmpty ());
}

void testClear () {
    var pq = make_str_pq ();
    pq.add ("a");
    pq.add ("b");
    pq.add ("c");
    assert (pq.size () == 3);

    pq.clear ();
    assert (pq.isEmpty ());
    assert (pq.size () == 0);
}

void testToArray () {
    var pq = make_str_pq ();
    pq.add ("b");
    pq.add ("a");
    pq.add ("c");

    string[] arr = pq.toArray ();
    assert (arr.length == 3);

    // empty queue
    var empty = make_str_pq ();
    string[] emptyArr = empty.toArray ();
    assert (emptyArr.length == 0);
}

void testDuplicates () {
    var pq = make_str_pq ();
    pq.add ("a");
    pq.add ("a");
    pq.add ("b");

    assert (pq.size () == 3);
    assert (pq.poll () == "a");
    assert (pq.poll () == "a");
    assert (pq.poll () == "b");
}

void testSingleElement () {
    var pq = make_str_pq ();
    pq.add ("only");

    assert (pq.peek () == "only");
    assert (pq.poll () == "only");
    assert (pq.isEmpty ());
}

void testReverseOrder () {
    // max-heap using reversed comparator
    var pq = new PriorityQueue<string> ((a, b) => {
        return strcmp (b, a);
    }, GLib.str_equal);

    pq.add ("a");
    pq.add ("c");
    pq.add ("b");

    assert (pq.poll () == "c");
    assert (pq.poll () == "b");
    assert (pq.poll () == "a");
}
