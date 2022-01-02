using Core;

void main (string[] args) {
    Test.init (ref args);
    // Test.add_func ("/testAbs", testAbs);
    Test.run ();
}

/*
   void testAbs () {
    var path = new Core.Path ("test");
    var abs = path.abs ();
    print ("%s\n", abs);
    assert (abs == null);
   }
 */
