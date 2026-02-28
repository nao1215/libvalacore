using Vala.Lang;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testChdirAndCwd", testChdirAndCwd);
    Test.add_func ("/testGetEnvExists", testGetEnvExists);
    Test.add_func ("/testGetEnvNotExists", testGetEnvNotExists);
    Test.add_func ("/testCwd", testCwd);
    Test.add_func ("/testChdirSuccess", testChdirSuccess);
    Test.add_func ("/testChdirFail", testChdirFail);
    Test.add_func ("/testOsInstantiation", testOsInstantiation);
    Test.run ();
}

void testChdirAndCwd () {
    assert (Os.chdir ("/tmp") == true);
    assert (Os.cwd () == "/tmp");
    assert (Os.chdir ("/not_exist") == false);
    assert (Os.cwd () == "/tmp");
}

void testGetEnvExists () {
    Environment.set_variable ("VALACORE_TEST_VAR", "hello", true);
    string ? val = Os.get_env ("VALACORE_TEST_VAR");
    assert (val != null);
    assert (val == "hello");
    Environment.unset_variable ("VALACORE_TEST_VAR");
}

void testGetEnvNotExists () {
    Environment.unset_variable ("VALACORE_NONEXISTENT_VAR");
    string ? val = Os.get_env ("VALACORE_NONEXISTENT_VAR");
    assert (val == null);
}

void testCwd () {
    Os.chdir ("/tmp");
    string ? cwd = Os.cwd ();
    assert (cwd != null);
    assert (cwd == "/tmp");
}

void testChdirSuccess () {
    assert (Os.chdir ("/") == true);
    assert (Os.cwd () == "/");
}

void testChdirFail () {
    assert (Os.chdir ("/nonexistent_dir_12345") == false);
}

void testOsInstantiation () {
    /* Exercises GObject boilerplate (construct, class_init, get_type) */
    var os = new Os ();
    assert (os != null);
}
