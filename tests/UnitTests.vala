using Core;

namespace UT {
    void main (string[] args) {
        Test.init (ref args);
        add_objects_tests ();
        Test.run ();
    }
}