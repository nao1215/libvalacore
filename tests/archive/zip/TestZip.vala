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
    Test.add_func ("/archive/zip/testExtractRejectsRootResolvedFileEntry",
                   testExtractRejectsRootResolvedFileEntry);
    Test.add_func ("/archive/zip/testCreateRejectsDuplicateBasename", testCreateRejectsDuplicateBasename);
    Test.add_func ("/archive/zip/testExtractRejectsTraversalEntries", testExtractRejectsTraversalEntries);
    Test.add_func ("/archive/zip/testListRejectsTruncatedArchive", testListRejectsTruncatedArchive);
    Test.add_func ("/archive/zip/testListRejectsCentralEntryBeyondDeclaredRange",
                   testListRejectsCentralEntryBeyondDeclaredRange);
    Test.add_func ("/archive/zip/testInvalidInputs", testInvalidInputs);
    Test.run ();
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

uint32 updateCrc32 (uint32 current, uint8[] bytes) {
    uint32 crc = current;
    for (int i = 0; i < bytes.length; i++) {
        crc ^= bytes[i];
        for (int j = 0; j < 8; j++) {
            if ((crc & 1) != 0) {
                crc = (crc >> 1) ^ ((uint32) 0xedb88320);
            } else {
                crc >>= 1;
            }
        }
    }
    return crc;
}

uint32 crc32For (uint8[] bytes) {
    return updateCrc32 (uint32.MAX, bytes) ^ uint32.MAX;
}

void appendLe16 (GLib.ByteArray buffer, uint16 value) {
    uint8[] bytes = {
        (uint8) (value & 0xff),
        (uint8) ((value >> 8) & 0xff)
    };
    buffer.append (bytes);
}

void appendLe32 (GLib.ByteArray buffer, uint32 value) {
    uint8[] bytes = {
        (uint8) (value & 0xff),
        (uint8) ((value >> 8) & 0xff),
        (uint8) ((value >> 16) & 0xff),
        (uint8) ((value >> 24) & 0xff)
    };
    buffer.append (bytes);
}

void writeLe32At (uint8[] bytes, int offset, uint32 value) {
    bytes[offset] = (uint8) (value & 0xff);
    bytes[offset + 1] = (uint8) ((value >> 8) & 0xff);
    bytes[offset + 2] = (uint8) ((value >> 16) & 0xff);
    bytes[offset + 3] = (uint8) ((value >> 24) & 0xff);
}

uint8[] buildSingleFileZip (string entryName, string content) {
    uint8[] nameBytes = entryName.data[0 : entryName.length];
    uint8[] bodyBytes = content.data[0 : content.length];
    uint32 crc = crc32For (bodyBytes);

    var zipBytes = new GLib.ByteArray ();

    uint32 localOffset = zipBytes.len;
    appendLe32 (zipBytes, 0x04034b50);
    appendLe16 (zipBytes, 20);
    appendLe16 (zipBytes, 0);
    appendLe16 (zipBytes, 0);
    appendLe16 (zipBytes, 0);
    appendLe16 (zipBytes, 0);
    appendLe32 (zipBytes, crc);
    appendLe32 (zipBytes, bodyBytes.length);
    appendLe32 (zipBytes, bodyBytes.length);
    appendLe16 (zipBytes, (uint16) nameBytes.length);
    appendLe16 (zipBytes, 0);
    zipBytes.append (nameBytes);
    zipBytes.append (bodyBytes);

    uint32 centralOffset = zipBytes.len;
    appendLe32 (zipBytes, 0x02014b50);
    appendLe16 (zipBytes, 20);
    appendLe16 (zipBytes, 20);
    appendLe16 (zipBytes, 0);
    appendLe16 (zipBytes, 0);
    appendLe16 (zipBytes, 0);
    appendLe16 (zipBytes, 0);
    appendLe32 (zipBytes, crc);
    appendLe32 (zipBytes, bodyBytes.length);
    appendLe32 (zipBytes, bodyBytes.length);
    appendLe16 (zipBytes, (uint16) nameBytes.length);
    appendLe16 (zipBytes, 0);
    appendLe16 (zipBytes, 0);
    appendLe16 (zipBytes, 0);
    appendLe16 (zipBytes, 0);
    appendLe32 (zipBytes, 0);
    appendLe32 (zipBytes, localOffset);
    zipBytes.append (nameBytes);

    uint32 centralSize = zipBytes.len - centralOffset;
    appendLe32 (zipBytes, 0x06054b50);
    appendLe16 (zipBytes, 0);
    appendLe16 (zipBytes, 0);
    appendLe16 (zipBytes, 1);
    appendLe16 (zipBytes, 1);
    appendLe32 (zipBytes, centralSize);
    appendLe32 (zipBytes, centralOffset);
    appendLe16 (zipBytes, 0);

    return zipBytes.steal ();
}

void testCreateAndExtract () {
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
    var extractErr = extracted.unwrapError ();
    assert (extractErr is ZipError.NOT_FOUND);
    assert (Files.readAllText (outputPath) == "keep");
    cleanup (root);
}

void testExtractRejectsRootResolvedFileEntry () {
    string root = rootFor ("reject_root_resolved_file");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var archive = new Vala.Io.Path (root + "/root.zip");
    uint8[] zipBytes = buildSingleFileZip (".", "overwrite-root");
    assert (Files.writeBytes (archive, zipBytes));

    var outDir = new Vala.Io.Path (root + "/out");
    var extracted = Zip.extract (archive, outDir);
    assert (extracted.isError ());
    assert (extracted.unwrapError () is ZipError.SECURITY);
    assert (!Files.isFile (outDir));
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
    var created = Zip.create (new Vala.Io.Path (root + "/dup.zip"), files);
    assert (created.isError ());
    var createErr = created.unwrapError ();
    assert (createErr is ZipError.INVALID_ARGUMENT);
    cleanup (root);
}

void testExtractRejectsTraversalEntries () {
    string root = rootFor ("reject_traversal");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var archive = new Vala.Io.Path (root + "/evil.zip");
    uint8[] evilZip = buildSingleFileZip ("../outside.txt", "outside");
    assert (Files.writeBytes (archive, evilZip));

    var extracted = Zip.extract (
        archive,
        new Vala.Io.Path (root + "/out")
    );
    assert (extracted.isError ());
    var securityErr = extracted.unwrapError ();
    assert (securityErr is ZipError.SECURITY);
    assert (!Files.exists (new Vala.Io.Path (root + "/outside.txt")));
    cleanup (root);
}

void testListRejectsTruncatedArchive () {
    string root = rootFor ("truncated");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var archive = new Vala.Io.Path (root + "/broken.zip");
    uint8[] broken = { 0x50, 0x4b, 0x03, 0x04, 0x00 };
    assert (Files.writeBytes (archive, broken));

    var listed = Zip.list (archive);
    assert (listed.isError ());
    assert (listed.unwrapError () is ZipError.IO);
    cleanup (root);
}

void testListRejectsCentralEntryBeyondDeclaredRange () {
    string root = rootFor ("invalid_central_range");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var archive = new Vala.Io.Path (root + "/invalid-central.zip");
    uint8[] bytes = buildSingleFileZip ("one.txt", "one");
    int eocdOffset = bytes.length - 22;
    writeLe32At (bytes, eocdOffset + 12, 1);
    assert (Files.writeBytes (archive, bytes));

    var listed = Zip.list (archive);
    assert (listed.isError ());
    assert (listed.unwrapError () is ZipError.IO);
    cleanup (root);
}

void testInvalidInputs () {
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

    var fromDir = Zip.createFromDir (
        new Vala.Io.Path (root + "/from-dir.zip"),
        new Vala.Io.Path (root + "/missing-dir")
    );
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
