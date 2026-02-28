using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testConstructor", testConstructor);
    Test.add_func ("/testToString", testToString);
    Test.add_func ("/testBasename", testBasename);
    Test.add_func ("/testDirname", testDirname);
    Test.add_func ("/testPathInstantiation", testPathInstantiation);
    Test.run ();
}

void testConstructor () {
    var path = new Vala.Io.Path ("/tmp/file.txt");
    assert (path.toString () == "/tmp/file.txt");
}

void testToString () {
    var path = new Vala.Io.Path ("/usr/local/bin");
    assert (path.toString () == "/usr/local/bin");

    var empty = new Vala.Io.Path ("");
    assert (empty.toString () == "");
}

void testBasename () {
    var path = new Vala.Io.Path ("/tmp/file.txt");
    assert (path.basename () == "file.txt");

    var dir = new Vala.Io.Path ("/usr/local/bin");
    assert (dir.basename () == "bin");

    var root = new Vala.Io.Path ("/");
    assert (root.basename () == "/");

    var single = new Vala.Io.Path ("file.txt");
    assert (single.basename () == "file.txt");
}

void testDirname () {
    var path = new Vala.Io.Path ("/tmp/file.txt");
    assert (path.dirname ("/tmp/file.txt") == "/tmp");

    assert (path.dirname ("/usr/local/bin") == "/usr/local");

    assert (path.dirname ("file.txt") == ".");

    assert (path.dirname ("/") == "/");

    /* Empty string returns "" */
    assert (path.dirname ("") == "");

    /* Single filename returns current directory */
    assert (path.dirname ("single") == ".");
}

void testPathInstantiation () {
    var path = new Vala.Io.Path ("/tmp");
    assert (path != null);
}
