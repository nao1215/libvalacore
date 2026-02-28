using Vala.Lang;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/lang/systemenv/testConstruct", testConstruct);
    Test.add_func ("/lang/systemenv/testGetSet", testGetSet);
    Test.add_func ("/lang/systemenv/testInvalidKey", testInvalidKey);
    Test.run ();
}

void testConstruct () {
    SystemEnv env = new SystemEnv ();
    assert (env != null);
}

void testGetSet () {
    string key = "LIBVALACORE_TEST_SYSTEMENV";
    assert (SystemEnv.set (key, "ok") == true);
    assert (SystemEnv.get (key) == "ok");
}

void testInvalidKey () {
    assert (SystemEnv.set ("", "x") == false);
    assert (SystemEnv.get ("") == null);
}
