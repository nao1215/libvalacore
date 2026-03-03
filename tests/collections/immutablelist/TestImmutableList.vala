using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/collections/immutablelist/testConstruct", testConstruct);
    Test.add_func ("/collections/immutablelist/testBasicRead", testBasicRead);
    Test.add_func ("/collections/immutablelist/testContainsAndEmpty", testContainsAndEmpty);
    Test.add_func ("/collections/immutablelist/testToArrayReturnsCopy", testToArrayReturnsCopy);
    Test.add_func ("/collections/immutablelist/testGetOutOfBounds", testGetOutOfBounds);
    Test.run ();
}

void testConstruct () {
    ImmutableList<string> list = new ImmutableList<string> ({ "a" });
    assert (list != null);
}

void testBasicRead () {
    ImmutableList<string> list = ImmutableList.of<string> ({ "a", "b", "c" });

    assert (list.size () == 3);
    var first = list.get (0);
    assert (first.isOk ());
    assert (first.unwrap () == "a");

    var second = list.get (1);
    assert (second.isOk ());
    assert (second.unwrap () == "b");

    var third = list.get (2);
    assert (third.isOk ());
    assert (third.unwrap () == "c");
}

void testContainsAndEmpty () {
    ImmutableList<string> list = new ImmutableList<string> ({ "1", "3", "5" }, GLib.str_equal);

    assert (list.isEmpty () == false);
    assert (list.contains ("3") == true);
    assert (list.contains ("2") == false);

    ImmutableList<string> empty = new ImmutableList<string> ({});

    assert (empty.isEmpty () == true);
    assert (empty.size () == 0);
}

void testToArrayReturnsCopy () {
    string[] source = { "x", "y" };
    ImmutableList<string> list = new ImmutableList<string> (source);

    source[0] = "changed";
    var first = list.get (0);
    assert (first.isOk ());
    assert (first.unwrap () == "x");

    string[] copy = list.toArray ();
    copy[1] = "changed";
    var second = list.get (1);
    assert (second.isOk ());
    assert (second.unwrap () == "y");
}

void testGetOutOfBounds () {
    ImmutableList<string> list = ImmutableList.of<string> ({ "a" });
    var outOfBounds = list.get (1);
    assert (outOfBounds.isError ());
    assert (outOfBounds.unwrapError () is ImmutableListError.INDEX_OUT_OF_BOUNDS);
    assert (outOfBounds.unwrapError ().message == "index out of bounds: 1");
}
