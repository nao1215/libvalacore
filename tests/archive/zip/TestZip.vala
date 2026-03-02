using Vala.Archive;
using Vala.Collections;
using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/archive/zip/testCreateAndExtract", testCreateAndExtract);
    Test.add_func ("/archive/zip/testCreateFromDirAndList", testCreateFromDirAndList);
    Test.add_func ("/archive/zip/testAddFile", testAddFile);
    Test.add_func ("/archive/zip/testExtractFile", testExtractFile);
    Test.add_func ("/archive/zip/testExtractFileFailureKeepsDestination",
                   testExtractFileFailureKeepsDestination);
    Test.add_func ("/archive/zip/testCreateRejectsDuplicateBasename", testCreateRejectsDuplicateBasename);
    Test.add_func ("/archive/zip/testExtractRejectsTraversalEntries", testExtractRejectsTraversalEntries);
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

void assertOk (Result<bool, GLib.Error> result) {
    assert (result.isOk ());
    assert (result.unwrap ());
}

ArrayList<string> unwrapEntries (Result<ArrayList<string>, GLib.Error> result) {
    assert (result.isOk ());
    return result.unwrap ();
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

    assertOk (Zip.create (archive, files));
    assertOk (Zip.extract (archive, new Vala.Io.Path (root + "/out")));

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
    assertOk (Zip.createFromDir (archive, new Vala.Io.Path (root + "/tree")));

    ArrayList<string> entries = unwrapEntries (Zip.list (archive));

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
    assertOk (Zip.createFromDir (archive, new Vala.Io.Path (root + "/base")));

    var add = new Vala.Io.Path (root + "/add.txt");
    assert (Files.writeText (add, "add"));
    assertOk (Zip.addFile (archive, add));

    ArrayList<string> entries = unwrapEntries (Zip.list (archive));
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
    assertOk (Zip.createFromDir (archive, new Vala.Io.Path (root + "/tree")));

    ArrayList<string> entries = unwrapEntries (Zip.list (archive));

    string ? entry = findBySuffix (entries, "sub/nested.txt");
    assert (entry != null);
    if (entry == null) {
        cleanup (root);
        return;
    }

    var outputPath = new Vala.Io.Path (root + "/single.txt");
    assertOk (Zip.extractFile (archive, entry, outputPath));
    assert (Files.readAllText (outputPath) == "target");
    cleanup (root);
}

void testExtractFileFailureKeepsDestination () {
    if (!hasZipTools ()) {
        return;
    }

    string root = rootFor ("extract_file_fail_keep");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/tree")));
    assert (Files.writeText (new Vala.Io.Path (root + "/tree/ok.txt"), "ok"));

    var archive = new Vala.Io.Path (root + "/tree.zip");
    assertOk (Zip.createFromDir (archive, new Vala.Io.Path (root + "/tree")));

    var outputPath = new Vala.Io.Path (root + "/single.txt");
    assert (Files.writeText (outputPath, "keep"));
    var extracted = Zip.extractFile (archive, "missing-entry.txt", outputPath);
    assert (extracted.isError ());
    assert (extracted.unwrapError () is ZipError.NOT_FOUND);
    assert (Files.readAllText (outputPath) == "keep");
    cleanup (root);
}

void testCreateRejectsDuplicateBasename () {
    if (!hasZipTools ()) {
        return;
    }

    string root = rootFor ("duplicate_basename");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/a")));
    assert (Files.makeDirs (new Vala.Io.Path (root + "/b")));
    assert (Files.writeText (new Vala.Io.Path (root + "/a/name.txt"), "one"));
    assert (Files.writeText (new Vala.Io.Path (root + "/b/name.txt"), "two"));

    var files = new ArrayList<Vala.Io.Path> ();
    files.add (new Vala.Io.Path (root + "/a/name.txt"));
    files.add (new Vala.Io.Path (root + "/b/name.txt"));
    var created = Zip.create (new Vala.Io.Path (root + "/dup.zip"), files);
    assert (created.isError ());
    assert (created.unwrapError () is ZipError.INVALID_ARGUMENT);
    cleanup (root);
}

void testExtractRejectsTraversalEntries () {
    if (!hasZipTools ()) {
        return;
    }

    string root = rootFor ("reject_traversal");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/work")));
    assert (Files.writeText (new Vala.Io.Path (root + "/outside.txt"), "outside"));

    try {
        var launcher = new GLib.SubprocessLauncher (GLib.SubprocessFlags.NONE);
        launcher.set_cwd (root + "/work");
        string[] argv = { "zip", "-q", "evil.zip", "../outside.txt", null };
        var process = launcher.spawnv (argv);
        assert (process.wait_check (null));
    } catch (GLib.Error e) {
        assert_not_reached ();
    }

    var extracted = Zip.extract (
        new Vala.Io.Path (root + "/work/evil.zip"),
        new Vala.Io.Path (root + "/out")
    );
    assert (extracted.isError ());
    assert (extracted.unwrapError () is ZipError.SECURITY);
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
    var emptyCreate = Zip.create (new Vala.Io.Path (root + "/x.zip"), empty);
    assert (emptyCreate.isError ());
    assert (emptyCreate.unwrapError () is ZipError.INVALID_ARGUMENT);

    var noRegularFiles = new ArrayList<Vala.Io.Path> ();
    noRegularFiles.add (new Vala.Io.Path (root + "/missing.txt"));
    var missingCreate = Zip.create (new Vala.Io.Path (root + "/y.zip"), noRegularFiles);
    assert (missingCreate.isError ());
    assert (missingCreate.unwrapError () is ZipError.NOT_FOUND);

    var fromDir = Zip.createFromDir (new Vala.Io.Path (root + "/from-dir.zip"), new Vala.Io.Path (root + "/missing-dir"));
    assert (fromDir.isError ());
    assert (fromDir.unwrapError () is ZipError.INVALID_ARGUMENT);

    var listed = Zip.list (new Vala.Io.Path (root + "/missing.zip"));
    assert (listed.isError ());
    assert (listed.unwrapError () is ZipError.NOT_FOUND);

    var extracted = Zip.extract (new Vala.Io.Path (root + "/missing.zip"), new Vala.Io.Path (root + "/out"));
    assert (extracted.isError ());
    assert (extracted.unwrapError () is ZipError.NOT_FOUND);

    var added = Zip.addFile (new Vala.Io.Path (root + "/missing.zip"), new Vala.Io.Path (root + "/missing.txt"));
    assert (added.isError ());
    assert (added.unwrapError () is ZipError.NOT_FOUND);

    assert (Files.makeDirs (new Vala.Io.Path (root + "/base")));
    assert (Files.writeText (new Vala.Io.Path (root + "/base/one.txt"), "one"));
    var archive = new Vala.Io.Path (root + "/base.zip");
    assertOk (Zip.createFromDir (archive, new Vala.Io.Path (root + "/base")));
    var addMissingFile = Zip.addFile (archive, new Vala.Io.Path (root + "/missing-file.txt"));
    assert (addMissingFile.isError ());
    assert (addMissingFile.unwrapError () is ZipError.NOT_FOUND);

    var extractedFile = Zip.extractFile (
        new Vala.Io.Path (root + "/missing.zip"),
        "entry.txt",
        new Vala.Io.Path (root + "/entry.txt")
    );
    assert (extractedFile.isError ());
    assert (extractedFile.unwrapError () is ZipError.NOT_FOUND);
    cleanup (root);
}
