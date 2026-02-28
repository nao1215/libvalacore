using Vala.Time;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/duration/testFactories", testFactories);
    Test.add_func ("/duration/testPlusMinus", testPlusMinus);
    Test.add_func ("/duration/testToString", testToString);
    Test.add_func ("/duration/testToStringNegative", testToStringNegative);
    Test.run ();
}

void testFactories () {
    assert (Duration.ofSeconds (5).toMillis () == 5000);
    assert (Duration.ofMinutes (2).toMillis () == 120000);
    assert (Duration.ofHours (3).toMillis () == 10800000);
    assert (Duration.ofDays (1).toMillis () == 86400000);
}

void testPlusMinus () {
    Duration a = Duration.ofMinutes (2);
    Duration b = Duration.ofSeconds (30);

    assert (a.plus (b).toMillis () == 150000);
    assert (a.minus (b).toMillis () == 90000);
    assert (a.minus (Duration.ofMinutes (2)).toMillis () == 0);
}

void testToString () {
    assert (Duration.ofSeconds (0).toString () == "0ms");
    assert (Duration.ofSeconds (1).toString () == "1s");
    assert (Duration.ofMinutes (150).toString () == "2h30m");
    assert (Duration.ofHours (26).toString () == "1d2h");
}

void testToStringNegative () {
    Duration negative = Duration.ofMinutes (1).minus (Duration.ofMinutes (2));
    assert (negative.toString () == "-1m");
    assert (negative.toSeconds () == -60);
}
