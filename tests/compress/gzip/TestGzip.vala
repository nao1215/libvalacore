using Vala.Compress;
using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/compress/gzip/testCompressAndDecompress", testCompressAndDecompress);
    Test.add_func ("/compress/gzip/testCompressLevel", testCompressLevel);
    Test.add_func ("/compress/gzip/testDecompressInvalid", testDecompressInvalid);
    Test.add_func ("/compress/gzip/testFileRoundtrip", testFileRoundtrip);
    Test.add_func ("/compress/gzip/testCompressFileMissingSource", testCompressFileMissingSource);
    Test.add_func ("/compress/gzip/testEmptyRoundtrip", testEmptyRoundtrip);
    Test.run ();
}

string rootFor (string name) {
    return "/tmp/valacore/ut/gzip_" + name;
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
        data[i] = (uint8) ('A' + (i % 4));
    }
    return data;
}

void testCompressAndDecompress () {
    uint8[] source = sampleData ();
    uint8[] compressed = Gzip.compress (source);
    assert (compressed.length > 0);

    uint8[] ? restored = Gzip.decompress (compressed);
    assert (restored != null);
    if (restored == null) {
        return;
    }
    assert (bytesEqual (source, restored));
}

void testCompressLevel () {
    uint8[] source = sampleData ();
    uint8[] fast = Gzip.compressLevel (source, 1);
    uint8[] best = Gzip.compressLevel (source, 9);
    assert (best.length <= fast.length);

    uint8[] ? restoredFast = Gzip.decompress (fast);
    uint8[] ? restoredBest = Gzip.decompress (best);
    assert (restoredFast != null);
    assert (restoredBest != null);
    if (restoredFast == null || restoredBest == null) {
        return;
    }

    assert (bytesEqual (source, restoredFast));
    assert (bytesEqual (source, restoredBest));
}

void testDecompressInvalid () {
    uint8[] invalid = { 0x01, 0x02, 0x03, 0x04, 0x05 };
    assert (Gzip.decompress (invalid) == null);
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
    assert (Gzip.compressFile (src, gz));
    assert (Files.exists (gz));
    assert (Gzip.decompressFile (gz, restored));

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
    assert (!Gzip.compressFile (src, dst));
    cleanup (root);
}

void testEmptyRoundtrip () {
    uint8[] empty = {};
    uint8[] compressed = Gzip.compress (empty);
    uint8[] ? restored = Gzip.decompress (compressed);
    // Vala can represent empty arrays as null pointers internally.
    assert (restored == null || restored.length == 0);
}
