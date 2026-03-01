using Vala.Archive;
using Vala.Collections;
using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/archive/zip/testCreateAndExtract", testCreateAndExtract);
    Test.add_func ("/archive/zip/testCreateFromDirAndList", testCreateFromDirAndList);
    Test.add_func ("/archive/zip/testAddFile", testAddFile);
    Test.add_func ("/archive/zip/testExtractFile", testExtractFile);
    Test.add_func ("/archive/zip/testInvalidInputs", testInvalidInputs);
    Test.run ();
}

bool hasZipTools () {
    return GLib.Environment.find_program_in_path ("zip") != null
           && GLib.Environment.find_program_in_path ("unzip") != null;
}

string rootFor (string name) {
    return "%s/valacore/ut/zip_%s_%s".printf (Environment.get_tmp_dir (), name, GLib.Uuid.string_random ());
}

void cleanup (string path) {
    FileTree.deleteTree (new Vala.Io.Path (path));
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
    if (!hasZipTools ()) {
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

    var archive = new Vala.Io.Path (root + "/files.zip");
    var files = new ArrayList<Vala.Io.Path> ();
    files.add (a);
    files.add (b);

    assert (Zip.create (archive, files));
    assert (Zip.extract (archive, new Vala.Io.Path (root + "/out")));

    assert (Files.readAllText (new Vala.Io.Path (root + "/out/a.txt")) == "alpha");
    assert (Files.readAllText (new Vala.Io.Path (root + "/out/b.txt")) == "beta");
    cleanup (root);
}

void testCreateFromDirAndList () {
    if (!hasZipTools ()) {
        return;
    }

    string root = rootFor ("from_dir");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/tree/sub")));
    assert (Files.writeText (new Vala.Io.Path (root + "/tree/root.txt"), "r"));
    assert (Files.writeText (new Vala.Io.Path (root + "/tree/sub/nested.txt"), "n"));

    var archive = new Vala.Io.Path (root + "/tree.zip");
    assert (Zip.createFromDir (archive, new Vala.Io.Path (root + "/tree")));

    ArrayList<string> ? entries = Zip.list (archive);
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
    if (!hasZipTools ()) {
        return;
    }

    string root = rootFor ("add_file");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/base")));
    assert (Files.writeText (new Vala.Io.Path (root + "/base/one.txt"), "one"));

    var archive = new Vala.Io.Path (root + "/base.zip");
    assert (Zip.createFromDir (archive, new Vala.Io.Path (root + "/base")));

    var add = new Vala.Io.Path (root + "/add.txt");
    assert (Files.writeText (add, "add"));
    assert (Zip.addFile (archive, add));

    ArrayList<string> ? entries = Zip.list (archive);
    assert (entries != null);
    if (entries == null) {
        cleanup (root);
        return;
    }
    assert (containsSuffix (entries, "add.txt"));
    cleanup (root);
}

void testExtractFile () {
    if (!hasZipTools ()) {
        return;
    }

    string root = rootFor ("extract_file");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/tree/sub")));
    assert (Files.writeText (new Vala.Io.Path (root + "/tree/sub/nested.txt"), "target"));

    var archive = new Vala.Io.Path (root + "/tree.zip");
    assert (Zip.createFromDir (archive, new Vala.Io.Path (root + "/tree")));

    ArrayList<string> ? entries = Zip.list (archive);
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
    assert (Zip.extractFile (archive, entry, outputPath));
    assert (Files.readAllText (outputPath) == "target");
    cleanup (root);
}

void testInvalidInputs () {
    if (!hasZipTools ()) {
        return;
    }

    string root = rootFor ("invalid");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var empty = new ArrayList<Vala.Io.Path> ();
    assert (!Zip.create (new Vala.Io.Path (root + "/x.zip"), empty));
    assert (Zip.list (new Vala.Io.Path (root + "/missing.zip")) == null);
    assert (!Zip.extract (
                new Vala.Io.Path (root + "/missing.zip"),
                new Vala.Io.Path (root + "/out")
    ));
    cleanup (root);
}
