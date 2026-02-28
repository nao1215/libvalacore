using Vala.Time;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/datetime/testNow", testNow);
    Test.add_func ("/datetime/testOfAndFields", testOfAndFields);
    Test.add_func ("/datetime/testParseAndFormat", testParseAndFormat);
    Test.add_func ("/datetime/testParseInvalid", testParseInvalid);
    Test.add_func ("/datetime/testPlusMinus", testPlusMinus);
    Test.add_func ("/datetime/testCompare", testCompare);
    Test.add_func ("/datetime/testUnixTimestamp", testUnixTimestamp);
    Test.add_func ("/datetime/testDiff", testDiff);
    Test.run ();
}

void testNow () {
    Vala.Time.DateTime now = Vala.Time.DateTime.now ();
    assert (now.toUnixTimestamp () > 0);
}

void testOfAndFields () {
    Vala.Time.DateTime dt = Vala.Time.DateTime.of (2024, 1, 1, 12, 34, 56);

    assert (dt.year () == 2024);
    assert (dt.month () == 1);
    assert (dt.day () == 1);
    assert (dt.hour () == 12);
    assert (dt.minute () == 34);
    assert (dt.second () == 56);
    assert (dt.dayOfWeek () == 1);
}

void testParseAndFormat () {
    Vala.Time.DateTime ? dt = Vala.Time.DateTime.parse (
        "2024-05-10 08:30:45",
        "%Y-%m-%d %H:%M:%S"
    );
    assert (dt != null);
    assert (dt.format ("%Y-%m-%d %H:%M:%S") == "2024-05-10 08:30:45");

    Vala.Time.DateTime ? dt_iso = Vala.Time.DateTime.parse (
        "2024-05-10T08:30:45",
        "%Y-%m-%dT%H:%M:%S"
    );
    assert (dt_iso != null);
    assert (dt_iso.format ("%Y-%m-%dT%H:%M:%S") == "2024-05-10T08:30:45");
}

void testParseInvalid () {
    assert (Vala.Time.DateTime.parse ("2024/05/10", "%Y-%m-%d %H:%M:%S") == null);
    assert (Vala.Time.DateTime.parse ("2024-05-10", "%d/%m/%Y") == null);
}

void testPlusMinus () {
    Vala.Time.DateTime dt = Vala.Time.DateTime.of (2024, 5, 10, 8, 0, 0);

    Vala.Time.DateTime plus = dt.plusDays (2);
    assert (plus.format ("%Y-%m-%d") == "2024-05-12");

    Vala.Time.DateTime plus_h = dt.plusHours (3);
    assert (plus_h.format ("%Y-%m-%d %H:%M:%S") == "2024-05-10 11:00:00");

    Vala.Time.DateTime minus = dt.minusDays (1);
    assert (minus.format ("%Y-%m-%d") == "2024-05-09");
}

void testCompare () {
    Vala.Time.DateTime a = Vala.Time.DateTime.of (2024, 1, 1, 0, 0, 0);
    Vala.Time.DateTime b = Vala.Time.DateTime.of (2024, 1, 2, 0, 0, 0);

    assert (a.isBefore (b) == true);
    assert (b.isAfter (a) == true);
    assert (a.isAfter (b) == false);
}

void testUnixTimestamp () {
    Vala.Time.DateTime dt = Vala.Time.DateTime.of (2024, 1, 1, 0, 0, 0);
    int64 ts = dt.toUnixTimestamp ();

    Vala.Time.DateTime restored = Vala.Time.DateTime.fromUnixTimestamp (ts);
    assert (restored.toUnixTimestamp () == ts);
}

void testDiff () {
    Vala.Time.DateTime a = Vala.Time.DateTime.of (2024, 1, 1, 0, 0, 0);
    Vala.Time.DateTime b = Vala.Time.DateTime.of (2024, 1, 3, 0, 0, 0);

    assert (b.diff (a).toSeconds () == 172800);
    assert (a.diff (b).toSeconds () == -172800);
}
