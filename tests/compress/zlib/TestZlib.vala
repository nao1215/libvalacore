using Vala.Compress;
using Vala.Collections;
using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/compress/zlib/testCompressAndDecompress", testCompressAndDecompress);
    Test.add_func ("/compress/zlib/testCompressLevel", testCompressLevel);
    Test.add_func ("/compress/zlib/testCompressLevelInvalid", testCompressLevelInvalid);
    Test.add_func ("/compress/zlib/testDecompressInvalid", testDecompressInvalid);
    Test.add_func ("/compress/zlib/testFileRoundtrip", testFileRoundtrip);
    Test.add_func ("/compress/zlib/testCompressFileMissingSource", testCompressFileMissingSource);
    Test.add_func ("/compress/zlib/testDecompressFileMissingSource", testDecompressFileMissingSource);
    Test.add_func ("/compress/zlib/testEmptyRoundtrip", testEmptyRoundtrip);
    Test.run ();
}

string rootFor (string name) {
    return "%s/valacore/ut/zlib_%s_%s".printf (Environment.get_tmp_dir (), name, GLib.Uuid.string_random ());
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
        data[i] = (uint8) ('a' + (i % 6));
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
    uint8[] compressed = unwrapBytes (Zlib.compress (source));
    assert (compressed.length > 0);

    uint8[] restored = unwrapBytes (Zlib.decompress (compressed));
    assert (bytesEqual (source, restored));
}

void testCompressLevel () {
    uint8[] source = sampleData ();
    uint8[] fast = unwrapBytes (Zlib.compressLevel (source, 1));
    uint8[] best = unwrapBytes (Zlib.compressLevel (source, 9));
    assert (best.length <= fast.length);

    uint8[] restoredFast = unwrapBytes (Zlib.decompress (fast));
    uint8[] restoredBest = unwrapBytes (Zlib.decompress (best));
    assert (bytesEqual (source, restoredFast));
    assert (bytesEqual (source, restoredBest));
}

void testCompressLevelInvalid () {
    uint8[] source = sampleData ();
    var compressed = Zlib.compressLevel (source, 0);
    assert (compressed.isError ());
    assert (compressed.unwrapError () is ZlibError.INVALID_ARGUMENT);
}

void testDecompressInvalid () {
    uint8[] invalid = { 0x40, 0x20, 0x10, 0x05, 0x01 };
    var restored = Zlib.decompress (invalid);
    assert (restored.isError ());
    assert (restored.unwrapError () is ZlibError.PARSE);
}

void testFileRoundtrip () {
    string root = rootFor ("roundtrip");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var src = new Vala.Io.Path (root + "/source.bin");
    var zf = new Vala.Io.Path (root + "/source.bin.z");
    var restored = new Vala.Io.Path (root + "/restored.bin");

    uint8[] srcData = sampleData ();
    assert (Files.writeBytes (src, srcData));
    assertOk (Zlib.compressFile (src, zf));
    assert (Files.exists (zf));
    assertOk (Zlib.decompressFile (zf, restored));

    uint8[] ? restoredData = Files.readBytes (restored);
    assert (restoredData != null);
    if (restoredData == null) {
        cleanup (root);
        return;
    }
    assert (bytesEqual (srcData, restoredData));
    cleanup (root);
}

void testCompressFileMissingSource () {
    string root = rootFor ("missing");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var src = new Vala.Io.Path (root + "/missing.txt");
    var dst = new Vala.Io.Path (root + "/missing.txt.z");
    var compressed = Zlib.compressFile (src, dst);
    assert (compressed.isError ());
    assert (compressed.unwrapError () is ZlibError.NOT_FOUND);
    cleanup (root);
}

void testDecompressFileMissingSource () {
    string root = rootFor ("decompress_missing");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var src = new Vala.Io.Path (root + "/missing.z");
    var dst = new Vala.Io.Path (root + "/plain.txt");
    var decompressed = Zlib.decompressFile (src, dst);
    assert (decompressed.isError ());
    assert (decompressed.unwrapError () is ZlibError.NOT_FOUND);
    cleanup (root);
}

void testEmptyRoundtrip () {
    uint8[] empty = {};
    uint8[] compressed = unwrapBytes (Zlib.compress (empty));
    uint8[] restored = unwrapBytes (Zlib.decompress (compressed));
    assert (restored.length == 0);
}
