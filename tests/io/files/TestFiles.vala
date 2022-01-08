using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testIsFile", testIsFile);
    Test.add_func ("/testIsDir", testIsDir);
    Test.add_func ("/testExists", testExists);
    Test.add_func ("/testCanRead", testCanRead);
    Test.add_func ("/testCanWrite", testCanWrite);
    Test.add_func ("/testCanExec", testCanExec);
    Test.add_func ("/testIsSymbolicFile", testIsSymbolicFile);
    Test.add_func ("/testIsHiddenFile", testIsHiddenFile);
    Test.run ();
}

void testIsFile () {
    var f1 = new Files ("/tmp/valacore/ut/file.txt");
    assert (f1.isFile () == true);

    var f2 = new Files ("/tmp/valacore/ut");
    assert (f2.isFile () == false);

    var f3 = new Files ("");
    assert (f3.isFile () == false);

    var f4 = new Files ("/tmp/valacore/ut/symbolic.txt");
    assert (f4.isFile () == true);

    var f5 = new Files ("/tmp/valacore/ut/symbolic");
    assert (f5.isFile () == false);

    var f6 = new Files ("/tmp/valacore/ut/.hidden.txt");
    assert (f6.isFile () == true);

    var f7 = new Files ("/tmp/valacore/ut/.hidden");
    assert (f7.isFile () == false);
}

void testIsDir () {
    var f1 = new Files ("/tmp/valacore/ut/file.txt");
    assert (f1.isDir () == false);

    var f2 = new Files ("/tmp/valacore/ut");
    assert (f2.isDir () == true);

    var f3 = new Files ("");
    assert (f3.isDir () == false);

    var f4 = new Files ("/tmp/valacore/ut/symbolic.txt");
    assert (f4.isDir () == false);

    var f5 = new Files ("/tmp/valacore/ut/symbolic");
    assert (f5.isDir () == true);

    var f6 = new Files ("/tmp/valacore/ut/.hidden.txt");
    assert (f6.isDir () == false);

    var f7 = new Files ("/tmp/valacore/ut/.hidden");
    assert (f7.isDir () == true);
}

void testExists () {
    var f1 = new Files ("/tmp/valacore/ut/file.txt");
    assert (f1.exists () == true);

    var f2 = new Files ("/tmp/valacore/ut");
    assert (f2.exists () == true);

    var f3 = new Files ("no_exists");
    assert (f3.exists () == false);

    var f4 = new Files ("/tmp/valacore/ut/symbolic.txt");
    assert (f4.exists () == true);

    var f5 = new Files ("/tmp/valacore/ut/symbolic");
    assert (f5.exists () == true);

    var f6 = new Files ("/tmp/valacore/ut/.hidden.txt");
    assert (f6.exists () == true);

    var f7 = new Files ("/tmp/valacore/ut/.hidden");
    assert (f7.exists () == true);
}

void testCanRead () {
    var f1 = new Files ("/tmp/valacore/ut/canNotRead.txt");
    assert (f1.canRead () == false);

    var f2 = new Files ("/tmp/valacore/ut");
    assert (f2.canRead () == true);

    var f3 = new Files ("/tmp/valacore/ut/file.txt");
    assert (f3.canRead () == true);

    var f4 = new Files ("/tmp/valacore/ut/no_exist_file.txt");
    assert (f4.canRead () == false);

    var f5 = new Files ("/tmp/valacore/ut/canNotReadDir");
    assert (f5.canRead () == false);
}

void testCanWrite () {
    var f1 = new Files ("/tmp/valacore/ut/canNotWrite.txt");
    assert (f1.canWrite () == false);

    var f2 = new Files ("/tmp/valacore/ut");
    assert (f2.canWrite () == true);

    var f3 = new Files ("/tmp/valacore/ut/file.txt");
    assert (f3.canWrite () == true);

    var f4 = new Files ("/tmp/valacore/ut/no_exist_file.txt");
    assert (f4.canWrite () == false);

    var f5 = new Files ("/tmp/valacore/ut/canNotWriteDir");
    assert (f5.canWrite () == false);
}

void testCanExec () {
    var f1 = new Files ("/tmp/valacore/ut/canNotExec.txt");
    assert (f1.canExec () == false);

    var f2 = new Files ("/tmp/valacore/ut");
    assert (f2.canExec () == true);

    var f3 = new Files ("/tmp/valacore/ut/file.txt");
    assert (f3.canExec () == true);

    var f4 = new Files ("/tmp/valacore/ut/no_exist_file.txt");
    assert (f4.canExec () == false);

    var f5 = new Files ("/tmp/valacore/ut/canNotExecDir");
    assert (f5.canExec () == false);
}

void testIsSymbolicFile () {
    var f1 = new Files ("/tmp/valacore/ut/canNotExec.txt");
    assert (f1.isSymbolicFile () == false);

    var f2 = new Files ("/tmp/valacore/ut");
    assert (f2.isSymbolicFile () == false);

    var f3 = new Files ("/tmp/valacore/ut/file.txt");
    assert (f3.isSymbolicFile () == false);

    var f4 = new Files ("/tmp/valacore/ut/no_exist_file.txt");
    assert (f4.isSymbolicFile () == false);

    var f5 = new Files ("/tmp/valacore/ut/canNotExecDir");
    assert (f5.isSymbolicFile () == false);

    var f6 = new Files ("/tmp/valacore/ut/symbolic.txt");
    assert (f6.isSymbolicFile () == true);

    var f7 = new Files ("/tmp/valacore/ut/.hidden.txt");
    assert (f7.isSymbolicFile () == false);

    var f8 = new Files ("/tmp/valacore/ut/.hidden");
    assert (f8.isSymbolicFile () == false);
}

void testIsHiddenFile () {
    var f1 = new Files ("/tmp/valacore/ut/canNotExec.txt");
    assert (f1.isHiddenFile () == false);

    var f2 = new Files ("/tmp/valacore/ut");
    assert (f2.isHiddenFile () == false);

    var f3 = new Files ("/tmp/valacore/ut/file.txt");
    assert (f3.isHiddenFile () == false);

    var f4 = new Files ("/tmp/valacore/ut/no_exist_file.txt");
    assert (f4.isHiddenFile () == false);

    var f5 = new Files ("/tmp/valacore/ut/canNotExecDir");
    assert (f5.isHiddenFile () == false);

    var f6 = new Files ("/tmp/valacore/ut/symbolic.txt");
    assert (f6.isHiddenFile () == false);

    var f7 = new Files ("/tmp/valacore/ut/.hidden.txt");
    assert (f7.isHiddenFile () == true);

    var f8 = new Files ("/tmp/valacore/ut/.hidden");
    assert (f8.isHiddenFile () == true);
}
