using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/testAdd", testAdd);
    Test.add_func ("/testAddAll", testAddAll);
    Test.add_func ("/testGet", testGet);
    Test.add_func ("/testGetOutOfBounds", testGetOutOfBounds);
    Test.add_func ("/testSet", testSet);
    Test.add_func ("/testSetOutOfBounds", testSetOutOfBounds);
    Test.add_func ("/testRemoveAt", testRemoveAt);
    Test.add_func ("/testRemoveAtOutOfBounds", testRemoveAtOutOfBounds);
    Test.add_func ("/testContains", testContains);
    Test.add_func ("/testIndexOf", testIndexOf);
    Test.add_func ("/testIndexOfNotFound", testIndexOfNotFound);
    Test.add_func ("/testSize", testSize);
    Test.add_func ("/testIsEmpty", testIsEmpty);
    Test.add_func ("/testClear", testClear);
    Test.add_func ("/testToArray", testToArray);
    Test.add_func ("/testSort", testSort);
    Test.add_func ("/testForEach", testForEach);
    Test.add_func ("/testMap", testMap);
    Test.add_func ("/testFilter", testFilter);
    Test.add_func ("/testReduce", testReduce);
    Test.add_func ("/testFind", testFind);
    Test.add_func ("/testFindNotFound", testFindNotFound);
    Test.add_func ("/testSubList", testSubList);
    Test.add_func ("/testSubListBoundary", testSubListBoundary);

    Test.run ();
}

void testAdd () {
    var list = new ArrayList<string>(GLib.str_equal);
    list.add ("hello");
    assert (list.size () == 1);
    assert (list.get (0) == "hello");

    list.add ("world");
    assert (list.size () == 2);
    assert (list.get (1) == "world");
}

void testAddAll () {
    var list1 = new ArrayList<string>(GLib.str_equal);
    list1.add ("a");
    list1.add ("b");

    var list2 = new ArrayList<string>(GLib.str_equal);
    list2.add ("c");
    list2.add ("d");

    list1.addAll (list2);
    assert (list1.size () == 4);
    assert (list1.get (0) == "a");
    assert (list1.get (1) == "b");
    assert (list1.get (2) == "c");
    assert (list1.get (3) == "d");
}

void testGet () {
    var list = new ArrayList<string>(GLib.str_equal);
    list.add ("first");
    list.add ("second");
    list.add ("third");

    assert (list.get (0) == "first");
    assert (list.get (1) == "second");
    assert (list.get (2) == "third");
}

void testGetOutOfBounds () {
    var list = new ArrayList<string>(GLib.str_equal);
    assert (list.get (0) == null);
    assert (list.get (-1) == null);

    list.add ("a");
    assert (list.get (1) == null);
    assert (list.get (100) == null);
}

void testSet () {
    var list = new ArrayList<string>(GLib.str_equal);
    list.add ("a");
    list.add ("b");

    assert (list.set (0, "x"));
    assert (list.get (0) == "x");

    assert (list.set (1, "y"));
    assert (list.get (1) == "y");
}

void testSetOutOfBounds () {
    var list = new ArrayList<string>(GLib.str_equal);
    assert (!list.set (0, "x"));
    assert (!list.set (-1, "x"));

    list.add ("a");
    assert (!list.set (1, "x"));
    assert (!list.set (100, "x"));
}

void testRemoveAt () {
    var list = new ArrayList<string>(GLib.str_equal);
    list.add ("a");
    list.add ("b");
    list.add ("c");

    assert (list.removeAt (1) == "b");
    assert (list.size () == 2);
    assert (list.get (0) == "a");
    assert (list.get (1) == "c");

    assert (list.removeAt (0) == "a");
    assert (list.size () == 1);
    assert (list.get (0) == "c");
}

void testRemoveAtOutOfBounds () {
    var list = new ArrayList<string>(GLib.str_equal);
    assert (list.removeAt (0) == null);
    assert (list.removeAt (-1) == null);

    list.add ("a");
    assert (list.removeAt (1) == null);
    assert (list.removeAt (100) == null);
}

void testContains () {
    var list = new ArrayList<string>(GLib.str_equal);
    list.add ("apple");
    list.add ("banana");
    list.add ("cherry");

    assert (list.contains ("apple"));
    assert (list.contains ("banana"));
    assert (list.contains ("cherry"));
    assert (!list.contains ("grape"));
}

void testIndexOf () {
    var list = new ArrayList<string>(GLib.str_equal);
    list.add ("a");
    list.add ("b");
    list.add ("c");
    list.add ("b");

    assert (list.indexOf ("a") == 0);
    assert (list.indexOf ("b") == 1);
    assert (list.indexOf ("c") == 2);
}

void testIndexOfNotFound () {
    var list = new ArrayList<string>(GLib.str_equal);
    assert (list.indexOf ("x") == -1);

    list.add ("a");
    assert (list.indexOf ("z") == -1);
}

void testSize () {
    var list = new ArrayList<string>(GLib.str_equal);
    assert (list.size () == 0);

    list.add ("a");
    assert (list.size () == 1);

    list.add ("b");
    assert (list.size () == 2);

    list.add ("c");
    assert (list.size () == 3);
}

void testIsEmpty () {
    var list = new ArrayList<string>(GLib.str_equal);
    assert (list.isEmpty ());

    list.add ("a");
    assert (!list.isEmpty ());
}

void testClear () {
    var list = new ArrayList<string>(GLib.str_equal);
    list.add ("a");
    list.add ("b");
    list.add ("c");
    assert (list.size () == 3);

    list.clear ();
    assert (list.isEmpty ());
    assert (list.size () == 0);
}

void testToArray () {
    var list = new ArrayList<string>(GLib.str_equal);
    list.add ("a");
    list.add ("b");
    list.add ("c");

    string[] arr = list.toArray ();
    assert (arr.length == 3);
    assert (arr[0] == "a");
    assert (arr[1] == "b");
    assert (arr[2] == "c");

    // empty list
    var empty = new ArrayList<string>(GLib.str_equal);
    string[] emptyArr = empty.toArray ();
    assert (emptyArr.length == 0);
}

void testSort () {
    var list = new ArrayList<string>(GLib.str_equal);
    list.add ("cherry");
    list.add ("apple");
    list.add ("banana");

    list.sort ((a, b) => {
        return strcmp (a, b);
    });

    assert (list.get (0) == "apple");
    assert (list.get (1) == "banana");
    assert (list.get (2) == "cherry");
}

void testForEach () {
    var list = new ArrayList<string>(GLib.str_equal);
    list.add ("a");
    list.add ("b");
    list.add ("c");

    var result = new ArrayList<string>(GLib.str_equal);
    list.forEach ((s) => {
        result.add (s);
    });

    assert (result.size () == 3);
    assert (result.get (0) == "a");
    assert (result.get (1) == "b");
    assert (result.get (2) == "c");
}

void testMap () {
    var list = new ArrayList<string>(GLib.str_equal);
    list.add ("hello");
    list.add ("world");

    var upper = list.map<string>((s) => {
        return s.up ();
    });

    assert (upper.size () == 2);
    assert (upper.get (0) == "HELLO");
    assert (upper.get (1) == "WORLD");
}

void testFilter () {
    var list = new ArrayList<string>(GLib.str_equal);
    list.add ("apple");
    list.add ("banana");
    list.add ("avocado");
    list.add ("cherry");

    var filtered = list.filter ((s) => {
        return s.has_prefix ("a");
    });

    assert (filtered.size () == 2);
    assert (filtered.get (0) == "apple");
    assert (filtered.get (1) == "avocado");
}

void testReduce () {
    var list = new ArrayList<string>(GLib.str_equal);
    list.add ("a");
    list.add ("b");
    list.add ("c");

    var joined = list.reduce<string>("", (acc, s) => {
        return acc + s;
    });
    assert (joined == "abc");

    // empty list reduces to initial value
    var empty = new ArrayList<string>(GLib.str_equal);
    var result = empty.reduce<string>("init", (acc, s) => {
        return acc + s;
    });
    assert (result == "init");
}

void testFind () {
    var list = new ArrayList<string>(GLib.str_equal);
    list.add ("apple");
    list.add ("banana");
    list.add ("cherry");

    var found = list.find ((s) => {
        return s == "banana";
    });
    assert (found.isPresent ());
    assert (found.get () == "banana");
}

void testFindNotFound () {
    var list = new ArrayList<string>(GLib.str_equal);
    list.add ("apple");
    list.add ("banana");

    var found = list.find ((s) => {
        return s == "grape";
    });
    assert (found.isEmpty ());

    // empty list
    var empty = new ArrayList<string>(GLib.str_equal);
    var emptyResult = empty.find ((s) => {
        return true;
    });
    assert (emptyResult.isEmpty ());
}

void testSubList () {
    var list = new ArrayList<string>(GLib.str_equal);
    list.add ("a");
    list.add ("b");
    list.add ("c");
    list.add ("d");
    list.add ("e");

    var sub = list.subList (1, 4);
    assert (sub.size () == 3);
    assert (sub.get (0) == "b");
    assert (sub.get (1) == "c");
    assert (sub.get (2) == "d");

    // full range
    var full = list.subList (0, 5);
    assert (full.size () == 5);

    // empty range
    var empty = list.subList (2, 2);
    assert (empty.size () == 0);
}

void testSubListBoundary () {
    var list = new ArrayList<string>(GLib.str_equal);
    list.add ("a");
    list.add ("b");
    list.add ("c");

    // negative from is clamped to 0
    var sub1 = list.subList (-1, 2);
    assert (sub1.size () == 2);
    assert (sub1.get (0) == "a");

    // to beyond length is clamped
    var sub2 = list.subList (1, 100);
    assert (sub2.size () == 2);
    assert (sub2.get (0) == "b");
    assert (sub2.get (1) == "c");

    // from > to returns empty
    var sub3 = list.subList (3, 1);
    assert (sub3.size () == 0);

    // empty list
    var empty = new ArrayList<string>(GLib.str_equal);
    var sub4 = empty.subList (0, 0);
    assert (sub4.size () == 0);
}
