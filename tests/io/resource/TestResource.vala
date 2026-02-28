using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/io/resource/testReadResource", testReadResource);
    Test.add_func ("/io/resource/testReadResourceInvalid", testReadResourceInvalid);
    Test.run ();
}

void testReadResource () {
    Vala.Io.Path ? tmp = Files.tempFile ("resource", ".txt");
    assert (tmp != null);

    try {
        assert (Files.writeBytes (tmp, { 'a', 'b', 'c' }) == true);
        uint8[] ? data = Vala.Io.Resource.readResource (tmp.toString ());
        assert (data != null);
        assert (data.length == 3);
        assert (data[0] == 'a');
        assert (data[1] == 'b');
        assert (data[2] == 'c');
    } finally {
        if (tmp != null) {
            Files.remove (tmp);
        }
    }
}

void testReadResourceInvalid () {
    assert (Vala.Io.Resource.readResource ("") == null);
    assert (Vala.Io.Resource.readResource ("/path/that/does/not/exist") == null);
}
