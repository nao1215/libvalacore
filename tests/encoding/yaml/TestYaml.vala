using Vala.Encoding;
using Vala.Collections;
using Vala.Io;

void main (string[] args) {
    Test.init (ref args);

    // Scalar parsing
    Test.add_func ("/encoding/yaml/testParseString", testParseString);
    Test.add_func ("/encoding/yaml/testParseInt", testParseInt);
    Test.add_func ("/encoding/yaml/testParseDouble", testParseDouble);
    Test.add_func ("/encoding/yaml/testParseBool", testParseBool);
    Test.add_func ("/encoding/yaml/testParseNull", testParseNull);
    Test.add_func ("/encoding/yaml/testParseQuotedString", testParseQuotedString);
    Test.add_func ("/encoding/yaml/testParseQuotedEscapes", testParseQuotedEscapes);
    Test.add_func ("/encoding/yaml/testParseNoSpaceAfterColon", testParseNoSpaceAfterColon);

    // Mapping
    Test.add_func ("/encoding/yaml/testParseMapping", testParseMapping);
    Test.add_func ("/encoding/yaml/testParseNestedMapping", testParseNestedMapping);

    // Sequence
    Test.add_func ("/encoding/yaml/testParseSequence", testParseSequence);
    Test.add_func ("/encoding/yaml/testParseSequenceOfMappings", testParseSequenceOfMappings);
    Test.add_func ("/encoding/yaml/testParseSequenceInlineMappingNestedFlow",
                   testParseSequenceInlineMappingNestedFlow);

    // Flow style
    Test.add_func ("/encoding/yaml/testParseFlowSequence", testParseFlowSequence);
    Test.add_func ("/encoding/yaml/testParseFlowMapping", testParseFlowMapping);

    // Comments and prolog
    Test.add_func ("/encoding/yaml/testParseComments", testParseComments);
    Test.add_func ("/encoding/yaml/testParseDocumentStart", testParseDocumentStart);

    // Multi-document
    Test.add_func ("/encoding/yaml/testParseAll", testParseAll);

    // YamlValue access
    Test.add_func ("/encoding/yaml/testValueTypes", testValueTypes);
    Test.add_func ("/encoding/yaml/testMappingKeys", testMappingKeys);
    Test.add_func ("/encoding/yaml/testSequenceAt", testSequenceAt);
    Test.add_func ("/encoding/yaml/testSize", testSize);
    Test.add_func ("/encoding/yaml/testGetMissing", testGetMissing);
    Test.add_func ("/encoding/yaml/testAtOutOfRange", testAtOutOfRange);

    // Stringify
    Test.add_func ("/encoding/yaml/testStringifyMapping", testStringifyMapping);
    Test.add_func ("/encoding/yaml/testStringifySequence", testStringifySequence);
    Test.add_func ("/encoding/yaml/testStringifyPreservesEdgeWhitespace",
                   testStringifyPreservesEdgeWhitespace);

    // Query
    Test.add_func ("/encoding/yaml/testQuerySimple", testQuerySimple);
    Test.add_func ("/encoding/yaml/testQueryNested", testQueryNested);
    Test.add_func ("/encoding/yaml/testQueryArrayIndex", testQueryArrayIndex);
    Test.add_func ("/encoding/yaml/testQueryMissing", testQueryMissing);

    // File
    Test.add_func ("/encoding/yaml/testParseFile", testParseFile);
    Test.add_func ("/encoding/yaml/testParseFileMissing", testParseFileMissing);

    // Edge cases
    Test.add_func ("/encoding/yaml/testParseEmpty", testParseEmpty);
    Test.add_func ("/encoding/yaml/testParseBoolVariants", testParseBoolVariants);

    Test.run ();
}

string rootFor (string name) {
    return "%s/valacore/ut/yaml_%s_%s".printf (Environment.get_tmp_dir (),
                                               name,
                                               GLib.Uuid.string_random ());
}

void cleanup (string path) {
    FileTree.deleteTree (new Vala.Io.Path (path));
}

// --- Scalar parsing ---

void testParseString () {
    YamlValue ? root = Yaml.parse ("name: Alice");
    assert (root != null);
    assert (root.isMapping ());
    YamlValue ? name = root.get ("name");
    assert (name != null);
    assert (name.isString ());
    assert (name.asString () == "Alice");
}

void testParseInt () {
    YamlValue ? root = Yaml.parse ("age: 30");
    assert (root != null);
    YamlValue ? age = root.get ("age");
    assert (age != null);
    assert (age.isInt ());
    assert (age.asInt () == 30);
}

void testParseDouble () {
    YamlValue ? root = Yaml.parse ("pi: 3.14");
    assert (root != null);
    YamlValue ? pi = root.get ("pi");
    assert (pi != null);
    assert (pi.isDouble ());
    assert (pi.asDouble () > 3.13 && pi.asDouble () < 3.15);
}

void testParseBool () {
    YamlValue ? root = Yaml.parse ("active: true\ndisabled: false");
    assert (root != null);
    YamlValue ? active = root.get ("active");
    assert (active != null);
    assert (active.isBool ());
    assert (active.asBool () == true);

    YamlValue ? disabled = root.get ("disabled");
    assert (disabled != null);
    assert (disabled.isBool ());
    assert (disabled.asBool () == false);
}

void testParseNull () {
    YamlValue ? root = Yaml.parse ("value: null\ntilde: ~");
    assert (root != null);
    YamlValue ? val = root.get ("value");
    assert (val != null);
    assert (val.isNull ());

    YamlValue ? tilde = root.get ("tilde");
    assert (tilde != null);
    assert (tilde.isNull ());
}

void testParseQuotedString () {
    YamlValue ? root = Yaml.parse ("name: \"true\"\nnum: '42'");
    assert (root != null);
    YamlValue ? name = root.get ("name");
    assert (name != null);
    assert (name.isString ());
    assert (name.asString () == "true");

    YamlValue ? num = root.get ("num");
    assert (num != null);
    assert (num.isString ());
    assert (num.asString () == "42");
}

void testParseQuotedEscapes () {
    YamlValue ? root = Yaml.parse ("text: \"line1\\nline2\\t\\\"ok\\\"\"");
    assert (root != null);
    YamlValue ? text = root.get ("text");
    assert (text != null);
    assert (text.isString ());
    assert (text.asString () == "line1\nline2\t\"ok\"");
}

void testParseNoSpaceAfterColon () {
    YamlValue ? root = Yaml.parse ("name:Alice\nage:30");
    assert (root != null);
    assert (root.get ("name").asString () == "Alice");
    assert (root.get ("age").asInt () == 30);
}

// --- Mapping ---

void testParseMapping () {
    string yaml = "name: Alice\nage: 30\ncity: Tokyo";
    YamlValue ? root = Yaml.parse (yaml);
    assert (root != null);
    assert (root.isMapping ());
    assert (root.size () == 3);
    assert (root.get ("name").asString () == "Alice");
    assert (root.get ("age").asInt () == 30);
    assert (root.get ("city").asString () == "Tokyo");
}

void testParseNestedMapping () {
    string yaml = "server:\n  host: localhost\n  port: 8080";
    YamlValue ? root = Yaml.parse (yaml);
    assert (root != null);
    YamlValue ? server = root.get ("server");
    assert (server != null);
    assert (server.isMapping ());
    assert (server.get ("host").asString () == "localhost");
    assert (server.get ("port").asInt () == 8080);
}

// --- Sequence ---

void testParseSequence () {
    string yaml = "items:\n  - apple\n  - banana\n  - cherry";
    YamlValue ? root = Yaml.parse (yaml);
    assert (root != null);
    YamlValue ? items = root.get ("items");
    assert (items != null);
    assert (items.isSequence ());
    assert (items.size () == 3);
    assert (items.at (0).asString () == "apple");
    assert (items.at (1).asString () == "banana");
    assert (items.at (2).asString () == "cherry");
}

void testParseSequenceOfMappings () {
    string yaml = "users:\n  - name: Alice\n    age: 30\n  - name: Bob\n    age: 25";
    YamlValue ? root = Yaml.parse (yaml);
    assert (root != null);
    YamlValue ? users = root.get ("users");
    assert (users != null);
    assert (users.isSequence ());
    assert (users.size () == 2);

    YamlValue ? alice = users.at (0);
    assert (alice != null);
    assert (alice.isMapping ());
    assert (alice.get ("name").asString () == "Alice");
    assert (alice.get ("age").asInt () == 30);

    YamlValue ? bob = users.at (1);
    assert (bob != null);
    assert (bob.get ("name").asString () == "Bob");
}

void testParseSequenceInlineMappingNestedFlow () {
    string yaml = "items:\n  - cfg: [1, 2]\n    meta: {x: 1, y: 2}";
    YamlValue ? root = Yaml.parse (yaml);
    assert (root != null);
    YamlValue ? items = root.get ("items");
    assert (items != null);
    YamlValue ? first = items.at (0);
    assert (first != null);
    YamlValue ? cfg = first.get ("cfg");
    assert (cfg != null);
    assert (cfg.isSequence ());
    assert (cfg.at (1).asInt () == 2);
    YamlValue ? meta = first.get ("meta");
    assert (meta != null);
    assert (meta.isMapping ());
    assert (meta.get ("y").asInt () == 2);
}

// --- Flow style ---

void testParseFlowSequence () {
    YamlValue ? root = Yaml.parse ("tags: [a, b, c]");
    assert (root != null);
    YamlValue ? tags = root.get ("tags");
    assert (tags != null);
    assert (tags.isSequence ());
    assert (tags.size () == 3);
    assert (tags.at (0).asString () == "a");
    assert (tags.at (1).asString () == "b");
    assert (tags.at (2).asString () == "c");
}

void testParseFlowMapping () {
    YamlValue ? root = Yaml.parse ("point: {x: 1, y: 2}");
    assert (root != null);
    YamlValue ? point = root.get ("point");
    assert (point != null);
    assert (point.isMapping ());
    assert (point.get ("x").asInt () == 1);
    assert (point.get ("y").asInt () == 2);
}

// --- Comments and prolog ---

void testParseComments () {
    string yaml = "# This is a comment\nname: Alice # inline\nage: 30";
    YamlValue ? root = Yaml.parse (yaml);
    assert (root != null);
    assert (root.get ("name").asString () == "Alice");
    assert (root.get ("age").asInt () == 30);
}

void testParseDocumentStart () {
    string yaml = "---\nname: Alice\nage: 30";
    YamlValue ? root = Yaml.parse (yaml);
    assert (root != null);
    assert (root.get ("name").asString () == "Alice");
}

// --- Multi-document ---

void testParseAll () {
    string yaml = "---\nname: Alice\n---\nname: Bob";
    ArrayList<YamlValue> docs = Yaml.parseAll (yaml);
    assert (docs.size () == 2);
    assert (docs.get (0).get ("name").asString () == "Alice");
    assert (docs.get (1).get ("name").asString () == "Bob");
}

// --- YamlValue access ---

void testValueTypes () {
    string yaml = "s: hello\ni: 42\nd: 3.14\nb: true\nn: null";
    YamlValue ? root = Yaml.parse (yaml);
    assert (root != null);

    assert (root.get ("s").isString ());
    assert (root.get ("i").isInt ());
    assert (root.get ("d").isDouble ());
    assert (root.get ("b").isBool ());
    assert (root.get ("n").isNull ());
}

void testMappingKeys () {
    string yaml = "a: 1\nb: 2\nc: 3";
    YamlValue ? root = Yaml.parse (yaml);
    assert (root != null);
    ArrayList<string> ? keys = root.keys ();
    assert (keys != null);
    assert (keys.size () == 3);
    assert (keys.get (0) == "a");
    assert (keys.get (1) == "b");
    assert (keys.get (2) == "c");
}

void testSequenceAt () {
    string yaml = "items:\n  - first\n  - second";
    YamlValue ? root = Yaml.parse (yaml);
    assert (root != null);
    YamlValue ? items = root.get ("items");
    assert (items.at (0).asString () == "first");
    assert (items.at (1).asString () == "second");
}

void testSize () {
    string yaml = "map:\n  a: 1\n  b: 2\nlist:\n  - x\n  - y\n  - z";
    YamlValue ? root = Yaml.parse (yaml);
    assert (root != null);
    assert (root.get ("map").size () == 2);
    assert (root.get ("list").size () == 3);
}

void testGetMissing () {
    YamlValue ? root = Yaml.parse ("name: Alice");
    assert (root != null);
    assert (root.get ("missing") == null);
}

void testAtOutOfRange () {
    string yaml = "items:\n  - a";
    YamlValue ? root = Yaml.parse (yaml);
    assert (root != null);
    YamlValue ? items = root.get ("items");
    assert (items.at (-1) == null);
    assert (items.at (99) == null);
}

// --- Stringify ---

void testStringifyMapping () {
    YamlValue ? root = Yaml.parse ("name: Alice\nage: 30");
    assert (root != null);
    string output = Yaml.stringify (root);
    assert (output.contains ("name:"));
    assert (output.contains ("Alice"));
    assert (output.contains ("age:"));
    assert (output.contains ("30"));
}

void testStringifySequence () {
    string yaml = "items:\n  - a\n  - b";
    YamlValue ? root = Yaml.parse (yaml);
    assert (root != null);
    string output = Yaml.stringify (root);
    assert (output.contains ("items:"));
    assert (output.contains ("- a"));
    assert (output.contains ("- b"));
}

void testStringifyPreservesEdgeWhitespace () {
    YamlValue ? root = Yaml.parse ("v: \" foo \"");
    assert (root != null);
    string output = Yaml.stringify (root);
    assert (output.contains ("\" foo \""));
}

// --- Query ---

void testQuerySimple () {
    YamlValue ? root = Yaml.parse ("name: Alice");
    assert (root != null);
    YamlValue ? val = Yaml.query (root, "name");
    assert (val != null);
    assert (val.asString () == "Alice");
}

void testQueryNested () {
    string yaml = "server:\n  host: localhost\n  port: 8080";
    YamlValue ? root = Yaml.parse (yaml);
    assert (root != null);
    YamlValue ? host = Yaml.query (root, "server.host");
    assert (host != null);
    assert (host.asString () == "localhost");

    YamlValue ? port = Yaml.query (root, "server.port");
    assert (port != null);
    assert (port.asInt () == 8080);
}

void testQueryArrayIndex () {
    string yaml = "items:\n  - apple\n  - banana\n  - cherry";
    YamlValue ? root = Yaml.parse (yaml);
    assert (root != null);
    YamlValue ? first = Yaml.query (root, "items[0]");
    assert (first != null);
    assert (first.asString () == "apple");

    YamlValue ? last = Yaml.query (root, "items[2]");
    assert (last != null);
    assert (last.asString () == "cherry");
}

void testQueryMissing () {
    YamlValue ? root = Yaml.parse ("name: Alice");
    assert (root != null);
    assert (Yaml.query (root, "missing") == null);
    assert (Yaml.query (root, "a.b.c") == null);
}

// --- File ---

void testParseFile () {
    string root = rootFor ("file");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    string filePath = root + "/test.yaml";
    try {
        GLib.FileUtils.set_contents (filePath, "name: Alice\nage: 30");
    } catch (GLib.FileError e) {
        assert_not_reached ();
    }

    YamlValue ? val = Yaml.parseFile (new Vala.Io.Path (filePath));
    assert (val != null);
    assert (val.get ("name").asString () == "Alice");
    assert (val.get ("age").asInt () == 30);
    cleanup (root);
}

void testParseFileMissing () {
    YamlValue ? val = Yaml.parseFile (new Vala.Io.Path ("/tmp/valacore/ut/nonexist.yaml"));
    assert (val == null);
}

// --- Edge cases ---

void testParseEmpty () {
    YamlValue ? root = Yaml.parse ("");
    assert (root == null);
}

void testParseBoolVariants () {
    string yaml = "a: yes\nb: no\nc: Yes\nd: No\ne: on\nf: off";
    YamlValue ? root = Yaml.parse (yaml);
    assert (root != null);
    assert (root.get ("a").asBool () == true);
    assert (root.get ("b").asBool () == false);
    assert (root.get ("c").asBool () == true);
    assert (root.get ("d").asBool () == false);
    assert (root.get ("e").asBool () == true);
    assert (root.get ("f").asBool () == false);
}
