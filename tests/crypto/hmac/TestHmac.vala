using Vala.Crypto;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/hmac/testSha256", testSha256);
    Test.add_func ("/hmac/testSha512", testSha512);
    Test.add_func ("/hmac/testVerify", testVerify);
    Test.run ();
}

void testSha256 () {
    assert (Vala.Crypto.Hmac.sha256 ("secret", "hello")
            == "88aab3ede8d3adf94d26ab90d3bafd4a"
            + "2083070c3bcce9c014ee04a443847c0b");
}

void testSha512 () {
    assert (Vala.Crypto.Hmac.sha512 ("secret", "hello")
            == "db1595ae88a62fd151ec1cba81b98c39"
            + "df82daae7b4cb9820f446d5bf02f1dcf"
            + "ca6683d88cab3e273f5963ab8ec469a7"
            + "46b5b19086371239f67d1e5f99a79440");
}

void testVerify () {
    string expected = Vala.Crypto.Hmac.sha256 ("secret", "hello");
    string same = Vala.Crypto.Hmac.sha256 ("secret", "hello");
    string different = Vala.Crypto.Hmac.sha256 ("secret", "world");

    assert (Vala.Crypto.Hmac.verify (expected, same) == true);
    assert (Vala.Crypto.Hmac.verify (expected, different) == false);
    assert (Vala.Crypto.Hmac.verify (expected, expected + "00") == false);
}
