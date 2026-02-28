using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/testOk", testOk);
    Test.add_func ("/testError", testError);
    Test.add_func ("/testIsOk", testIsOk);
    Test.add_func ("/testIsError", testIsError);
    Test.add_func ("/testUnwrap", testUnwrap);
    Test.add_func ("/testUnwrapOr", testUnwrapOr);
    Test.add_func ("/testUnwrapError", testUnwrapError);
    Test.add_func ("/testMap", testMap);
    Test.add_func ("/testMapError", testMapError);
    Test.run ();
}

void testOk () {
    var r = Result.ok<string, string>("data");
    assert (r.isOk ());
    assert (r.unwrap () == "data");
}

void testError () {
    var r = Result.error<string, string>("not found");
    assert (r.isError ());
    assert (r.unwrapError () == "not found");
}

void testIsOk () {
    assert (Result.ok<string, string>("x").isOk () == true);
    assert (Result.error<string, string>("e").isOk () == false);
}

void testIsError () {
    assert (Result.ok<string, string>("x").isError () == false);
    assert (Result.error<string, string>("e").isError () == true);
}

void testUnwrap () {
    /* Success returns value */
    var ok = Result.ok<string, string>("value");
    assert (ok.unwrap () == "value");

    /* Error returns null */
    var err = Result.error<string, string>("oops");
    assert (err.unwrap () == null);
}

void testUnwrapOr () {
    var ok = Result.ok<string, string>("present");
    assert (ok.unwrapOr ("fallback") == "present");

    var err = Result.error<string, string>("oops");
    assert (err.unwrapOr ("fallback") == "fallback");
}

void testUnwrapError () {
    /* Error returns error value */
    var err = Result.error<string, string>("not found");
    assert (err.unwrapError () == "not found");

    /* Success returns null for error */
    var ok = Result.ok<string, string>("data");
    assert (ok.unwrapError () == null);
}

void testMap () {
    /* Map over success */
    var ok = Result.ok<string, string>("hello");
    var mapped = ok.map<string>((s) => { return s.up (); });
    assert (mapped.isOk ());
    assert (mapped.unwrap () == "HELLO");

    /* Map over error does not invoke function */
    var err = Result.error<string, string>("oops");
    var mappedErr = err.map<string>((s) => { return s.up (); });
    assert (mappedErr.isError ());
    assert (mappedErr.unwrapError () == "oops");
}

void testMapError () {
    /* Map error over error */
    var err = Result.error<string, string>("err");
    var mapped = err.mapError<string>((e) => { return e.up (); });
    assert (mapped.isError ());
    assert (mapped.unwrapError () == "ERR");

    /* Map error over success does not invoke function */
    var ok = Result.ok<string, string>("data");
    var mappedOk = ok.mapError<string>((e) => { return e.up (); });
    assert (mappedOk.isOk ());
    assert (mappedOk.unwrap () == "data");
}
