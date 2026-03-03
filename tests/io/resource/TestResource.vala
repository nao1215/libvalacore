using Vala.Io;
using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/io/resource/testConstruct", testConstruct);
    Test.add_func ("/io/resource/testReadResource", testReadResource);
    Test.add_func ("/io/resource/testReadResourceInvalid", testReadResourceInvalid);
    Test.run ();
}

void testConstruct () {
    var helper = new Vala.Io.Resource ();
    assert (helper != null);
}

void testReadResource () {
    Vala.Io.Path ? tmp = Files.tempFile ("resource", ".txt");
    assert (tmp != null);

    try {
        assert (Files.writeBytes (tmp, { 'a', 'b', 'c' }) == true);
        uint8[] data = unwrapBytes (Vala.Io.Resource.readResource (tmp.toString ()));
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
    Result<GLib.Bytes, GLib.Error> empty = Vala.Io.Resource.readResource ("");
    assert (empty.isError ());
    assert (empty.unwrapError () is Vala.Io.ResourceError.INVALID_ARGUMENT);

    Result<GLib.Bytes, GLib.Error> missing = Vala.Io.Resource.readResource ("/path/that/does/not/exist");
    assert (missing.isError ());
    assert (missing.unwrapError () is Vala.Io.ResourceError.NOT_FOUND);
}

uint8[] unwrapBytes (Result<GLib.Bytes, GLib.Error> result) {
    assert (result.isOk ());
    return copyBytes (result.unwrap ());
}

uint8[] copyBytes (GLib.Bytes bytes) {
    uint8[] raw = bytes.get_data ();
    uint8[] copied = new uint8[raw.length];
    for (int i = 0; i < raw.length; i++) {
        copied[i] = raw[i];
    }
    return copied;
}
