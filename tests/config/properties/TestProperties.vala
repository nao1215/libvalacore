using Vala.Config;
using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/config/properties/testSetGetRemove", testSetGetRemove);
    Test.add_func ("/config/properties/testSaveLoad", testSaveLoad);
    Test.add_func ("/config/properties/testLoadWithComments", testLoadWithComments);
    Test.run ();
}

void testSetGetRemove () {
    Properties props = new Properties ();
    props.set ("name", "libvalacore");
    props.set ("version", "0.1.0");

    assert (props.get ("name") == "libvalacore");
    assert (props.getOrDefault ("missing", "default") == "default");
    assert (props.size () == 2);
    assert (props.remove ("version") == true);
    assert (props.size () == 1);
}

void testSaveLoad () {
    Vala.Io.Path ? tmp = Files.tempFile ("props", ".txt");
    assert (tmp != null);

    try {
        Properties props = new Properties ();
        props.set ("k1", "v1");
        props.set ("k2", "v2");
        assert (props.save (tmp) == true);

        Properties loaded = new Properties ();
        assert (loaded.load (tmp) == true);
        assert (loaded.get ("k1") == "v1");
        assert (loaded.get ("k2") == "v2");
        assert (loaded.size () == 2);
    } finally {
        if (tmp != null) {
            Files.remove (tmp);
        }
    }
}

void testLoadWithComments () {
    Vala.Io.Path ? tmp = Files.tempFile ("props-comment", ".txt");
    assert (tmp != null);

    try {
        string text = "# comment\n\nfoo = bar\ninvalid-line\nz=9\n";
        assert (Files.writeText (tmp, text) == true);

        Properties props = new Properties ();
        assert (props.load (tmp) == true);
        assert (props.size () == 2);
        assert (props.get ("foo") == "bar");
        assert (props.get ("z") == "9");
    } finally {
        if (tmp != null) {
            Files.remove (tmp);
        }
    }
}
