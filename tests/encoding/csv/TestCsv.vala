using Vala.Collections;
using Vala.Encoding;
using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/csv/testConstruct", testConstruct);
    Test.add_func ("/csv/testParse", testParse);
    Test.add_func ("/csv/testParseQuoted", testParseQuoted);
    Test.add_func ("/csv/testParseInvalid", testParseInvalid);
    Test.add_func ("/csv/testParseFile", testParseFile);
    Test.add_func ("/csv/testWrite", testWrite);
    Test.add_func ("/csv/testRoundTrip", testRoundTrip);
    Test.run ();
}

void testConstruct () {
    Csv csv = new Csv ();
    assert (csv != null);
}

void testParse () {
    ArrayList<ArrayList<string> > rows = Csv.parse ("name,age\nalice,20");
    assert (rows.size () == 2);

    ArrayList<string> ? header = rows.get (0);
    ArrayList<string> ? body = rows.get (1);
    assert (header != null);
    assert (body != null);

    assert (header.size () == 2);
    assert (header.get (0) == "name");
    assert (header.get (1) == "age");
    assert (body.get (0) == "alice");
    assert (body.get (1) == "20");
}

void testParseQuoted () {
    ArrayList<ArrayList<string> > rows = Csv.parse ("a,\"b,c\",\"d\"\"e\",\"line1\nline2\"");
    assert (rows.size () == 1);

    ArrayList<string> ? row = rows.get (0);
    assert (row != null);
    assert (row.size () == 4);
    assert (row.get (0) == "a");
    assert (row.get (1) == "b,c");
    assert (row.get (2) == "d\"e");
    assert (row.get (3) == "line1\nline2");
}

void testParseInvalid () {
    ArrayList<ArrayList<string> > rows = Csv.parse ("\"unclosed");
    assert (rows.size () == 0);
}

void testParseFile () {
    Vala.Io.Path ? tmp = Files.tempFile ("csv", ".txt");
    assert (tmp != null);

    try {
        assert (Files.writeText (tmp, "x,y\n1,2"));
        ArrayList<ArrayList<string> > rows = Csv.parseFile (tmp);
        assert (rows.size () == 2);

        ArrayList<string> ? row0 = rows.get (0);
        ArrayList<string> ? row1 = rows.get (1);
        assert (row0 != null);
        assert (row1 != null);
        assert (row0.get (0) == "x");
        assert (row1.get (1) == "2");
    } finally {
        if (tmp != null) {
            Files.remove (tmp);
        }
    }
}

void testWrite () {
    ArrayList<ArrayList<string> > rows = new ArrayList<ArrayList<string> > ();

    var row1 = new ArrayList<string> (GLib.str_equal);
    row1.add ("a");
    row1.add ("b,c");
    row1.add ("d\"e");
    rows.add (row1);

    var row2 = new ArrayList<string> (GLib.str_equal);
    row2.add ("1");
    row2.add ("2");
    row2.add ("3");
    rows.add (row2);

    string csv = Csv.write (rows, ",");
    assert (csv == "a,\"b,c\",\"d\"\"e\"\n1,2,3");
}

void testRoundTrip () {
    ArrayList<ArrayList<string> > rows = new ArrayList<ArrayList<string> > ();

    var row1 = new ArrayList<string> (GLib.str_equal);
    row1.add ("hello");
    row1.add ("a,b");
    row1.add ("line1\nline2");
    rows.add (row1);

    var row2 = new ArrayList<string> (GLib.str_equal);
    row2.add ("");
    row2.add ("plain");
    row2.add ("\"q\"");
    rows.add (row2);

    string csv = Csv.write (rows, ",");
    ArrayList<ArrayList<string> > parsed = Csv.parse (csv);

    assert (parsed.size () == rows.size ());
    for (int i = 0; i < (int) rows.size (); i++) {
        ArrayList<string> ? expected = rows.get (i);
        ArrayList<string> ? actual = parsed.get (i);
        assert (expected != null);
        assert (actual != null);
        assert (actual.size () == expected.size ());

        for (int j = 0; j < (int) expected.size (); j++) {
            assert (actual.get (j) == expected.get (j));
        }
    }
}
