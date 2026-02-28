using Vala.Lang;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/lang/randoms/testNextInt", testNextInt);
    Test.add_func ("/lang/randoms/testNextDouble", testNextDouble);
    Test.add_func ("/lang/randoms/testShuffle", testShuffle);
    Test.run ();
}

void testNextInt () {
    for (int i = 0; i < 100; i++) {
        int n = Randoms.nextInt (10);
        assert (n >= 0);
        assert (n < 10);
    }
}

void testNextDouble () {
    for (int i = 0; i < 100; i++) {
        double n = Randoms.nextDouble ();
        assert (n >= 0.0);
        assert (n < 1.0);
    }
}

void testShuffle () {
    string[] values = { "a", "b", "c", "d", "e" };
    Randoms.shuffle (values);

    assert (values.length == 5);
    int count_a = 0;
    int count_b = 0;
    int count_c = 0;
    int count_d = 0;
    int count_e = 0;
    foreach (string v in values) {
        if (v == "a") {
            count_a++;
        } else if (v == "b") {
            count_b++;
        } else if (v == "c") {
            count_c++;
        } else if (v == "d") {
            count_d++;
        } else if (v == "e") {
            count_e++;
        }
    }
    assert (count_a == 1);
    assert (count_b == 1);
    assert (count_c == 1);
    assert (count_d == 1);
    assert (count_e == 1);

    string[] one = { "x" };
    Randoms.shuffle (one);
    assert (one[0] == "x");

    string[] empty = {};
    Randoms.shuffle (empty);
    assert (empty.length == 0);
}
