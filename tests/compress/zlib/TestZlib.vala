using Vala.Compress;
using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/compress/zlib/testCompressAndDecompress", testCompressAndDecompress);
    Test.add_func ("/compress/zlib/testCompressLevel", testCompressLevel);
    Test.add_func ("/compress/zlib/testDecompressInvalid", testDecompressInvalid);
    Test.add_func ("/compress/zlib/testFileRoundtrip", testFileRoundtrip);
    Test.add_func ("/compress/zlib/testCompressFileMissingSource", testCompressFileMissingSource);
    Test.add_func ("/compress/zlib/testEmptyRoundtrip", testEmptyRoundtrip);
    Test.run ();
}

string rootFor (string name) {
    return "/tmp/valacore/ut/zlib_" + name;
}

void cleanup (string path) {
    Posix.system ("rm -rf " + path);
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

void testCompressAndDecompress () {
    uint8[] source = sampleData ();
    uint8[] compressed = Zlib.compress (source);
    assert (compressed.length > 0);

    uint8[] restored = Zlib.decompress (compressed);
    assert (bytesEqual (source, restored));
}

void testCompressLevel () {
    uint8[] source = sampleData ();
    uint8[] fast = Zlib.compressLevel (source, 1);
    uint8[] best = Zlib.compressLevel (source, 9);
    assert (best.length <= fast.length);

    uint8[] restoredFast = Zlib.decompress (fast);
    uint8[] restoredBest = Zlib.decompress (best);
    assert (bytesEqual (source, restoredFast));
    assert (bytesEqual (source, restoredBest));
}

void testDecompressInvalid () {
    uint8[] invalid = { 0x40, 0x20, 0x10, 0x05, 0x01 };
    uint8[] restored = Zlib.decompress (invalid);
    assert (restored.length == 0);
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
    assert (Zlib.compressFile (src, zf));
    assert (Files.exists (zf));
    assert (Zlib.decompressFile (zf, restored));

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
    assert (!Zlib.compressFile (src, dst));
    cleanup (root);
}

void testEmptyRoundtrip () {
    uint8[] empty = {};
    uint8[] compressed = Zlib.compress (empty);
    uint8[] restored = Zlib.decompress (compressed);
    assert (restored.length == 0);
}
