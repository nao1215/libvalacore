using Vala.Text;
using Vala.Collections;
using Vala.Encoding;
using Vala.Io;

void main (string[] args) {
    Test.init (ref args);

    // Basic variable substitution
    Test.add_func ("/text/template/testSimpleVariable", testSimpleVariable);
    Test.add_func ("/text/template/testMultipleVariables", testMultipleVariables);
    Test.add_func ("/text/template/testMissingVariable", testMissingVariable);
    Test.add_func ("/text/template/testNoVariables", testNoVariables);
    Test.add_func ("/text/template/testEmptyTemplate", testEmptyTemplate);

    // Conditionals
    Test.add_func ("/text/template/testIfTrue", testIfTrue);
    Test.add_func ("/text/template/testIfFalse", testIfFalse);
    Test.add_func ("/text/template/testIfElseTrue", testIfElseTrue);
    Test.add_func ("/text/template/testIfElseFalse", testIfElseFalse);
    Test.add_func ("/text/template/testIfMissing", testIfMissing);
    Test.add_func ("/text/template/testIfFalseString", testIfFalseString);
    Test.add_func ("/text/template/testIfZeroString", testIfZeroString);

    // Loops
    Test.add_func ("/text/template/testEachLoop", testEachLoop);
    Test.add_func ("/text/template/testEachEmpty", testEachEmpty);
    Test.add_func ("/text/template/testEachMissing", testEachMissing);

    // Filters
    Test.add_func ("/text/template/testFilterUpper", testFilterUpper);
    Test.add_func ("/text/template/testFilterLower", testFilterLower);
    Test.add_func ("/text/template/testFilterTrim", testFilterTrim);
    Test.add_func ("/text/template/testFilterEscape", testFilterEscape);
    Test.add_func ("/text/template/testFilterUnknown", testFilterUnknown);

    // Fallback
    Test.add_func ("/text/template/testFallbackUsed", testFallbackUsed);
    Test.add_func ("/text/template/testFallbackNotUsed", testFallbackNotUsed);

    // Compile and reuse
    Test.add_func ("/text/template/testCompileReuse", testCompileReuse);

    // renderFile
    Test.add_func ("/text/template/testRenderFile", testRenderFile);
    Test.add_func ("/text/template/testRenderFileMissing", testRenderFileMissing);

    // renderJson
    Test.add_func ("/text/template/testRenderJson", testRenderJson);
    Test.add_func ("/text/template/testRenderJsonArray", testRenderJsonArray);
    Test.add_func ("/text/template/testCompiledRenderJson", testCompiledRenderJson);

    // Edge cases
    Test.add_func ("/text/template/testUnclosedTag", testUnclosedTag);
    Test.add_func ("/text/template/testNestedIf", testNestedIf);
    Test.add_func ("/text/template/testComplexTemplate", testComplexTemplate);

    Test.run ();
}

string rootFor (string name) {
    return "/tmp/valacore/ut/template_" + name;
}

void cleanup (string path) {
    Posix.system ("rm -rf " + path);
}

// --- Basic variable substitution ---

void testSimpleVariable () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("name", "World");
    string result = Template.render ("Hello, {{name}}!", vars);
    assert (result == "Hello, World!");
}

void testMultipleVariables () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("first", "John");
    vars.put ("last", "Doe");
    string result = Template.render ("{{first}} {{last}}", vars);
    assert (result == "John Doe");
}

void testMissingVariable () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    string result = Template.render ("Hello, {{name}}!", vars);
    assert (result == "Hello, !");
}

void testNoVariables () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    string result = Template.render ("Plain text", vars);
    assert (result == "Plain text");
}

void testEmptyTemplate () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    string result = Template.render ("", vars);
    assert (result == "");
}

// --- Conditionals ---

void testIfTrue () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("show", "yes");
    string result = Template.render ("{{#if show}}Visible{{/if}}", vars);
    assert (result == "Visible");
}

void testIfFalse () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("show", "");
    string result = Template.render ("{{#if show}}Visible{{/if}}", vars);
    assert (result == "");
}

void testIfElseTrue () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("premium", "yes");
    string result = Template.render (
        "{{#if premium}}Premium{{else}}Free{{/if}}", vars);
    assert (result == "Premium");
}

void testIfElseFalse () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    string result = Template.render (
        "{{#if premium}}Premium{{else}}Free{{/if}}", vars);
    assert (result == "Free");
}

void testIfMissing () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    string result = Template.render ("{{#if missing}}Yes{{/if}}", vars);
    assert (result == "");
}

void testIfFalseString () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("flag", "false");
    string result = Template.render ("{{#if flag}}Yes{{else}}No{{/if}}", vars);
    assert (result == "No");
}

void testIfZeroString () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("flag", "0");
    string result = Template.render ("{{#if flag}}Yes{{else}}No{{/if}}", vars);
    assert (result == "No");
}

// --- Loops ---

void testEachLoop () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("items", "a,b,c");
    string result = Template.render ("{{#each items}}[{{.}}]{{/each}}", vars);
    assert (result == "[a][b][c]");
}

void testEachEmpty () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("items", "");
    string result = Template.render ("{{#each items}}[{{.}}]{{/each}}", vars);
    assert (result == "");
}

void testEachMissing () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    string result = Template.render ("{{#each items}}[{{.}}]{{/each}}", vars);
    assert (result == "");
}

// --- Filters ---

void testFilterUpper () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("name", "world");
    string result = Template.render ("{{name | upper}}", vars);
    assert (result == "WORLD");
}

void testFilterLower () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("name", "WORLD");
    string result = Template.render ("{{name | lower}}", vars);
    assert (result == "world");
}

void testFilterTrim () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("name", "  hello  ");
    string result = Template.render ("{{name | trim}}", vars);
    assert (result == "hello");
}

void testFilterEscape () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("html", "<b>bold & \"quoted\"</b>");
    string result = Template.render ("{{html | escape}}", vars);
    assert (result == "&lt;b&gt;bold &amp; &quot;quoted&quot;&lt;/b&gt;");
}

void testFilterUnknown () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("name", "World");
    string result = Template.render ("{{name | unknown}}", vars);
    assert (result == "World");
}

// --- Fallback ---

void testFallbackUsed () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    string result = Template.render ("{{fallback name \"Anonymous\"}}", vars);
    assert (result == "Anonymous");
}

void testFallbackNotUsed () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("name", "Alice");
    string result = Template.render ("{{fallback name \"Anonymous\"}}", vars);
    assert (result == "Alice");
}

// --- Compile and reuse ---

void testCompileReuse () {
    var tmpl = Template.compile ("Hello, {{name}}!");

    var v1 = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    v1.put ("name", "Alice");
    assert (tmpl.render (v1) == "Hello, Alice!");

    var v2 = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    v2.put ("name", "Bob");
    assert (tmpl.render (v2) == "Hello, Bob!");
}

// --- renderFile ---

void testRenderFile () {
    string root = rootFor ("file");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    string tmplPath = root + "/page.tmpl";
    try {
        GLib.FileUtils.set_contents (tmplPath, "Title: {{title}}");
    } catch (GLib.FileError e) {
        assert_not_reached ();
    }

    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("title", "Home");
    string ? result = Template.renderFile (new Vala.Io.Path (tmplPath), vars);
    assert (result == "Title: Home");
    cleanup (root);
}

void testRenderFileMissing () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    string ? result = Template.renderFile (
        new Vala.Io.Path ("/tmp/valacore/ut/nonexistent.tmpl"), vars);
    assert (result == null);
}

// --- renderJson ---

void testRenderJson () {
    var json = Json.parse ("{\"name\": \"World\", \"count\": 42}");
    string result = Template.renderJson ("{{name}} ({{count}})", json);
    assert (result == "World (42)");
}

void testRenderJsonArray () {
    var json = Json.parse ("{\"items\": [\"a\", \"b\", \"c\"]}");
    string result = Template.renderJson (
        "{{#each items}}[{{.}}]{{/each}}", json);
    assert (result == "[a][b][c]");
}

void testCompiledRenderJson () {
    var tmpl = Template.compile ("Hi {{name}}!");
    var json = Json.parse ("{\"name\": \"Vala\"}");
    string result = tmpl.renderJson (json);
    assert (result == "Hi Vala!");
}

// --- Edge cases ---

void testUnclosedTag () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    string result = Template.render ("Hello {{name", vars);
    assert (result == "Hello {{name");
}

void testNestedIf () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("a", "yes");
    vars.put ("b", "yes");
    string result = Template.render (
        "{{#if a}}A{{#if b}}B{{/if}}{{/if}}", vars);
    assert (result == "AB");
}

void testComplexTemplate () {
    var vars = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    vars.put ("title", "Report");
    vars.put ("items", "alpha,beta,gamma");
    vars.put ("footer", "true");
    string tmpl = "# {{title | upper}}\n{{#each items}}- {{.}}\n{{/each}}{{#if footer}}---{{/if}}";
    string result = Template.render (tmpl, vars);
    assert (result == "# REPORT\n- alpha\n- beta\n- gamma\n---");
}
