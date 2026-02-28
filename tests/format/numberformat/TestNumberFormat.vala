using Vala.Format;
using Vala.Time;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/format/numberformat/testFormatInt", testFormatInt);
    Test.add_func ("/format/numberformat/testFormatDouble", testFormatDouble);
    Test.add_func ("/format/numberformat/testFormatPercentCurrency", testFormatPercentCurrency);
    Test.add_func ("/format/numberformat/testFormatBytes", testFormatBytes);
    Test.add_func ("/format/numberformat/testFormatDuration", testFormatDuration);
    Test.add_func ("/format/numberformat/testOrdinal", testOrdinal);
    Test.run ();
}

void testFormatInt () {
    assert (NumberFormat.formatInt (0) == "0");
    assert (NumberFormat.formatInt (1234567) == "1,234,567");
    assert (NumberFormat.formatInt (-12345) == "-12,345");
}

void testFormatDouble () {
    assert (NumberFormat.formatDouble (12345.678, 2) == "12,345.68");
    assert (NumberFormat.formatDouble (-1234.0, 0) == "-1,234");
    assert (NumberFormat.formatDouble (12.3, -1) == "12");
}

void testFormatPercentCurrency () {
    assert (NumberFormat.formatPercent (0.256) == "25.60%");
    assert (NumberFormat.formatCurrency (1234.5, "$") == "$1,234.50");
    assert (NumberFormat.formatCurrency (-12.3, "$") == "-$12.30");
}

void testFormatBytes () {
    assert (NumberFormat.formatBytes (999) == "999 B");
    assert (NumberFormat.formatBytes (1024) == "1 KB");
    assert (NumberFormat.formatBytes (1536) == "1.5 KB");
    assert (NumberFormat.formatBytes (1024 * 1024) == "1 MB");
    assert (NumberFormat.formatBytes (int64.MIN) == "-8 EB");
}

void testFormatDuration () {
    assert (NumberFormat.formatDuration (Duration.ofSeconds (3661)) == "1h1m1s");
}

void testOrdinal () {
    assert (NumberFormat.ordinal (1) == "1st");
    assert (NumberFormat.ordinal (2) == "2nd");
    assert (NumberFormat.ordinal (3) == "3rd");
    assert (NumberFormat.ordinal (4) == "4th");
    assert (NumberFormat.ordinal (11) == "11th");
    assert (NumberFormat.ordinal (12) == "12th");
    assert (NumberFormat.ordinal (13) == "13th");
    assert (NumberFormat.ordinal (21) == "21st");
    assert (NumberFormat.ordinal (int.MIN) == "-2147483648th");
}
