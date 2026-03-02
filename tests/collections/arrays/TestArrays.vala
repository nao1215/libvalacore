using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/arrays/testConstruct", testConstruct);
    Test.add_func ("/arrays/testSort", testSort);
    Test.add_func ("/arrays/testSortEdgeCases", testSortEdgeCases);
    Test.add_func ("/arrays/testBinarySearch", testBinarySearch);
    Test.add_func ("/arrays/testBinarySearchEdgeCases", testBinarySearchEdgeCases);
    Test.add_func ("/arrays/testCopyOf", testCopyOf);
    Test.add_func ("/arrays/testCopyOfInvalidLength", testCopyOfInvalidLength);
    Test.add_func ("/arrays/testCopyOfZeroLength", testCopyOfZeroLength);
    Test.add_func ("/arrays/testFill", testFill);
    Test.add_func ("/arrays/testEquals", testEquals);
    Test.add_func ("/arrays/testEqualsEmpty", testEqualsEmpty);
    Test.run ();
}

void testConstruct () {
    var arrays = new Arrays ();
    assert (arrays != null);
}

void testSort () {
    int[] arr = { 5, 1, 4, 2, 3 };
    Arrays.sort (arr);

    assert (arr[0] == 1);
    assert (arr[1] == 2);
    assert (arr[2] == 3);
    assert (arr[3] == 4);
    assert (arr[4] == 5);
}

void testSortEdgeCases () {
    int[] empty = {};
    Arrays.sort (empty);
    assert (empty.length == 0);

    int[] single = { 42 };
    Arrays.sort (single);
    assert (single[0] == 42);

    int[] sorted = { 1, 2, 3, 4 };
    Arrays.sort (sorted);
    assert (sorted[0] == 1);
    assert (sorted[3] == 4);
}

void testBinarySearch () {
    int[] arr = { 1, 3, 5, 7, 9 };

    assert (Arrays.binarySearch (arr, 1) == 0);
    assert (Arrays.binarySearch (arr, 5) == 2);
    assert (Arrays.binarySearch (arr, 9) == 4);
    assert (Arrays.binarySearch (arr, 2) == -1);
}

void testBinarySearchEdgeCases () {
    int[] empty = {};
    assert (Arrays.binarySearch (empty, 1) == -1);

    int[] duplicates = { 1, 2, 2, 2, 3 };
    int idx = Arrays.binarySearch (duplicates, 2);
    assert (idx >= 1);
    assert (idx <= 3);
    assert (duplicates[idx] == 2);
}

void testCopyOf () {
    int[] arr = { 10, 20, 30 };

    int[] expanded = Arrays.copyOf (arr, 5);
    assert (expanded.length == 5);
    assert (expanded[0] == 10);
    assert (expanded[1] == 20);
    assert (expanded[2] == 30);
    assert (expanded[3] == 0);
    assert (expanded[4] == 0);

    int[] shrink = Arrays.copyOf (arr, 2);
    assert (shrink.length == 2);
    assert (shrink[0] == 10);
    assert (shrink[1] == 20);
}

void testCopyOfInvalidLength () {
    int[] arr = { 1, 2, 3 };
    int[] copied = Arrays.copyOf (arr, -1);
    assert (copied.length == 0);
}

void testCopyOfZeroLength () {
    int[] arr = { 1, 2, 3 };
    int[] copied = Arrays.copyOf (arr, 0);
    assert (copied.length == 0);
}

void testFill () {
    int[] arr = { 1, 2, 3, 4 };
    Arrays.fill (arr, 7);

    assert (arr[0] == 7);
    assert (arr[1] == 7);
    assert (arr[2] == 7);
    assert (arr[3] == 7);
}

void testEquals () {
    int[] a = { 1, 2, 3 };
    int[] b = { 1, 2, 3 };
    int[] c = { 1, 2, 4 };
    int[] d = { 1, 2 };

    assert (Arrays.equals (a, b) == true);
    assert (Arrays.equals (a, c) == false);
    assert (Arrays.equals (a, d) == false);
}

void testEqualsEmpty () {
    int[] a = {};
    int[] b = {};

    assert (Arrays.equals (a, b) == true);
}
