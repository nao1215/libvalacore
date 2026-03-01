using Vala.Math;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/random/testNextInt", testNextInt);
    Test.add_func ("/random/testNextIntRange", testNextIntRange);
    Test.add_func ("/random/testNextDouble", testNextDouble);
    Test.add_func ("/random/testNextBool", testNextBool);
    Test.add_func ("/random/testShuffle", testShuffle);
    Test.add_func ("/random/testChoice", testChoice);
    Test.add_func ("/random/testChoiceEmpty", testChoiceEmpty);
    Test.add_func ("/random/testInvalidArguments", testInvalidArguments);
    Test.run ();
}

void testNextInt () {
    try {
        for (int i = 0; i < 100; i++) {
            int n = Vala.Math.Random.nextInt (10);
            assert (n >= 0);
            assert (n < 10);
        }
    } catch (RandomError e) {
        assert_not_reached ();
    }
}

void testNextIntRange () {
    try {
        for (int i = 0; i < 100; i++) {
            int n = Vala.Math.Random.nextIntRange (-3, 7);
            assert (n >= -3);
            assert (n < 7);
        }
    } catch (RandomError e) {
        assert_not_reached ();
    }
}

void testNextDouble () {
    for (int i = 0; i < 100; i++) {
        double d = Vala.Math.Random.nextDouble ();
        assert (d >= 0.0);
        assert (d < 1.0);
    }
}

void testNextBool () {
    bool value = Vala.Math.Random.nextBool ();
    assert (value == true || value == false);
}

void testShuffle () {
    string[] values = { "a", "b", "c", "d", "e" };
    Vala.Math.Random.shuffle<string> (values);

    int count_a = 0;
    int count_b = 0;
    int count_c = 0;
    int count_d = 0;
    int count_e = 0;
    for (int i = 0; i < values.length; i++) {
        if (values[i] == "a") {
            count_a++;
        } else if (values[i] == "b") {
            count_b++;
        } else if (values[i] == "c") {
            count_c++;
        } else if (values[i] == "d") {
            count_d++;
        } else if (values[i] == "e") {
            count_e++;
        }
    }

    assert (values.length == 5);
    assert (count_a == 1);
    assert (count_b == 1);
    assert (count_c == 1);
    assert (count_d == 1);
    assert (count_e == 1);
}

void testChoice () {
    string[] values = { "a", "b", "c" };
    string ? pick = Vala.Math.Random.choice<string> (values);

    assert (pick != null);
    assert (pick == "a" || pick == "b" || pick == "c");
}

void testChoiceEmpty () {
    string[] values = {};
    assert (Vala.Math.Random.choice<string> (values) == null);
}

void testInvalidArguments () {
    bool nextIntThrown = false;
    try {
        Vala.Math.Random.nextInt (0);
    } catch (RandomError e) {
        nextIntThrown = true;
        assert (e is RandomError.INVALID_ARGUMENT);
    }
    assert (nextIntThrown);

    bool rangeThrown = false;
    try {
        Vala.Math.Random.nextIntRange (5, 5);
    } catch (RandomError e) {
        rangeThrown = true;
        assert (e is RandomError.INVALID_ARGUMENT);
    }
    assert (rangeThrown);
}
