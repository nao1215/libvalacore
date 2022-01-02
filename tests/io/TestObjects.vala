void add_objects_tests () {
    Test.add_func ("/libcore/objects", () => {
        string test = null;
        assert (Core.Objects.isNull (test) == true);
    });
}