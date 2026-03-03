using Vala.Archive;
using Vala.Collections;
using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/archive/tar/testCreateAndExtract", testCreateAndExtract);
    Test.add_func ("/archive/tar/testCreateAndExtractLeadingDash", testCreateAndExtractLeadingDash);
    Test.add_func ("/archive/tar/testCreateFromDirAndList", testCreateFromDirAndList);
    Test.add_func ("/archive/tar/testAddFile", testAddFile);
    Test.add_func ("/archive/tar/testExtractFile", testExtractFile);
    Test.add_func ("/archive/tar/testExtractFileMissingEntryKeepsDestination",
                   testExtractFileMissingEntryKeepsDestination);
    Test.add_func ("/archive/tar/testExtractRejectsLinkEntries", testExtractRejectsLinkEntries);
    Test.add_func ("/archive/tar/testExtractRejectsTraversalEntries", testExtractRejectsTraversalEntries);
    Test.add_func ("/archive/tar/testListRejectsTruncatedArchive", testListRejectsTruncatedArchive);
    Test.add_func ("/archive/tar/testCreateRejectsDuplicateBasename", testCreateRejectsDuplicateBasename);
    Test.add_func ("/archive/tar/testInvalidInputs", testInvalidInputs);
    Test.run ();
}

string rootFor (string name) {
    return "%s/valacore/ut/tar_%s_%s".printf (Environment.get_tmp_dir (), name, GLib.Uuid.string_random ());
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

string toOctal (int64 value) {
    if (value <= 0) {
        return "0";
    }

    string out = "";
    int64 n = value;
    while (n > 0) {
        int digit = (int) (n & 7);
        out = ((char) ('0' + digit)).to_string () + out;
        n >>= 3;
    }
    return out;
}

void writeStringField (uint8[] header, int offset, int width, string value) {
    int limit = value.length;
    if (limit > width) {
        limit = width;
    }
    for (int i = 0; i < limit; i++) {
        header[offset + i] = (uint8) value[i];
    }
}

void writeOctalField (uint8[] header, int offset, int width, int64 value) {
    string oct = toOctal (value);
    int digitsWidth = width - 1;
    if (oct.length > digitsWidth) {
        oct = oct.substring (oct.length - digitsWidth);
    }
    int pad = digitsWidth - oct.length;
    for (int i = 0; i < pad; i++) {
        header[offset + i] = (uint8) '0';
    }
    for (int i = 0; i < oct.length; i++) {
        header[offset + pad + i] = (uint8) oct[i];
    }
    header[offset + width - 1] = 0;
}

void writeChecksumField (uint8[] header) {
    for (int i = 0; i < 8; i++) {
        header[148 + i] = (uint8) ' ';
    }

    int64 sum = 0;
    for (int i = 0; i < 512; i++) {
        sum += header[i];
    }

    string oct = toOctal (sum);
    if (oct.length > 6) {
        oct = oct.substring (oct.length - 6);
    }
    int pad = 6 - oct.length;
    for (int i = 0; i < pad; i++) {
        header[148 + i] = (uint8) '0';
    }
    for (int i = 0; i < oct.length; i++) {
        header[148 + pad + i] = (uint8) oct[i];
    }
    header[154] = 0;
    header[155] = (uint8) ' ';
}

uint8[] buildSingleFileTar (string entryName, string contents) {
    uint8[] contentBytes = contents.data[0 : contents.length];
    uint8[] header = new uint8[512];
    writeStringField (header, 0, 100, entryName);
    writeOctalField (header, 100, 8, 0644);
    writeOctalField (header, 108, 8, 0);
    writeOctalField (header, 116, 8, 0);
    writeOctalField (header, 124, 12, contentBytes.length);
    writeOctalField (header, 136, 12, 0);
    header[156] = (uint8) '0';
    writeStringField (header, 257, 6, "ustar");
    writeStringField (header, 263, 2, "00");
    writeChecksumField (header);

    var output = new GLib.ByteArray ();
    output.append (header);
    output.append (contentBytes);

    int payloadPadding = (int) ((512 - (contentBytes.length % 512)) % 512);
    if (payloadPadding > 0) {
        output.append (new uint8[payloadPadding]);
    }
    output.append (new uint8[512]);
    output.append (new uint8[512]);
    return output.steal ();
}

void testCreateAndExtract () {
    string root = rootFor ("create_extract");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/src")));

    var a = new Vala.Io.Path (root + "/src/a.txt");
    var b = new Vala.Io.Path (root + "/src/b.txt");
    assert (Files.writeText (a, "alpha"));
    assert (Files.writeText (b, "beta"));

    var archive = new Vala.Io.Path (root + "/files.tar");
    var files = new ArrayList<Vala.Io.Path> ();
    files.add (a);
    files.add (b);

    assertOk (Tar.create (archive, files));
    assertOk (Tar.extract (archive, new Vala.Io.Path (root + "/out")));
    assert (Files.readAllText (new Vala.Io.Path (root + "/out/a.txt")) == "alpha");
    assert (Files.readAllText (new Vala.Io.Path (root + "/out/b.txt")) == "beta");
    cleanup (root);
}

void testCreateAndExtractLeadingDash () {
    string root = rootFor ("create_extract_leading_dash");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/src")));

    var dashFile = new Vala.Io.Path (root + "/src/-dash.txt");
    assert (Files.writeText (dashFile, "dash"));

    var archive = new Vala.Io.Path (root + "/files.tar");
    var files = new ArrayList<Vala.Io.Path> ();
    files.add (dashFile);

    assertOk (Tar.create (archive, files));
    assertOk (Tar.extract (archive, new Vala.Io.Path (root + "/out")));
    assert (Files.readAllText (new Vala.Io.Path (root + "/out/-dash.txt")) == "dash");
    cleanup (root);
}

void testCreateFromDirAndList () {
    string root = rootFor ("from_dir");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/tree/sub")));
    assert (Files.writeText (new Vala.Io.Path (root + "/tree/root.txt"), "r"));
    assert (Files.writeText (new Vala.Io.Path (root + "/tree/sub/nested.txt"), "n"));

    var archive = new Vala.Io.Path (root + "/tree.tar");
    assertOk (Tar.createFromDir (archive, new Vala.Io.Path (root + "/tree")));

    ArrayList<string> entries = unwrapEntries (Tar.list (archive));
    assert (containsSuffix (entries, "root.txt"));
    assert (containsSuffix (entries, "sub/nested.txt"));
    cleanup (root);
}

void testAddFile () {
    string root = rootFor ("add_file");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/base")));
    assert (Files.writeText (new Vala.Io.Path (root + "/base/one.txt"), "one"));

    var archive = new Vala.Io.Path (root + "/base.tar");
    assertOk (Tar.createFromDir (archive, new Vala.Io.Path (root + "/base")));

    var add = new Vala.Io.Path (root + "/add.txt");
    assert (Files.writeText (add, "add"));
    assertOk (Tar.addFile (archive, add));

    ArrayList<string> entries = unwrapEntries (Tar.list (archive));
    assert (containsSuffix (entries, "add.txt"));
    cleanup (root);
}

void testExtractFile () {
    string root = rootFor ("extract_file");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/tree/sub")));
    assert (Files.writeText (new Vala.Io.Path (root + "/tree/sub/nested.txt"), "target"));

    var archive = new Vala.Io.Path (root + "/tree.tar");
    assertOk (Tar.createFromDir (archive, new Vala.Io.Path (root + "/tree")));

    ArrayList<string> entries = unwrapEntries (Tar.list (archive));

    string ? entry = findBySuffix (entries, "sub/nested.txt");
    assert (entry != null);
    if (entry == null) {
        cleanup (root);
        return;
    }

    var outputPath = new Vala.Io.Path (root + "/single.txt");
    assertOk (Tar.extractFile (archive, entry, outputPath));
    assert (Files.readAllText (outputPath) == "target");
    cleanup (root);
}

void testExtractFileMissingEntryKeepsDestination () {
    string root = rootFor ("extract_file_fail_keep");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/tree")));
    assert (Files.writeText (new Vala.Io.Path (root + "/tree/ok.txt"), "ok"));

    var archive = new Vala.Io.Path (root + "/tree.tar");
    assertOk (Tar.createFromDir (archive, new Vala.Io.Path (root + "/tree")));

    var outputPath = new Vala.Io.Path (root + "/single.txt");
    assert (Files.writeText (outputPath, "keep"));
    var extracted = Tar.extractFile (archive, "missing-entry.txt", outputPath);
    assert (extracted.isError ());
    assert (extracted.unwrapError () is TarError.NOT_FOUND);
    assert (Files.readAllText (outputPath) == "keep");
    cleanup (root);
}

void testCreateRejectsDuplicateBasename () {
    string root = rootFor ("duplicate_basename");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/a")));
    assert (Files.makeDirs (new Vala.Io.Path (root + "/b")));
    assert (Files.writeText (new Vala.Io.Path (root + "/a/name.txt"), "one"));
    assert (Files.writeText (new Vala.Io.Path (root + "/b/name.txt"), "two"));

    var files = new ArrayList<Vala.Io.Path> ();
    files.add (new Vala.Io.Path (root + "/a/name.txt"));
    files.add (new Vala.Io.Path (root + "/b/name.txt"));
    var created = Tar.create (new Vala.Io.Path (root + "/dup.tar"), files);
    assert (created.isError ());
    assert (created.unwrapError () is TarError.INVALID_ARGUMENT);
    cleanup (root);
}

void testInvalidInputs () {
    string root = rootFor ("invalid");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var empty = new ArrayList<Vala.Io.Path> ();
    var emptyCreate = Tar.create (new Vala.Io.Path (root + "/x.tar"), empty);
    assert (emptyCreate.isError ());
    assert (emptyCreate.unwrapError () is TarError.INVALID_ARGUMENT);

    var noRegularFiles = new ArrayList<Vala.Io.Path> ();
    noRegularFiles.add (new Vala.Io.Path (root + "/missing.txt"));
    var missingCreate = Tar.create (new Vala.Io.Path (root + "/y.tar"), noRegularFiles);
    assert (missingCreate.isError ());
    assert (missingCreate.unwrapError () is TarError.NOT_FOUND);

    var fromDir = Tar.createFromDir (
        new Vala.Io.Path (root + "/from-dir.tar"),
        new Vala.Io.Path (root + "/missing-dir")
    );
    assert (fromDir.isError ());
    assert (fromDir.unwrapError () is TarError.INVALID_ARGUMENT);

    var listed = Tar.list (new Vala.Io.Path (root + "/missing.tar"));
    assert (listed.isError ());
    assert (listed.unwrapError () is TarError.NOT_FOUND);

    var extracted = Tar.extract (new Vala.Io.Path (root + "/missing.tar"), new Vala.Io.Path (root + "/out"));
    assert (extracted.isError ());
    assert (extracted.unwrapError () is TarError.NOT_FOUND);

    var added = Tar.addFile (new Vala.Io.Path (root + "/missing.tar"), new Vala.Io.Path (root + "/missing.txt"));
    assert (added.isError ());
    assert (added.unwrapError () is TarError.NOT_FOUND);

    assert (Files.makeDirs (new Vala.Io.Path (root + "/base")));
    assert (Files.writeText (new Vala.Io.Path (root + "/base/one.txt"), "one"));
    var archive = new Vala.Io.Path (root + "/base.tar");
    assertOk (Tar.createFromDir (archive, new Vala.Io.Path (root + "/base")));

    ArrayList<string> entries = unwrapEntries (Tar.list (archive));
    string ? oneEntry = findBySuffix (entries, "one.txt");
    assert (oneEntry != null);
    if (oneEntry != null) {
        var parentAsFile = new Vala.Io.Path (root + "/parent_as_file");
        assert (Files.writeText (parentAsFile, "file"));
        var invalidDest = new Vala.Io.Path (parentAsFile.toString () + "/out.txt");
        var invalidParent = Tar.extractFile (archive, oneEntry, invalidDest);
        assert (invalidParent.isError ());
        assert (invalidParent.unwrapError () is TarError.INVALID_ARGUMENT);
    }

    var addMissingFile = Tar.addFile (archive, new Vala.Io.Path (root + "/missing-file.txt"));
    assert (addMissingFile.isError ());
    assert (addMissingFile.unwrapError () is TarError.NOT_FOUND);

    var extractedFile = Tar.extractFile (
        new Vala.Io.Path (root + "/missing.tar"),
        "entry.txt",
        new Vala.Io.Path (root + "/entry.txt")
    );
    assert (extractedFile.isError ());
    assert (extractedFile.unwrapError () is TarError.NOT_FOUND);
    cleanup (root);
}

void testExtractRejectsLinkEntries () {
    string root = rootFor ("reject_links");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root + "/tree")));
    assert (Files.writeText (new Vala.Io.Path (root + "/tree/plain.txt"), "plain"));

    int rc = Posix.symlink ("/etc/passwd", root + "/tree/link_out");
    if (rc != 0) {
        Test.skip ("symlink is not supported in this environment");
        cleanup (root);
        return;
    }

    var archive = new Vala.Io.Path (root + "/link.tar");
    assertOk (Tar.createFromDir (archive, new Vala.Io.Path (root + "/tree")));
    var extracted = Tar.extract (archive, new Vala.Io.Path (root + "/out"));
    assert (extracted.isError ());
    assert (extracted.unwrapError () is TarError.SECURITY);
    cleanup (root);
}

void testExtractRejectsTraversalEntries () {
    string root = rootFor ("reject_traversal");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var archive = new Vala.Io.Path (root + "/evil.tar");
    uint8[] evilTar = buildSingleFileTar ("../evil.txt", "danger");
    assert (Files.writeBytes (archive, evilTar));

    var extracted = Tar.extract (archive, new Vala.Io.Path (root + "/out"));
    assert (extracted.isError ());
    assert (extracted.unwrapError () is TarError.SECURITY);
    assert (!Files.exists (new Vala.Io.Path (root + "/evil.txt")));
    cleanup (root);
}

void testListRejectsTruncatedArchive () {
    string root = rootFor ("truncated");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var archive = new Vala.Io.Path (root + "/broken.tar");
    uint8[] broken = { 0x75, 0x73, 0x74, 0x61, 0x72, 0x00, 0x00, 0x00, 0x00 };
    assert (Files.writeBytes (archive, broken));

    var listed = Tar.list (archive);
    assert (listed.isError ());
    assert (listed.unwrapError () is TarError.IO);
    cleanup (root);
}
