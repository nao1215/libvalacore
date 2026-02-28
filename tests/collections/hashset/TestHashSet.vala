using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/testAdd", testAdd);
    Test.add_func ("/testAddDuplicate", testAddDuplicate);
    Test.add_func ("/testRemove", testRemove);
    Test.add_func ("/testRemoveMissing", testRemoveMissing);
    Test.add_func ("/testContains", testContains);
    Test.add_func ("/testSize", testSize);
    Test.add_func ("/testIsEmpty", testIsEmpty);
    Test.add_func ("/testClear", testClear);
    Test.add_func ("/testUnion", testUnion);
    Test.add_func ("/testIntersection", testIntersection);
    Test.add_func ("/testDifference", testDifference);
    Test.add_func ("/testIsSubsetOf", testIsSubsetOf);
    Test.add_func ("/testToArray", testToArray);
    Test.add_func ("/testForEach", testForEach);
    Test.add_func ("/testAddAll", testAddAll);
    Test.add_func ("/testEmptySetOperations", testEmptySetOperations);

    Test.run ();
}

void testAdd () {
    var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    assert (set.add ("apple"));
    assert (set.size () == 1);
    assert (set.contains ("apple"));

    assert (set.add ("banana"));
    assert (set.size () == 2);
}

void testAddDuplicate () {
    var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    assert (set.add ("apple"));
    assert (!set.add ("apple"));
    assert (set.size () == 1);
}

void testRemove () {
    var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    set.add ("apple");
    set.add ("banana");

    assert (set.remove ("apple"));
    assert (!set.contains ("apple"));
    assert (set.size () == 1);

    assert (set.remove ("banana"));
    assert (set.isEmpty ());
}

void testRemoveMissing () {
    var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    assert (!set.remove ("nothing"));

    set.add ("apple");
    assert (!set.remove ("banana"));
    assert (set.size () == 1);
}

void testContains () {
    var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    assert (!set.contains ("apple"));

    set.add ("apple");
    set.add ("banana");
    assert (set.contains ("apple"));
    assert (set.contains ("banana"));
    assert (!set.contains ("cherry"));
}

void testSize () {
    var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    assert (set.size () == 0);

    set.add ("a");
    assert (set.size () == 1);

    set.add ("b");
    assert (set.size () == 2);

    set.add ("a");
    assert (set.size () == 2);
}

void testIsEmpty () {
    var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    assert (set.isEmpty ());

    set.add ("a");
    assert (!set.isEmpty ());

    set.remove ("a");
    assert (set.isEmpty ());
}

void testClear () {
    var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    set.add ("a");
    set.add ("b");
    set.add ("c");
    assert (set.size () == 3);

    set.clear ();
    assert (set.isEmpty ());
    assert (set.size () == 0);
}

void testUnion () {
    var a = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    a.add ("1");
    a.add ("2");

    var b = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    b.add ("2");
    b.add ("3");

    var u = a.union (b);
    assert (u.size () == 3);
    assert (u.contains ("1"));
    assert (u.contains ("2"));
    assert (u.contains ("3"));

    // originals unchanged
    assert (a.size () == 2);
    assert (b.size () == 2);
}

void testIntersection () {
    var a = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    a.add ("1");
    a.add ("2");
    a.add ("3");

    var b = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    b.add ("2");
    b.add ("3");
    b.add ("4");

    var i = a.intersection (b);
    assert (i.size () == 2);
    assert (i.contains ("2"));
    assert (i.contains ("3"));
    assert (!i.contains ("1"));
    assert (!i.contains ("4"));
}

void testDifference () {
    var a = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    a.add ("1");
    a.add ("2");
    a.add ("3");

    var b = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    b.add ("2");
    b.add ("4");

    var d = a.difference (b);
    assert (d.size () == 2);
    assert (d.contains ("1"));
    assert (d.contains ("3"));
    assert (!d.contains ("2"));
}

void testIsSubsetOf () {
    var a = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    a.add ("1");
    a.add ("2");

    var b = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    b.add ("1");
    b.add ("2");
    b.add ("3");

    assert (a.isSubsetOf (b));
    assert (!b.isSubsetOf (a));

    // equal sets
    var c = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    c.add ("1");
    c.add ("2");
    assert (a.isSubsetOf (c));
    assert (c.isSubsetOf (a));

    // empty set is subset of any set
    var empty = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    assert (empty.isSubsetOf (a));
    assert (empty.isSubsetOf (empty));
}

void testToArray () {
    var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    set.add ("a");
    set.add ("b");
    set.add ("c");

    string[] arr = set.toArray ();
    assert (arr.length == 3);

    // verify all elements present (order not guaranteed)
    var check = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    for (int i = 0; i < arr.length; i++) {
        check.add (arr[i]);
    }
    assert (check.contains ("a"));
    assert (check.contains ("b"));
    assert (check.contains ("c"));

    // empty set
    var empty = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    string[] emptyArr = empty.toArray ();
    assert (emptyArr.length == 0);
}

void testForEach () {
    var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    set.add ("a");
    set.add ("b");
    set.add ("c");

    var collected = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    set.forEach ((s) => {
        collected.add (s);
    });

    assert (collected.size () == 3);
    assert (collected.contains ("a"));
    assert (collected.contains ("b"));
    assert (collected.contains ("c"));
}

void testAddAll () {
    var a = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    a.add ("1");

    var b = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    b.add ("2");
    b.add ("3");

    a.addAll (b);
    assert (a.size () == 3);
    assert (a.contains ("1"));
    assert (a.contains ("2"));
    assert (a.contains ("3"));

    // addAll with overlapping elements
    var c = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    c.add ("1");
    c.add ("4");
    a.addAll (c);
    assert (a.size () == 4);
}

void testEmptySetOperations () {
    var a = new HashSet<string> (GLib.str_hash, GLib.str_equal);
    var b = new HashSet<string> (GLib.str_hash, GLib.str_equal);

    // union of empty sets
    var u = a.union (b);
    assert (u.isEmpty ());

    // intersection of empty sets
    var i = a.intersection (b);
    assert (i.isEmpty ());

    // difference of empty sets
    var d = a.difference (b);
    assert (d.isEmpty ());

    // union with non-empty set
    b.add ("x");
    var u2 = a.union (b);
    assert (u2.size () == 1);
    assert (u2.contains ("x"));

    // difference of non-empty minus empty
    var d2 = b.difference (a);
    assert (d2.size () == 1);
    assert (d2.contains ("x"));
}
