using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testOf", testOf);
    Test.add_func ("/testEmpty", testEmpty);
    Test.add_func ("/testOfNullable", testOfNullable);
    Test.add_func ("/testIsPresent", testIsPresent);
    Test.add_func ("/testIsEmpty", testIsEmpty);
    Test.add_func ("/testGet", testGet);
    Test.add_func ("/testOrElse", testOrElse);
    Test.add_func ("/testOrElseGet", testOrElseGet);
    Test.add_func ("/testIfPresent", testIfPresent);
    Test.add_func ("/testFilter", testFilter);
    Test.run ();
}

void testOf () {
    var opt = Optional.of<string>("hello");
    assert (opt.isPresent ());
    assert (opt.get () == "hello");
}

void testEmpty () {
    var opt = Optional.empty<string> ();
    assert (opt.isEmpty ());
    assert (opt.get () == null);
}

void testOfNullable () {
    /* Non-null value */
    string ? name = "Alice";
    var opt = Optional.ofNullable<string>(name);
    assert (opt.isPresent ());
    assert (opt.get () == "Alice");

    /* Null value */
    string ? nothing = null;
    var empty = Optional.ofNullable<string>(nothing);
    assert (empty.isEmpty ());
}

void testIsPresent () {
    assert (Optional.of<string>("x").isPresent () == true);
    assert (Optional.empty<string> ().isPresent () == false);
}

void testIsEmpty () {
    assert (Optional.of<string>("x").isEmpty () == false);
    assert (Optional.empty<string> ().isEmpty () == true);
}

void testGet () {
    var opt = Optional.of<string>("value");
    assert (opt.get () == "value");

    /* Empty returns null */
    var empty = Optional.empty<string> ();
    assert (empty.get () == null);
}

void testOrElse () {
    var opt = Optional.of<string>("present");
    assert (opt.orElse ("fallback") == "present");

    var empty = Optional.empty<string> ();
    assert (empty.orElse ("fallback") == "fallback");
}

void testOrElseGet () {
    var opt = Optional.of<string>("present");
    assert (opt.orElseGet (() => { return "computed"; }) == "present");

    var empty = Optional.empty<string> ();
    assert (empty.orElseGet (() => { return "computed"; }) == "computed");
}

void testIfPresent () {
    string result = "";
    Optional.of<string>("hello").ifPresent ((v) => {
        result = v;
    });
    assert (result == "hello");

    /* Empty does not invoke the function */
    result = "unchanged";
    Optional.empty<string> ().ifPresent ((v) => {
        result = "should not happen";
    });
    assert (result == "unchanged");
}

void testFilter () {
    var opt = Optional.of<string>("hello");

    /* Matching predicate keeps the value */
    var filtered = opt.filter ((s) => { return s == "hello"; });
    assert (filtered.isPresent ());
    assert (filtered.get () == "hello");

    /* Non-matching predicate returns empty */
    var rejected = opt.filter ((s) => { return s == "world"; });
    assert (rejected.isEmpty ());

    /* Filtering empty returns empty */
    var empty = Optional.empty<string> ();
    assert (empty.filter ((s) => { return true; }).isEmpty ());
}
