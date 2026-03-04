using Vala.Config;
using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/config/properties/testSetGetRemove", testSetGetRemove);
    Test.add_func ("/config/properties/testSaveLoad", testSaveLoad);
    Test.add_func ("/config/properties/testLoadWithComments", testLoadWithComments);
    Test.add_func ("/config/properties/testSaveOrderAndEdgeCases", testSaveOrderAndEdgeCases);
    Test.add_func ("/config/properties/testLoadMissingFile", testLoadMissingFile);
    Test.add_func ("/config/properties/testSaveInvalidDestination", testSaveInvalidDestination);
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
        var saved = props.save (tmp);
        assert (saved.isOk ());
        assert (saved.unwrap () == true);

        Properties loaded = new Properties ();
        var loadResult = loaded.load (tmp);
        assert (loadResult.isOk ());
        assert (loadResult.unwrap () == true);
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
        var loadResult = props.load (tmp);
        assert (loadResult.isOk ());
        assert (loadResult.unwrap () == true);
        assert (props.size () == 2);
        assert (props.get ("foo") == "bar");
        assert (props.get ("z") == "9");
    } finally {
        if (tmp != null) {
            Files.remove (tmp);
        }
    }
}

void testSaveOrderAndEdgeCases () {
    Properties props = new Properties ();
    assert (props.get ("") == null);
    assert (props.getOrDefault ("missing", "default") == "default");
    assert (props.remove ("") == false);

    props.set ("z", "3");
    props.set ("a", "1");
    props.set ("m", "2");
    props.set ("", "ignored");
    assert (props.size () == 3);

    Vala.Io.Path ? tmp = Files.tempFile ("props-order", ".txt");
    assert (tmp != null);

    try {
        var saved = props.save (tmp);
        assert (saved.isOk ());
        assert (saved.unwrap () == true);
        string ? content = Files.readAllText (tmp);
        assert (content != null);
        assert (content == "a=1\nm=2\nz=3\n");
    } finally {
        if (tmp != null) {
            Files.remove (tmp);
        }
    }
}

void testLoadMissingFile () {
    Vala.Io.Path ? dir = Files.tempDir ("props-missing");
    assert (dir != null);

    Properties props = new Properties ();
    try {
        Vala.Io.Path missing = dir.resolve ("no-such-properties-file");
        var loaded = props.load (missing);
        assert (loaded.isError ());
        assert (loaded.unwrapError () is PropertiesError.IO);
    } finally {
        if (dir != null) {
            Files.deleteRecursive (dir);
        }
    }
}

void testSaveInvalidDestination () {
    Vala.Io.Path ? dir = Files.tempDir ("props-invalid-dest");
    assert (dir != null);

    Properties props = new Properties ();
    props.set ("k", "v");

    try {
        Vala.Io.Path invalidDestination = dir.resolve ("no-such-dir").resolve ("props.txt");
        var saved = props.save (invalidDestination);
        assert (saved.isError ());
        assert (saved.unwrapError () is PropertiesError.IO);
    } finally {
        if (dir != null) {
            Files.deleteRecursive (dir);
        }
    }
}
