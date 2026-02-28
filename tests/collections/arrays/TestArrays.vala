using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/arrays/testSort", testSort);
    Test.add_func ("/arrays/testBinarySearch", testBinarySearch);
    Test.add_func ("/arrays/testCopyOf", testCopyOf);
    Test.add_func ("/arrays/testFill", testFill);
    Test.add_func ("/arrays/testEquals", testEquals);
    Test.run ();
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

void testBinarySearch () {
    int[] arr = { 1, 3, 5, 7, 9 };

    assert (Arrays.binarySearch (arr, 1) == 0);
    assert (Arrays.binarySearch (arr, 5) == 2);
    assert (Arrays.binarySearch (arr, 9) == 4);
    assert (Arrays.binarySearch (arr, 2) == -1);
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
