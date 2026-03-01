using Vala.Validation;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/validation/validator/testInvalidCases", testInvalidCases);
    Test.add_func ("/validation/validator/testValidCases", testValidCases);
    Test.add_func ("/validation/validator/testCustomRule", testCustomRule);

    Test.run ();
}

void testInvalidCases () {
    var validator = new Validator ();
    validator.required ("name", "")
     .minLength ("name", "ab", 3)
     .maxLength ("nickname", "too-long", 4)
     .range ("age", 130, 0, 120)
     .pattern ("code", "abc", "^[0-9]+$")
     .email ("email", "invalid-address")
     .url ("site", "ftp://example.com");

    ValidationResult result = validator.validate ();
    assert (result.isValid () == false);
    assert (result.errors ().size () == 7);
    assert (result.errorsByField ("name").size () == 2);
    assert (result.firstError () != null);
    assert (result.errorMessages ().size () == 7);
}

void testValidCases () {
    var validator = new Validator ();
    validator.required ("name", "Alice")
     .minLength ("name", "Alice", 3)
     .maxLength ("name", "Alice", 10)
     .range ("age", 20, 0, 120)
     .pattern ("code", "12345", "^[0-9]+$")
     .email ("email", "alice@example.com")
     .url ("site", "https://example.com/path");

    ValidationResult result = validator.validate ();
    assert (result.isValid () == true);
    assert (result.errors ().size () == 0);
    assert (result.firstError () == null);
}

void testCustomRule () {
    var validator = new Validator ();
    validator.required ("token", "abc-001")
     .custom ("token", (value) => {
        return value != null && value.has_prefix ("abc");
    }, "token must start with abc")
     .custom ("token", (value) => {
        return value != null && value.has_suffix ("xyz");
    }, "token must end with xyz");

    ValidationResult result = validator.validate ();
    assert (result.isValid () == false);
    assert (result.errors ().size () == 1);
    assert (result.firstError ().field () == "token");
    assert (result.firstError ().message () == "token must end with xyz");
}
