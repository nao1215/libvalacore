using Core;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testChdirAndCwd", testChdirAndCwd);
    Test.run ();
}

void testChdirAndCwd () {
    assert (Os.chdir ("/tmp") == true);
    assert (Os.cwd () == "/tmp");
    assert (Os.chdir ("/not_exist") == false);
    assert (Os.cwd () == "/tmp");
}