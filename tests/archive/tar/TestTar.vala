using Vala.Archive;
using Vala.Collections;
using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/archive/tar/testCreateAndExtract", testCreateAndExtract);
    Test.add_func ("/archive/tar/testCreateFromDirAndList", testCreateFromDirAndList);
    Test.add_func ("/archive/tar/testAddFile", testAddFile);
    Test.add_func ("/archive/tar/testExtractFile", testExtractFile);
    Test.add_func ("/archive/tar/testInvalidInputs", testInvalidInputs);
    Test.run ();
}

bool hasTarTool () {
    return Vala.Io.Process.exec ("sh", { "-c", "command -v tar >/dev/null 2>&1" });
}

string rootFor (string name) {
    return "/tmp/valacore/ut/tar_" + name;
}

void cleanup (string path) {
    Posix.system ("rm -rf " + path);
}

bool containsSuffix (ArrayList<string> entries, string suffix) {
    for (int i = 0; i < entries.size (); i++) {
        string ? entry = entries.get (i);
        if (entry != null && entry.has_suffix (suffix)) {
            return true;
        }
    }
    return false;
}

string ? findBySuffix (ArrayList<string> entries, string suffix) {
    for (int i = 0; i < entries.size (); i++) {
        string ? entry = entries.get (i);
        if (entry != null && entry.has_suffix (suffix)) {
            return entry;
        }
    }
    return null;
}

void testCreateAndExtract () {
    if (!hasTarTool ()) {
        return;
    }

    string root = rootFor ("create_extract");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/src")));
    assert (Files.makeDirs (new Vala.Io.Path (root + "/out")));

    var a = new Vala.Io.Path (root + "/src/a.txt");
    var b = new Vala.Io.Path (root + "/src/b.txt");
    assert (Files.writeText (a, "alpha"));
    assert (Files.writeText (b, "beta"));

    var archive = new Vala.Io.Path (root + "/files.tar");
    var files = new ArrayList<Vala.Io.Path> ();
    files.add (a);
    files.add (b);

    assert (Tar.create (archive, files));
    assert (Tar.extract (archive, new Vala.Io.Path (root + "/out")));
    assert (Files.readAllText (new Vala.Io.Path (root + "/out/a.txt")) == "alpha");
    assert (Files.readAllText (new Vala.Io.Path (root + "/out/b.txt")) == "beta");
    cleanup (root);
}

void testCreateFromDirAndList () {
    if (!hasTarTool ()) {
        return;
    }

    string root = rootFor ("from_dir");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/tree/sub")));
    assert (Files.writeText (new Vala.Io.Path (root + "/tree/root.txt"), "r"));
    assert (Files.writeText (new Vala.Io.Path (root + "/tree/sub/nested.txt"), "n"));

    var archive = new Vala.Io.Path (root + "/tree.tar");
    assert (Tar.createFromDir (archive, new Vala.Io.Path (root + "/tree")));

    ArrayList<string> ? entries = Tar.list (archive);
    assert (entries != null);
    if (entries == null) {
        cleanup (root);
        return;
    }
    assert (containsSuffix (entries, "root.txt"));
    assert (containsSuffix (entries, "sub/nested.txt"));
    cleanup (root);
}

void testAddFile () {
    if (!hasTarTool ()) {
        return;
    }

    string root = rootFor ("add_file");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/base")));
    assert (Files.writeText (new Vala.Io.Path (root + "/base/one.txt"), "one"));

    var archive = new Vala.Io.Path (root + "/base.tar");
    assert (Tar.createFromDir (archive, new Vala.Io.Path (root + "/base")));

    var add = new Vala.Io.Path (root + "/add.txt");
    assert (Files.writeText (add, "add"));
    assert (Tar.addFile (archive, add));

    ArrayList<string> ? entries = Tar.list (archive);
    assert (entries != null);
    if (entries == null) {
        cleanup (root);
        return;
    }
    assert (containsSuffix (entries, "add.txt"));
    cleanup (root);
}

void testExtractFile () {
    if (!hasTarTool ()) {
        return;
    }

    string root = rootFor ("extract_file");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/tree/sub")));
    assert (Files.writeText (new Vala.Io.Path (root + "/tree/sub/nested.txt"), "target"));

    var archive = new Vala.Io.Path (root + "/tree.tar");
    assert (Tar.createFromDir (archive, new Vala.Io.Path (root + "/tree")));

    ArrayList<string> ? entries = Tar.list (archive);
    assert (entries != null);
    if (entries == null) {
        cleanup (root);
        return;
    }

    string ? entry = findBySuffix (entries, "sub/nested.txt");
    assert (entry != null);
    if (entry == null) {
        cleanup (root);
        return;
    }

    var outputPath = new Vala.Io.Path (root + "/single.txt");
    assert (Tar.extractFile (archive, entry, outputPath));
    assert (Files.readAllText (outputPath) == "target");
    cleanup (root);
}

void testInvalidInputs () {
    if (!hasTarTool ()) {
        return;
    }

    string root = rootFor ("invalid");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var empty = new ArrayList<Vala.Io.Path> ();
    assert (!Tar.create (new Vala.Io.Path (root + "/x.tar"), empty));
    assert (Tar.list (new Vala.Io.Path (root + "/missing.tar")) == null);
    assert (!Tar.extract (
                new Vala.Io.Path (root + "/missing.tar"),
                new Vala.Io.Path (root + "/out")
    ));
    cleanup (root);
}
