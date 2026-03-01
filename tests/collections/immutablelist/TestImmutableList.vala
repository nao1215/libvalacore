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
    try {
        assert (list.get (0) == "a");
        assert (list.get (1) == "b");
        assert (list.get (2) == "c");
    } catch (ImmutableListError e) {
        assert_not_reached ();
    }
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
    try {
        assert (list.get (0) == "x");
    } catch (ImmutableListError e) {
        assert_not_reached ();
    }

    string[] copy = list.toArray ();
    copy[1] = "changed";
    try {
        assert (list.get (1) == "y");
    } catch (ImmutableListError e) {
        assert_not_reached ();
    }
}

void testGetOutOfBounds () {
    ImmutableList<string> list = ImmutableList.of<string> ({ "a" });
    bool thrown = false;
    try {
        list.get (1);
    } catch (ImmutableListError e) {
        thrown = true;
        assert (e is ImmutableListError.INDEX_OUT_OF_BOUNDS);
    }
    assert (thrown);
}
