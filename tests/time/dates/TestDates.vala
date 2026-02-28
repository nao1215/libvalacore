using Vala.Time;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/time/dates/testNow", testNow);
    Test.add_func ("/time/dates/testParseAndFormat", testParseAndFormat);
    Test.add_func ("/time/dates/testParseInvalid", testParseInvalid);
    Test.add_func ("/time/dates/testAddDays", testAddDays);
    Test.add_func ("/time/dates/testIsLeapYear", testIsLeapYear);
    Test.run ();
}

void testNow () {
    Vala.Time.DateTime now = Dates.now ();
    assert (now.toUnixTimestamp () > 0);
}

void testParseAndFormat () {
    Vala.Time.DateTime ? dt = Dates.parse ("2024-05-10 08:30:45", "%Y-%m-%d %H:%M:%S");
    assert (dt != null);
    assert (Dates.format (dt, "%Y-%m-%d %H:%M:%S") == "2024-05-10 08:30:45");
    assert (Dates.format (dt, "") == "");
}

void testParseInvalid () {
    assert (Dates.parse ("", "%Y-%m-%d %H:%M:%S") == null);
    assert (Dates.parse ("2024-05-10", "") == null);
    assert (Dates.parse ("2024/05/10", "%Y-%m-%d %H:%M:%S") == null);
}

void testAddDays () {
    Vala.Time.DateTime dt = Vala.Time.DateTime.of (2024, 2, 28, 0, 0, 0);
    Vala.Time.DateTime plus = Dates.addDays (dt, 1);
    Vala.Time.DateTime minus = Dates.addDays (dt, -1);

    assert (plus.format ("%Y-%m-%d") == "2024-02-29");
    assert (minus.format ("%Y-%m-%d") == "2024-02-27");
}

void testIsLeapYear () {
    assert (Dates.isLeapYear (2000) == true);
    assert (Dates.isLeapYear (1900) == false);
    assert (Dates.isLeapYear (2024) == true);
    assert (Dates.isLeapYear (2023) == false);
}
