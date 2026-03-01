using Vala.Encoding;
using Vala.Io;
using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);

    // JsonValue factory and type checks
    Test.add_func ("/encoding/json/testOfString", testOfString);
    Test.add_func ("/encoding/json/testOfInt", testOfInt);
    Test.add_func ("/encoding/json/testOfDouble", testOfDouble);
    Test.add_func ("/encoding/json/testOfBool", testOfBool);
    Test.add_func ("/encoding/json/testOfNull", testOfNull);

    // JsonValue object/array builders
    Test.add_func ("/encoding/json/testObjectBuilder", testObjectBuilder);
    Test.add_func ("/encoding/json/testObjectBuilderSnapshot", testObjectBuilderSnapshot);
    Test.add_func ("/encoding/json/testArrayBuilder", testArrayBuilder);
    Test.add_func ("/encoding/json/testArrayBuilderSnapshot", testArrayBuilderSnapshot);

    // JsonValue access
    Test.add_func ("/encoding/json/testGetAndAt", testGetAndAt);
    Test.add_func ("/encoding/json/testKeysAndSize", testKeysAndSize);
    Test.add_func ("/encoding/json/testToList", testToList);
    Test.add_func ("/encoding/json/testEquals", testEquals);
    Test.add_func ("/encoding/json/testFallbackGetters", testFallbackGetters);

    // Json parse
    Test.add_func ("/encoding/json/testParseString", testParseString);
    Test.add_func ("/encoding/json/testParseNumber", testParseNumber);
    Test.add_func ("/encoding/json/testParseBool", testParseBool);
    Test.add_func ("/encoding/json/testParseNull", testParseNull);
    Test.add_func ("/encoding/json/testParseObject", testParseObject);
    Test.add_func ("/encoding/json/testParseArray", testParseArray);
    Test.add_func ("/encoding/json/testParseNested", testParseNested);
    Test.add_func ("/encoding/json/testParseEscapes", testParseEscapes);
    Test.add_func ("/encoding/json/testParseWhitespace", testParseWhitespace);
    Test.add_func ("/encoding/json/testParseInvalid", testParseInvalid);

    // Json parseFile
    Test.add_func ("/encoding/json/testParseFile", testParseFile);

    // Json stringify and pretty
    Test.add_func ("/encoding/json/testStringify", testStringify);
    Test.add_func ("/encoding/json/testPretty", testPretty);

    // Json query
    Test.add_func ("/encoding/json/testQuery", testQuery);
    Test.add_func ("/encoding/json/testQueryArray", testQueryArray);
    Test.add_func ("/encoding/json/testQueryDeep", testQueryDeep);

    // Json convenience getters
    Test.add_func ("/encoding/json/testGetString", testGetString);
    Test.add_func ("/encoding/json/testGetInt", testGetInt);
    Test.add_func ("/encoding/json/testGetBool", testGetBool);
    Test.add_func ("/encoding/json/testMust", testMust);
    Test.add_func ("/encoding/json/testMustMissing", testMustMissing);

    // Json set, remove, merge, diff, flatten
    Test.add_func ("/encoding/json/testSet", testSet);
    Test.add_func ("/encoding/json/testRemove", testRemove);
    Test.add_func ("/encoding/json/testMerge", testMerge);
    Test.add_func ("/encoding/json/testDiff", testDiff);
    Test.add_func ("/encoding/json/testFlatten", testFlatten);

    // Edge cases
    Test.add_func ("/encoding/json/testEmptyObjectAndArray", testEmptyObjectAndArray);
    Test.add_func ("/encoding/json/testParseUnicode", testParseUnicode);
    Test.add_func ("/encoding/json/testRoundTrip", testRoundTrip);

    Test.run ();
}

string rootFor (string name) {
    return "%s/valacore/ut/json_%s_%s".printf (Environment.get_tmp_dir (), name, GLib.Uuid.string_random ());
}

void cleanup (string path) {
    FileTree.deleteTree (new Vala.Io.Path (path));
}

// --- JsonValue factory and type checks ---

void testOfString () {
    var v = JsonValue.ofString ("hello");
    assert (v.isString ());
    assert (!v.isNumber ());
    assert (!v.isBool ());
    assert (!v.isNull ());
    assert (!v.isObject ());
    assert (!v.isArray ());
    assert (v.asString () == "hello");
    assert (v.asInt () == null);
}

void testOfInt () {
    var v = JsonValue.ofInt (42);
    assert (v.isNumber ());
    assert (!v.isString ());
    int ? i = v.asInt ();
    assert (i != null && i == 42);
    double ? d = v.asDouble ();
    assert (d != null && d == 42.0);
}

void testOfDouble () {
    var v = JsonValue.ofDouble (3.14);
    assert (v.isNumber ());
    double ? d = v.asDouble ();
    assert (d != null && (d - 3.14).abs () < 0.001);
    int ? i = v.asInt ();
    assert (i != null && i == 3);
}

void testOfBool () {
    var t = JsonValue.ofBool (true);
    var f = JsonValue.ofBool (false);
    assert (t.isBool ());
    assert (f.isBool ());
    bool ? bt = t.asBool ();
    bool ? bf = f.asBool ();
    assert (bt != null && bt == true);
    assert (bf != null && bf == false);
}

void testOfNull () {
    var v = JsonValue.ofNull ();
    assert (v.isNull ());
    assert (!v.isString ());
    assert (v.asString () == null);
    assert (v.asInt () == null);
}

// --- Builders ---

void testObjectBuilder () {
    var obj = JsonValue.object ()
               .put ("name", JsonValue.ofString ("Alice"))
               .put ("age", JsonValue.ofInt (30))
               .build ();
    assert (obj.isObject ());
    assert (obj.size () == 2);

    JsonValue ? name = obj.get ("name");
    assert (name != null);
    if (name != null) {
        assert (name.asString () == "Alice");
    }
}

void testObjectBuilderSnapshot () {
    var builder = JsonValue.object ().put ("a", JsonValue.ofInt (1));
    JsonValue first = builder.build ();
    JsonValue second = builder.put ("b", JsonValue.ofInt (2)).build ();

    assert (first.isObject ());
    assert (first.get ("a") != null);
    assert (first.get ("b") == null);
    assert (second.get ("a") == null);
    assert (second.get ("b") != null);
}

void testArrayBuilder () {
    var arr = JsonValue.array ()
               .add (JsonValue.ofInt (1))
               .add (JsonValue.ofInt (2))
               .add (JsonValue.ofInt (3))
               .build ();
    assert (arr.isArray ());
    assert (arr.size () == 3);

    JsonValue ? second = arr.at (1);
    assert (second != null);
    if (second != null) {
        int ? i = second.asInt ();
        assert (i != null && i == 2);
    }
}

void testArrayBuilderSnapshot () {
    var builder = JsonValue.array ().add (JsonValue.ofInt (1));
    JsonValue first = builder.build ();
    JsonValue second = builder.add (JsonValue.ofInt (2)).build ();

    assert (first.isArray ());
    assert (first.size () == 1);
    assert (first.at (0).asInt () == 1);
    assert (second.size () == 1);
    assert (second.at (0).asInt () == 2);
}

// --- Access ---

void testGetAndAt () {
    var obj = JsonValue.object ()
               .put ("key", JsonValue.ofString ("val"))
               .build ();
    assert (obj.get ("key") != null);
    assert (obj.get ("missing") == null);

    var arr = JsonValue.array ()
               .add (JsonValue.ofString ("a"))
               .build ();
    assert (arr.at (0) != null);
    assert (arr.at (5) == null);
    assert (arr.at (-1) == null);
}

void testKeysAndSize () {
    var obj = JsonValue.object ()
               .put ("a", JsonValue.ofInt (1))
               .put ("b", JsonValue.ofInt (2))
               .build ();
    ArrayList<string> ? k = obj.keys ();
    assert (k != null);
    if (k != null) {
        assert (k.size () == 2);
    }
    assert (obj.size () == 2);

    assert (JsonValue.ofString ("x").size () == 0);
    assert (JsonValue.ofString ("x").keys () == null);
}

void testToList () {
    var arr = JsonValue.array ()
               .add (JsonValue.ofInt (10))
               .add (JsonValue.ofInt (20))
               .build ();
    ArrayList<JsonValue> ? list = arr.toList ();
    assert (list != null);
    if (list != null) {
        assert (list.size () == 2);
    }
    assert (JsonValue.ofNull ().toList () == null);
}

void testEquals () {
    assert (JsonValue.ofString ("a").equals (JsonValue.ofString ("a")));
    assert (!JsonValue.ofString ("a").equals (JsonValue.ofString ("b")));
    assert (JsonValue.ofInt (1).equals (JsonValue.ofInt (1)));
    assert (!JsonValue.ofInt (1).equals (JsonValue.ofInt (2)));
    assert (JsonValue.ofBool (true).equals (JsonValue.ofBool (true)));
    assert (!JsonValue.ofBool (true).equals (JsonValue.ofBool (false)));
    assert (JsonValue.ofNull ().equals (JsonValue.ofNull ()));
    assert (!JsonValue.ofNull ().equals (JsonValue.ofInt (0)));

    var obj1 = JsonValue.object ().put ("k", JsonValue.ofInt (1)).build ();
    var obj2 = JsonValue.object ().put ("k", JsonValue.ofInt (1)).build ();
    var obj3 = JsonValue.object ().put ("k", JsonValue.ofInt (2)).build ();
    assert (obj1.equals (obj2));
    assert (!obj1.equals (obj3));

    var arr1 = JsonValue.array ().add (JsonValue.ofInt (1)).build ();
    var arr2 = JsonValue.array ().add (JsonValue.ofInt (1)).build ();
    var arr3 = JsonValue.array ().add (JsonValue.ofInt (2)).build ();
    assert (arr1.equals (arr2));
    assert (!arr1.equals (arr3));
}

void testFallbackGetters () {
    var v = JsonValue.ofString ("hello");
    assert (v.asStringOr ("x") == "hello");
    assert (v.asIntOr (99) == 99);

    var n = JsonValue.ofInt (5);
    assert (n.asIntOr (0) == 5);
    assert (n.asStringOr ("x") == "x");
}

// --- Parse ---

void testParseString () {
    JsonValue ? v = Json.parse ("\"hello world\"");
    assert (v != null);
    if (v != null) {
        assert (v.isString ());
        assert (v.asString () == "hello world");
    }
}

void testParseNumber () {
    JsonValue ? v1 = Json.parse ("42");
    assert (v1 != null);
    if (v1 != null) {
        assert (v1.isNumber ());
        int ? i = v1.asInt ();
        assert (i != null && i == 42);
    }

    JsonValue ? v2 = Json.parse ("-3.14");
    assert (v2 != null);
    if (v2 != null) {
        assert (v2.isNumber ());
        double ? d = v2.asDouble ();
        assert (d != null && (d + 3.14).abs () < 0.001);
    }

    JsonValue ? v3 = Json.parse ("1.5e2");
    assert (v3 != null);
    if (v3 != null) {
        double ? d = v3.asDouble ();
        assert (d != null && (d - 150.0).abs () < 0.001);
    }
}

void testParseBool () {
    JsonValue ? t = Json.parse ("true");
    assert (t != null && t.isBool ());
    if (t != null) {
        bool ? b = t.asBool ();
        assert (b != null && b == true);
    }

    JsonValue ? f = Json.parse ("false");
    assert (f != null && f.isBool ());
    if (f != null) {
        bool ? b = f.asBool ();
        assert (b != null && b == false);
    }
}

void testParseNull () {
    JsonValue ? v = Json.parse ("null");
    assert (v != null);
    if (v != null) {
        assert (v.isNull ());
    }
}

void testParseObject () {
    JsonValue ? v = Json.parse ("{\"name\": \"Alice\", \"age\": 30}");
    assert (v != null);
    if (v == null) {
        return;
    }
    assert (v.isObject ());
    assert (v.size () == 2);

    JsonValue ? name = v.get ("name");
    assert (name != null && name.asString () == "Alice");

    JsonValue ? age = v.get ("age");
    assert (age != null);
    if (age != null) {
        int ? a = age.asInt ();
        assert (a != null && a == 30);
    }
}

void testParseArray () {
    JsonValue ? v = Json.parse ("[1, 2, 3]");
    assert (v != null);
    if (v == null) {
        return;
    }
    assert (v.isArray ());
    assert (v.size () == 3);

    JsonValue ? first = v.at (0);
    assert (first != null);
    if (first != null) {
        int ? i = first.asInt ();
        assert (i != null && i == 1);
    }
}

void testParseNested () {
    string json = "{\"user\": {\"name\": \"Bob\", \"scores\": [90, 85, 100]}}";
    JsonValue ? v = Json.parse (json);
    assert (v != null);
    if (v == null) {
        return;
    }

    JsonValue ? user = v.get ("user");
    assert (user != null && user.isObject ());
    if (user == null) {
        return;
    }

    JsonValue ? name = user.get ("name");
    assert (name != null && name.asString () == "Bob");

    JsonValue ? scores = user.get ("scores");
    assert (scores != null && scores.isArray ());
    if (scores != null) {
        assert (scores.size () == 3);
    }
}

void testParseEscapes () {
    JsonValue ? v = Json.parse ("\"hello\\nworld\\t!\"");
    assert (v != null);
    if (v != null) {
        assert (v.asString () == "hello\nworld\t!");
    }

    JsonValue ? v2 = Json.parse ("\"quote: \\\"ok\\\"\"");
    assert (v2 != null);
    if (v2 != null) {
        assert (v2.asString () == "quote: \"ok\"");
    }

    JsonValue ? v3 = Json.parse ("\"back\\\\slash\"");
    assert (v3 != null);
    if (v3 != null) {
        assert (v3.asString () == "back\\slash");
    }
}

void testParseWhitespace () {
    JsonValue ? v = Json.parse ("  {  \"a\" :  1  }  ");
    assert (v != null);
    if (v != null) {
        assert (v.isObject ());
    }
}

void testParseInvalid () {
    assert (Json.parse ("") == null);
    assert (Json.parse ("{") == null);
    assert (Json.parse ("[1,]") == null);
    assert (Json.parse ("{\"a\":}") == null);
    assert (Json.parse ("{\"a\" \"b\"}") == null);
    assert (Json.parse ("undefined") == null);
}

// --- parseFile ---

void testParseFile () {
    string root = rootFor ("file");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var path = new Vala.Io.Path (root + "/data.json");
    assert (Files.writeText (path, "{\"x\": 10}"));

    JsonValue ? v = Json.parseFile (path);
    assert (v != null);
    if (v != null) {
        assert (Json.getInt (v, "$.x", 0) == 10);
    }

    assert (Json.parseFile (new Vala.Io.Path (root + "/missing.json")) == null);
    cleanup (root);
}

// --- stringify and pretty ---

void testStringify () {
    var obj = JsonValue.object ()
               .put ("a", JsonValue.ofInt (1))
               .put ("b", JsonValue.ofString ("hello"))
               .build ();
    string s = Json.stringify (obj);
    // Verify round-trip
    JsonValue ? parsed = Json.parse (s);
    assert (parsed != null);
    if (parsed != null) {
        assert (Json.getInt (parsed, "$.a", 0) == 1);
        assert (Json.getString (parsed, "$.b", "") == "hello");
    }
}

void testPretty () {
    var obj = JsonValue.object ()
               .put ("name", JsonValue.ofString ("test"))
               .build ();
    string pretty = Json.pretty (obj, 2);
    assert (pretty.contains ("\n"));
    assert (pretty.contains ("  "));

    // Verify round-trip
    JsonValue ? parsed = Json.parse (pretty);
    assert (parsed != null);
}

// --- query ---

void testQuery () {
    JsonValue ? root = Json.parse ("{\"name\": \"Alice\", \"age\": 30}");
    assert (root != null);
    if (root == null) {
        return;
    }

    JsonValue ? name = Json.query (root, "$.name");
    assert (name != null && name.asString () == "Alice");

    JsonValue ? age = Json.query (root, "$.age");
    assert (age != null);
    if (age != null) {
        int ? a = age.asInt ();
        assert (a != null && a == 30);
    }

    assert (Json.query (root, "$.missing") == null);
}

void testQueryArray () {
    JsonValue ? root = Json.parse ("{\"items\": [10, 20, 30]}");
    assert (root != null);
    if (root == null) {
        return;
    }

    JsonValue ? second = Json.query (root, "$.items[1]");
    assert (second != null);
    if (second != null) {
        int ? i = second.asInt ();
        assert (i != null && i == 20);
    }
}

void testQueryDeep () {
    string json = "{\"users\": [{\"name\": \"Bob\", \"address\": {\"city\": \"Tokyo\"}}]}";
    JsonValue ? root = Json.parse (json);
    assert (root != null);
    if (root == null) {
        return;
    }

    JsonValue ? city = Json.query (root, "$.users[0].address.city");
    assert (city != null && city.asString () == "Tokyo");
}

// --- convenience getters ---

void testGetString () {
    JsonValue ? root = Json.parse ("{\"msg\": \"hello\"}");
    assert (root != null);
    if (root == null) {
        return;
    }
    assert (Json.getString (root, "$.msg", "x") == "hello");
    assert (Json.getString (root, "$.missing", "fallback") == "fallback");
    assert (Json.getString (root, "$.missing") == "");
}

void testGetInt () {
    JsonValue ? root = Json.parse ("{\"count\": 42}");
    assert (root != null);
    if (root == null) {
        return;
    }
    assert (Json.getInt (root, "$.count", 0) == 42);
    assert (Json.getInt (root, "$.missing", 99) == 99);
    assert (Json.getInt (root, "$.missing") == 0);
}

void testGetBool () {
    JsonValue ? root = Json.parse ("{\"active\": true}");
    assert (root != null);
    if (root == null) {
        return;
    }
    assert (Json.getBool (root, "$.active", false) == true);
    assert (Json.getBool (root, "$.missing", false) == false);
    assert (Json.getBool (root, "$.missing") == false);
}

void testMust () {
    JsonValue ? root = Json.parse ("{\"user\":{\"id\":123}}");
    assert (root != null);
    if (root == null) {
        return;
    }
    try {
        JsonValue v = Json.must (root, "$.user.id");
        int ? id = v.asInt ();
        assert (id != null && id == 123);
    } catch (JsonError e) {
        assert_not_reached ();
    }
}

void testMustMissing () {
    JsonValue ? root = Json.parse ("{\"user\":{\"id\":123}}");
    assert (root != null);
    if (root == null) {
        return;
    }

    bool missingThrown = false;
    try {
        Json.must (root, "$.user.missing");
    } catch (JsonError e) {
        missingThrown = true;
        assert (e is JsonError.NOT_FOUND);
    }
    assert (missingThrown);

    bool emptyPathThrown = false;
    try {
        Json.must (root, " ");
    } catch (JsonError e) {
        emptyPathThrown = true;
        assert (e is JsonError.INVALID_PATH);
    }
    assert (emptyPathThrown);

    bool malformedPathThrown = false;
    try {
        Json.must (root, "$.user[abc]");
    } catch (JsonError e) {
        malformedPathThrown = true;
        assert (e is JsonError.INVALID_PATH);
    }
    assert (malformedPathThrown);
}

// --- set, remove, merge, flatten ---

void testSet () {
    JsonValue ? root = Json.parse ("{\"a\": 1}");
    assert (root != null);
    if (root == null) {
        return;
    }

    JsonValue ? updated = Json.set (root, "$.b", JsonValue.ofInt (2));
    assert (updated != null);
    if (updated != null) {
        assert (Json.getInt (updated, "$.a", 0) == 1);
        assert (Json.getInt (updated, "$.b", 0) == 2);
    }
    // Original is unchanged (immutable)
    assert (Json.query (root, "$.b") == null);
}

void testRemove () {
    JsonValue ? root = Json.parse ("{\"a\": 1, \"b\": 2}");
    assert (root != null);
    if (root == null) {
        return;
    }

    JsonValue ? removed = Json.remove (root, "$.a");
    assert (removed != null);
    if (removed != null) {
        assert (Json.query (removed, "$.a") == null);
        assert (Json.getInt (removed, "$.b", 0) == 2);
    }
    // Original is unchanged
    assert (Json.query (root, "$.a") != null);
}

void testMerge () {
    JsonValue ? a = Json.parse ("{\"x\": 1, \"y\": 2}");
    JsonValue ? b = Json.parse ("{\"y\": 3, \"z\": 4}");
    assert (a != null && b != null);
    if (a == null || b == null) {
        return;
    }

    JsonValue ? merged = Json.merge (a, b);
    assert (merged != null);
    if (merged != null) {
        assert (Json.getInt (merged, "$.x", 0) == 1);
        assert (Json.getInt (merged, "$.y", 0) == 3);
        assert (Json.getInt (merged, "$.z", 0) == 4);
    }
}

void testDiff () {
    JsonValue ? a = Json.parse ("{\"name\":\"Alice\",\"age\":20,\"tags\":[\"a\",\"b\"]}");
    JsonValue ? b = Json.parse ("{\"name\":\"Alice\",\"age\":21,\"tags\":[\"a\",\"c\"],\"active\":true}");
    assert (a != null && b != null);
    if (a == null || b == null) {
        return;
    }

    JsonValue diff = Json.diff (a, b);
    assert (diff.isArray ());
    assert (diff.size () == 3);

    // Check that expected changed paths exist in diff output.
    bool hasAge = false;
    bool hasTag = false;
    bool hasActive = false;
    for (int i = 0; i < diff.size (); i++) {
        JsonValue ? entry = diff.at (i);
        if (entry == null) {
            continue;
        }
        string path = Json.getString (entry, "$.path", "");
        if (path == "$.age") {
            hasAge = true;
        } else if (path == "$.tags[1]") {
            hasTag = true;
        } else if (path == "$.active") {
            hasActive = true;
        }
    }
    assert (hasAge);
    assert (hasTag);
    assert (hasActive);
}

void testFlatten () {
    JsonValue ? root = Json.parse ("{\"a\": {\"b\": {\"c\": 1}}, \"d\": 2}");
    assert (root != null);
    if (root == null) {
        return;
    }

    HashMap<string, JsonValue> ? flat = Json.flatten (root);
    assert (flat != null);
    if (flat != null) {
        JsonValue ? c = flat.get ("a.b.c");
        assert (c != null);
        if (c != null) {
            int ? i = c.asInt ();
            assert (i != null && i == 1);
        }

        JsonValue ? d = flat.get ("d");
        assert (d != null);
        if (d != null) {
            int ? i = d.asInt ();
            assert (i != null && i == 2);
        }
    }
}

// --- Edge cases ---

void testEmptyObjectAndArray () {
    JsonValue ? obj = Json.parse ("{}");
    assert (obj != null && obj.isObject ());
    if (obj != null) {
        assert (obj.size () == 0);
    }

    JsonValue ? arr = Json.parse ("[]");
    assert (arr != null && arr.isArray ());
    if (arr != null) {
        assert (arr.size () == 0);
    }
}

void testParseUnicode () {
    JsonValue ? v = Json.parse ("\"hello \\u0041\"");
    assert (v != null);
    if (v != null) {
        assert (v.asString () == "hello A");
    }
}

void testRoundTrip () {
    string original = "{\"users\":[{\"name\":\"Alice\",\"age\":30},{\"name\":\"Bob\",\"age\":25}],\"count\":2}";
    JsonValue ? parsed = Json.parse (original);
    assert (parsed != null);
    if (parsed == null) {
        return;
    }

    string output = Json.stringify (parsed);
    JsonValue ? reparsed = Json.parse (output);
    assert (reparsed != null);
    if (reparsed != null) {
        assert (parsed.equals (reparsed));
    }
}
