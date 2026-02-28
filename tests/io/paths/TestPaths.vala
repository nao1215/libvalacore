using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testConstructor", testConstructor);
    Test.add_func ("/testToString", testToString);
    Test.add_func ("/testBasename", testBasename);
    Test.add_func ("/testDirname", testDirname);
    Test.add_func ("/testExtension", testExtension);
    Test.add_func ("/testWithoutExtension", testWithoutExtension);
    Test.add_func ("/testIsAbsolute", testIsAbsolute);
    Test.add_func ("/testParent", testParent);
    Test.add_func ("/testResolve", testResolve);
    Test.add_func ("/testJoin", testJoin);
    Test.add_func ("/testEquals", testEquals);
    Test.add_func ("/testStartsWith", testStartsWith);
    Test.add_func ("/testEndsWith", testEndsWith);
    Test.add_func ("/testComponents", testComponents);
    Test.add_func ("/testNormalize", testNormalize);
    Test.add_func ("/testAbs", testAbs);
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

void testExtension () {
    var txt = new Vala.Io.Path ("/tmp/file.txt");
    assert (txt.extension () == ".txt");

    var tar = new Vala.Io.Path ("archive.tar.gz");
    assert (tar.extension () == ".gz");

    var noExt = new Vala.Io.Path ("/tmp/Makefile");
    assert (noExt.extension () == "");

    var dot = new Vala.Io.Path (".");
    assert (dot.extension () == "");

    var dotdot = new Vala.Io.Path ("..");
    assert (dotdot.extension () == "");

    var hidden = new Vala.Io.Path ("/home/.bashrc");
    assert (hidden.extension () == "");

    var hiddenExt = new Vala.Io.Path ("/home/.config.bak");
    assert (hiddenExt.extension () == ".bak");
}

void testWithoutExtension () {
    var txt = new Vala.Io.Path ("/tmp/file.txt");
    assert (txt.withoutExtension () == "/tmp/file");

    var tar = new Vala.Io.Path ("archive.tar.gz");
    assert (tar.withoutExtension () == "archive.tar");

    var noExt = new Vala.Io.Path ("/tmp/Makefile");
    assert (noExt.withoutExtension () == "/tmp/Makefile");

    var hidden = new Vala.Io.Path ("/home/.bashrc");
    assert (hidden.withoutExtension () == "/home/.bashrc");
}

void testIsAbsolute () {
    assert (new Vala.Io.Path ("/usr/bin").isAbsolute () == true);
    assert (new Vala.Io.Path ("/").isAbsolute () == true);
    assert (new Vala.Io.Path ("relative/path").isAbsolute () == false);
    assert (new Vala.Io.Path ("file.txt").isAbsolute () == false);
    assert (new Vala.Io.Path ("").isAbsolute () == false);
}

void testParent () {
    var path = new Vala.Io.Path ("/tmp/file.txt");
    assert (path.parent ().toString () == "/tmp");

    var deep = new Vala.Io.Path ("/a/b/c/d");
    assert (deep.parent ().toString () == "/a/b/c");

    var root = new Vala.Io.Path ("/");
    assert (root.parent ().toString () == "/");

    var single = new Vala.Io.Path ("file.txt");
    assert (single.parent ().toString () == ".");
}

void testResolve () {
    var base_path = new Vala.Io.Path ("/home/user");
    assert (base_path.resolve ("docs").toString () == "/home/user/docs");

    /* Absolute path replaces base */
    assert (base_path.resolve ("/etc/config").toString () == "/etc/config");

    /* Trailing slash */
    var trailing = new Vala.Io.Path ("/home/user/");
    assert (trailing.resolve ("docs").toString () == "/home/user/docs");
}

void testJoin () {
    var root = new Vala.Io.Path ("/home");
    assert (root.join ("user", "docs").toString () == "/home/user/docs");

    var single = new Vala.Io.Path ("/tmp");
    assert (single.join ("file.txt").toString () == "/tmp/file.txt");

    /* Trailing slash */
    var trailing = new Vala.Io.Path ("/home/");
    assert (trailing.join ("user").toString () == "/home/user");
}

void testEquals () {
    var a = new Vala.Io.Path ("/tmp/file.txt");
    var b = new Vala.Io.Path ("/tmp/file.txt");
    assert (a.equals (b) == true);

    var c = new Vala.Io.Path ("/tmp/other.txt");
    assert (a.equals (c) == false);
}

void testStartsWith () {
    var path = new Vala.Io.Path ("/home/user/docs");
    assert (path.startsWith ("/home") == true);
    assert (path.startsWith ("/etc") == false);
    assert (path.startsWith ("") == true);
}

void testEndsWith () {
    var path = new Vala.Io.Path ("/tmp/file.txt");
    assert (path.endsWith (".txt") == true);
    assert (path.endsWith (".log") == false);
    assert (path.endsWith ("") == true);
}

void testComponents () {
    var path = new Vala.Io.Path ("/home/user/docs");
    var parts = path.components ();
    assert (parts.length () == 3);
    assert (parts.nth_data (0) == "home");
    assert (parts.nth_data (1) == "user");
    assert (parts.nth_data (2) == "docs");

    var root = new Vala.Io.Path ("/");
    assert (root.components ().length () == 0);

    var relative = new Vala.Io.Path ("a/b/c");
    assert (relative.components ().length () == 3);

    var empty = new Vala.Io.Path ("");
    assert (empty.components ().length () == 0);
}

void testNormalize () {
    var dotdot = new Vala.Io.Path ("/home/user/../admin/./docs");
    assert (dotdot.normalize ().toString () == "/home/admin/docs");

    var simple = new Vala.Io.Path ("/tmp/file.txt");
    assert (simple.normalize ().toString () == "/tmp/file.txt");

    var dots = new Vala.Io.Path ("/a/b/./c/../d");
    assert (dots.normalize ().toString () == "/a/b/d");

    var root = new Vala.Io.Path ("/");
    assert (root.normalize ().toString () == "/");

    var relative = new Vala.Io.Path ("a/b/../c");
    assert (relative.normalize ().toString () == "a/c");

    var empty = new Vala.Io.Path ("");
    assert (empty.normalize ().toString () == "");

    var onlyDots = new Vala.Io.Path (".");
    assert (onlyDots.normalize ().toString () == ".");
}

void testAbs () {
    /* Absolute path stays absolute */
    var abs = new Vala.Io.Path ("/tmp/file.txt");
    assert (abs.abs ().toString () == "/tmp/file.txt");

    /* Relative path gets resolved against cwd */
    var rel = new Vala.Io.Path ("file.txt");
    var result = rel.abs ();
    assert (result.toString ().has_prefix ("/"));
    assert (result.toString ().has_suffix ("file.txt"));

    /* Absolute with dots gets normalized */
    var dotted = new Vala.Io.Path ("/a/b/../c");
    assert (dotted.abs ().toString () == "/a/c");
}

void testPathInstantiation () {
    var path = new Vala.Io.Path ("/tmp");
    assert (path != null);
}
