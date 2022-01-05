using Core;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testIsFile", testIsFile);
    Test.add_func ("/testIsDir", testIsDir);
    Test.add_func ("/testExists", testExists);
    Test.add_func ("/testCanRead", testCanRead);
    Test.add_func ("/testCanWrite", testCanWrite);
    Test.add_func ("/testCanExec", testCanExec);
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

void testExists () {
    var f1 = new Core.File ("/tmp/valacore/ut/file.txt");
    assert (f1.exists () == true);

    var f2 = new Core.File ("/tmp/valacore/ut");
    assert (f2.exists () == true);

    var f3 = new Core.File ("no_exists");
    assert (f3.exists () == false);
}

void testCanRead () {
    var f1 = new Core.File ("/tmp/valacore/ut/canNotRead.txt");
    assert (f1.canRead () == false);

    var f2 = new Core.File ("/tmp/valacore/ut");
    assert (f2.canRead () == true);

    var f3 = new Core.File ("/tmp/valacore/ut/file.txt");
    assert (f3.canRead () == true);

    var f4 = new Core.File ("/tmp/valacore/ut/no_exist_file.txt");
    assert (f4.canRead () == false);

    var f5 = new Core.File ("/tmp/valacore/ut/canNotReadDir");
    assert (f5.canRead () == false);
}

void testCanWrite () {
    var f1 = new Core.File ("/tmp/valacore/ut/canNotWrite.txt");
    assert (f1.canWrite () == false);

    var f2 = new Core.File ("/tmp/valacore/ut");
    assert (f2.canWrite () == true);

    var f3 = new Core.File ("/tmp/valacore/ut/file.txt");
    assert (f3.canWrite () == true);

    var f4 = new Core.File ("/tmp/valacore/ut/no_exist_file.txt");
    assert (f4.canWrite () == false);

    var f5 = new Core.File ("/tmp/valacore/ut/canNotWriteDir");
    assert (f5.canWrite () == false);
}

void testCanExec () {
    var f1 = new Core.File ("/tmp/valacore/ut/canNotExec.txt");
    assert (f1.canExec () == false);

    var f2 = new Core.File ("/tmp/valacore/ut");
    assert (f2.canExec () == true);

    var f3 = new Core.File ("/tmp/valacore/ut/file.txt");
    assert (f3.canExec () == true);

    var f4 = new Core.File ("/tmp/valacore/ut/no_exist_file.txt");
    assert (f4.canExec () == false);

    var f5 = new Core.File ("/tmp/valacore/ut/canNotExecDir");
    assert (f5.canExec () == false);
}
