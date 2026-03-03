using Vala.Compress;
using Vala.Collections;
using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/compress/gzip/testCompressAndDecompress", testCompressAndDecompress);
    Test.add_func ("/compress/gzip/testCompressLevel", testCompressLevel);
    Test.add_func ("/compress/gzip/testCompressLevelInvalid", testCompressLevelInvalid);
    Test.add_func ("/compress/gzip/testDecompressInvalid", testDecompressInvalid);
    Test.add_func ("/compress/gzip/testFileRoundtrip", testFileRoundtrip);
    Test.add_func ("/compress/gzip/testCompressFileMissingSource", testCompressFileMissingSource);
    Test.add_func ("/compress/gzip/testDecompressFileMissingSource", testDecompressFileMissingSource);
    Test.add_func ("/compress/gzip/testEmptyRoundtrip", testEmptyRoundtrip);
    Test.run ();
}

string rootFor (string name) {
    return "%s/valacore/ut/gzip_%s_%s".printf (Environment.get_tmp_dir (), name, GLib.Uuid.string_random ());
}

void cleanup (string path) {
    FileTree.deleteTree (new Vala.Io.Path (path));
}

bool bytesEqual (uint8[] a, uint8[] b) {
    if (a.length != b.length) {
        return false;
    }
    for (int i = 0; i < a.length; i++) {
        if (a[i] != b[i]) {
            return false;
        }
    }
    return true;
}

uint8[] sampleData () {
    uint8[] data = new uint8[4096];
    for (int i = 0; i < data.length; i++) {
        data[i] = (uint8) ('A' + (i % 4));
    }
    return data;
}

uint8[] copyBytes (GLib.Bytes bytes) {
    uint8[] raw = bytes.get_data ();
    uint8[] copied = new uint8[raw.length];
    for (int i = 0; i < raw.length; i++) {
        copied[i] = raw[i];
    }
    return copied;
}

void assertOk (Result<bool, GLib.Error> result) {
    assert (result.isOk ());
    assert (result.unwrap ());
}

uint8[] unwrapBytes (Result<GLib.Bytes, GLib.Error> result) {
    assert (result.isOk ());
    return copyBytes (result.unwrap ());
}

void testCompressAndDecompress () {
    uint8[] source = sampleData ();
    uint8[] compressed = unwrapBytes (Gzip.compress (source));
    assert (compressed.length > 0);

    uint8[] restored = unwrapBytes (Gzip.decompress (compressed));
    assert (bytesEqual (source, restored));
}

void testCompressLevel () {
    uint8[] source = sampleData ();
    uint8[] fast = unwrapBytes (Gzip.compressLevel (source, 1));
    uint8[] best = unwrapBytes (Gzip.compressLevel (source, 9));
    assert (best.length <= fast.length);

    uint8[] restoredFast = unwrapBytes (Gzip.decompress (fast));
    uint8[] restoredBest = unwrapBytes (Gzip.decompress (best));

    assert (bytesEqual (source, restoredFast));
    assert (bytesEqual (source, restoredBest));
}

void testCompressLevelInvalid () {
    uint8[] source = sampleData ();
    var compressed = Gzip.compressLevel (source, 0);
    assert (compressed.isError ());
    assert (compressed.unwrapError () is GzipError.INVALID_ARGUMENT);
}

void testDecompressInvalid () {
    uint8[] invalid = { 0x01, 0x02, 0x03, 0x04, 0x05 };
    var decompressed = Gzip.decompress (invalid);
    assert (decompressed.isError ());
    assert (decompressed.unwrapError () is GzipError.PARSE);
}

void testFileRoundtrip () {
    string root = rootFor ("roundtrip");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var src = new Vala.Io.Path (root + "/source.txt");
    var gz = new Vala.Io.Path (root + "/source.txt.gz");
    var restored = new Vala.Io.Path (root + "/restored.txt");

    var builder = new GLib.StringBuilder ();
    for (int i = 0; i < 200; i++) {
        builder.append ("line");
        builder.append_printf ("%d", i);
        builder.append ("\n");
    }

    assert (Files.writeText (src, builder.str));
    assertOk (Gzip.compressFile (src, gz));
    assert (Files.exists (gz));
    assertOk (Gzip.decompressFile (gz, restored));

    string ? restoredText = Files.readAllText (restored);
    assert (restoredText == builder.str);
    cleanup (root);
}

void testCompressFileMissingSource () {
    string root = rootFor ("missing");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var src = new Vala.Io.Path (root + "/missing.txt");
    var dst = new Vala.Io.Path (root + "/missing.txt.gz");
    var compressed = Gzip.compressFile (src, dst);
    assert (compressed.isError ());
    assert (compressed.unwrapError () is GzipError.NOT_FOUND);
    cleanup (root);
}

void testDecompressFileMissingSource () {
    string root = rootFor ("decompress_missing");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var src = new Vala.Io.Path (root + "/missing.gz");
    var dst = new Vala.Io.Path (root + "/plain.txt");
    var decompressed = Gzip.decompressFile (src, dst);
    assert (decompressed.isError ());
    assert (decompressed.unwrapError () is GzipError.NOT_FOUND);
    cleanup (root);
}

void testEmptyRoundtrip () {
    uint8[] empty = {};
    uint8[] compressed = unwrapBytes (Gzip.compress (empty));
    uint8[] restored = unwrapBytes (Gzip.decompress (compressed));
    assert (restored.length == 0);
}
