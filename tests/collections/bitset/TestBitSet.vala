using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/testSetAndGet", testSetAndGet);
    Test.add_func ("/testClearBit", testClearBit);
    Test.add_func ("/testFlip", testFlip);
    Test.add_func ("/testAnd", testAnd);
    Test.add_func ("/testOr", testOr);
    Test.add_func ("/testXor", testXor);
    Test.add_func ("/testCardinality", testCardinality);
    Test.add_func ("/testLength", testLength);
    Test.add_func ("/testIsEmpty", testIsEmpty);
    Test.add_func ("/testToString", testToString);
    Test.add_func ("/testClearAll", testClearAll);
    Test.add_func ("/testAutoGrow", testAutoGrow);
    Test.add_func ("/testGetOutOfRange", testGetOutOfRange);
    Test.add_func ("/testNegativeIndex", testNegativeIndex);
    Test.add_func ("/testDifferentSizes", testDifferentSizes);

    Test.run ();
}

void testSetAndGet () {
    var bits = new BitSet (8);
    assert (!bits.get (0));
    assert (!bits.get (7));

    bits.set (0);
    bits.set (3);
    bits.set (7);

    assert (bits.get (0));
    assert (!bits.get (1));
    assert (!bits.get (2));
    assert (bits.get (3));
    assert (bits.get (7));
}

void testClearBit () {
    var bits = new BitSet (8);
    bits.set (3);
    assert (bits.get (3));

    bits.clearBit (3);
    assert (!bits.get (3));

    // clear already-clear bit
    bits.clearBit (5);
    assert (!bits.get (5));
}

void testFlip () {
    var bits = new BitSet (8);
    bits.flip (3);
    assert (bits.get (3));

    bits.flip (3);
    assert (!bits.get (3));

    // flip on unset bit
    bits.flip (0);
    assert (bits.get (0));
}

void testAnd () {
    var a = new BitSet (8);
    a.set (0);
    a.set (1);
    a.set (2);

    var b = new BitSet (8);
    b.set (1);
    b.set (2);
    b.set (3);

    a.and (b);
    assert (!a.get (0));
    assert (a.get (1));
    assert (a.get (2));
    assert (!a.get (3));
}

void testOr () {
    var a = new BitSet (8);
    a.set (0);
    a.set (1);

    var b = new BitSet (8);
    b.set (1);
    b.set (2);

    a.or (b);
    assert (a.get (0));
    assert (a.get (1));
    assert (a.get (2));
}

void testXor () {
    var a = new BitSet (8);
    a.set (0);
    a.set (1);

    var b = new BitSet (8);
    b.set (1);
    b.set (2);

    a.xor (b);
    assert (a.get (0));
    assert (!a.get (1));
    assert (a.get (2));
}

void testCardinality () {
    var bits = new BitSet (16);
    assert (bits.cardinality () == 0);

    bits.set (0);
    assert (bits.cardinality () == 1);

    bits.set (3);
    bits.set (7);
    bits.set (15);
    assert (bits.cardinality () == 4);

    bits.clearBit (3);
    assert (bits.cardinality () == 3);
}

void testLength () {
    var bits = new BitSet (64);
    assert (bits.length () == 0);

    bits.set (0);
    assert (bits.length () == 1);

    bits.set (10);
    assert (bits.length () == 11);

    bits.set (63);
    assert (bits.length () == 64);

    bits.clearBit (63);
    assert (bits.length () == 11);
}

void testIsEmpty () {
    var bits = new BitSet (8);
    assert (bits.isEmpty ());

    bits.set (5);
    assert (!bits.isEmpty ());

    bits.clearBit (5);
    assert (bits.isEmpty ());
}

void testToString () {
    var bits = new BitSet (8);
    assert (bits.toString () == "{}");

    bits.set (0);
    bits.set (3);
    assert (bits.toString () == "{0, 3}");

    bits.set (7);
    assert (bits.toString () == "{0, 3, 7}");
}

void testClearAll () {
    var bits = new BitSet (16);
    bits.set (0);
    bits.set (5);
    bits.set (10);
    bits.set (15);
    assert (bits.cardinality () == 4);

    bits.clearAll ();
    assert (bits.isEmpty ());
    assert (bits.cardinality () == 0);
}

void testAutoGrow () {
    var bits = new BitSet (8);
    bits.set (100);
    assert (bits.get (100));
    assert (!bits.get (99));
    assert (bits.cardinality () == 1);
    assert (bits.length () == 101);
}

void testGetOutOfRange () {
    var bits = new BitSet (8);
    assert (!bits.get (100));
    assert (!bits.get (1000));
}

void testNegativeIndex () {
    var bits = new BitSet (8);
    // negative index operations should be no-ops
    bits.set (-1);
    assert (!bits.get (-1));
    bits.clearBit (-1);
    bits.flip (-1);
}

void testDifferentSizes () {
    // AND with different sizes
    var a = new BitSet (16);
    a.set (0);
    a.set (10);

    var b = new BitSet (8);
    b.set (0);

    a.and (b);
    assert (a.get (0));
    assert (!a.get (10));

    // OR with different sizes
    var c = new BitSet (8);
    c.set (0);

    var d = new BitSet (32);
    d.set (20);

    c.or (d);
    assert (c.get (0));
    assert (c.get (20));

    // XOR with different sizes
    var e = new BitSet (8);
    e.set (0);

    var f = new BitSet (32);
    f.set (0);
    f.set (20);

    e.xor (f);
    assert (!e.get (0));
    assert (e.get (20));
}
