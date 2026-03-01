using Vala.Encoding;
using Vala.Io;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/encoding/toml/testParseAndGet", testParseAndGet);
    Test.add_func ("/encoding/toml/testParseFile", testParseFile);
    Test.add_func ("/encoding/toml/testStringify", testStringify);
    Test.add_func ("/encoding/toml/testInvalid", testInvalid);
    Test.add_func ("/encoding/toml/testFallback", testFallback);
    Test.run ();
}

string rootFor (string name) {
    return "/tmp/valacore/ut/toml_" + name;
}

void cleanup (string path) {
    FileTree.deleteTree (new Vala.Io.Path (path));
}

void testParseAndGet () {
    string text = """
title = "App"
[server]
port = 8080
enabled = true
""";

    TomlValue ? root = Toml.parse (text);
    assert (root != null);
    if (root == null) {
        return;
    }

    assert (Toml.getStringOr (root, "title", "") == "App");
    assert (Toml.getIntOr (root, "server.port", 0) == 8080);

    TomlValue ? enabled = Toml.get (root, "server.enabled");
    assert (enabled != null);
    if (enabled == null) {
        return;
    }
    bool ? b = enabled.asBool ();
    assert (b != null && b);
}

void testParseFile () {
    string root = rootFor ("file");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var path = new Vala.Io.Path (root + "/config.toml");
    assert (Files.writeText (path, "[db]\nport = 5432\n"));

    TomlValue ? parsed = Toml.parseFile (path);
    assert (parsed != null);
    if (parsed == null) {
        cleanup (root);
        return;
    }
    assert (Toml.getIntOr (parsed, "db.port", 0) == 5432);
    cleanup (root);
}

void testStringify () {
    string source = """
name = "service"
[db]
host = "localhost"
port = 3306
""";

    TomlValue ? parsed = Toml.parse (source);
    assert (parsed != null);
    if (parsed == null) {
        return;
    }

    string output = Toml.stringify (parsed);
    TomlValue ? parsedAgain = Toml.parse (output);
    assert (parsedAgain != null);
    if (parsedAgain == null) {
        return;
    }

    assert (Toml.getStringOr (parsedAgain, "name", "") == "service");
    assert (Toml.getStringOr (parsedAgain, "db.host", "") == "localhost");
    assert (Toml.getIntOr (parsedAgain, "db.port", 0) == 3306);
}

void testInvalid () {
    assert (Toml.parse ("invalid-line") == null);
    assert (Toml.parse ("[a\nx = 1") == null);
    assert (Toml.parse ("x = ") == null);
}

void testFallback () {
    TomlValue ? parsed = Toml.parse ("[x]\nname = \"ok\"\n");
    assert (parsed != null);
    if (parsed == null) {
        return;
    }

    assert (Toml.getStringOr (parsed, "x.name", "ng") == "ok");
    assert (Toml.getStringOr (parsed, "x.missing", "fallback") == "fallback");
    assert (Toml.getIntOr (parsed, "x.name", 99) == 99);
    assert (Toml.getIntOr (parsed, "x.missing", 123) == 123);
}
