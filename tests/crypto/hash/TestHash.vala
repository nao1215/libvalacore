using Vala.Crypto;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/hash/testMd5", testMd5);
    Test.add_func ("/hash/testMd5Bytes", testMd5Bytes);
    Test.add_func ("/hash/testSha1", testSha1);
    Test.add_func ("/hash/testSha256", testSha256);
    Test.add_func ("/hash/testSha256Bytes", testSha256Bytes);
    Test.add_func ("/hash/testSha512", testSha512);
    Test.run ();
}

void testMd5 () {
    assert (Hash.md5 ("hello") == "5d41402abc4b2a76b9719d911017c592");
}

void testMd5Bytes () {
    uint8[] data = { 0x68, 0x65, 0x6C, 0x6C, 0x6F };
    assert (Hash.md5Bytes (data) == "5d41402abc4b2a76b9719d911017c592");
}

void testSha1 () {
    assert (Hash.sha1 ("hello") == "aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d");
}

void testSha256 () {
    assert (Hash.sha256 ("hello") == "2cf24dba5fb0a30e26e83b2ac5b9e29e"
            + "1b161e5c1fa7425e73043362938b9824");
}

void testSha256Bytes () {
    uint8[] data = { 0x68, 0x65, 0x6C, 0x6C, 0x6F };
    assert (Hash.sha256Bytes (data) == "2cf24dba5fb0a30e26e83b2ac5b9e29e"
            + "1b161e5c1fa7425e73043362938b9824");
}

void testSha512 () {
    assert (Hash.sha512 ("hello") == "9b71d224bd62f3785d96d46ad3ea3d73"
            + "319bfbc2890caadae2dff72519673ca7"
            + "2323c3d99ba5c11d7c7acc6e14b8c5da"
            + "0c4663475c2e5c3adef46f73bcdec043");
}
