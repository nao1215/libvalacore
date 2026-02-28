using Vala.Log;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/log/loglevel/testValueOrder", testValueOrder);
    Test.add_func ("/log/loglevel/testExplicitValues", testExplicitValues);
    Test.run ();
}

void testValueOrder () {
    assert ((int) LogLevel.DEBUG < (int) LogLevel.INFO);
    assert ((int) LogLevel.INFO < (int) LogLevel.WARN);
    assert ((int) LogLevel.WARN < (int) LogLevel.ERROR);
}

void testExplicitValues () {
    assert ((int) LogLevel.DEBUG == 10);
    assert ((int) LogLevel.INFO == 20);
    assert ((int) LogLevel.WARN == 30);
    assert ((int) LogLevel.ERROR == 40);
}
