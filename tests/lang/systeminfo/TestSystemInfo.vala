using Vala.Lang;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/lang/systeminfo/testConstruct", testConstruct);
    Test.add_func ("/lang/systeminfo/testPaths", testPaths);
    Test.add_func ("/lang/systeminfo/testOsName", testOsName);
    Test.run ();
}

void testConstruct () {
    SystemInfo info = new SystemInfo ();
    assert (info != null);
}

void testPaths () {
    assert (SystemInfo.userHome () == Environment.get_home_dir ());
    assert (SystemInfo.tmpDir () == Environment.get_tmp_dir ());
    assert (SystemInfo.currentDir () == Environment.get_current_dir ());
}

void testOsName () {
    string osName = SystemInfo.osName ();
    assert (osName.length > 0);
}
