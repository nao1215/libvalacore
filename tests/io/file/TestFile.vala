using Core;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testIsFile", testIsFile);
    Test.add_func ("/testIsDir", testIsDir);
    Test.run ();
}

void testIsFile () {
    var f1 = new Core.File ("/tmp/valacore/ut/file.txt");
    assert (f1.isFile () == true);

    var f2 = new Core.File ("/tmp/valacore/ut");
    assert (f2.isFile () == false);

    var f3 = new Core.File ("");
    assert (f3.isFile () == false);
}

void testIsDir () {
    var f1 = new Core.File ("/tmp/valacore/ut/file.txt");
    assert (f1.isDir () == false);

    var f2 = new Core.File ("/tmp/valacore/ut");
    assert (f2.isDir () == true);

    var f3 = new Core.File ("");
    assert (f3.isDir () == false);
}