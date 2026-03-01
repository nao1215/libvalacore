using Vala.Encoding;
using Vala.Collections;
using Vala.Io;

void main (string[] args) {
    Test.init (ref args);

    // Parse basics
    Test.add_func ("/encoding/xml/testParseSimple", testParseSimple);
    Test.add_func ("/encoding/xml/testParseAttributes", testParseAttributes);
    Test.add_func ("/encoding/xml/testParseNested", testParseNested);
    Test.add_func ("/encoding/xml/testParseSelfClosing", testParseSelfClosing);
    Test.add_func ("/encoding/xml/testParseEntities", testParseEntities);
    Test.add_func ("/encoding/xml/testParseProlog", testParseProlog);
    Test.add_func ("/encoding/xml/testParseComment", testParseComment);
    Test.add_func ("/encoding/xml/testParseCDATA", testParseCDATA);
    Test.add_func ("/encoding/xml/testParseMultipleChildren", testParseMultipleChildren);
    Test.add_func ("/encoding/xml/testParseInvalid", testParseInvalid);

    // Node access
    Test.add_func ("/encoding/xml/testNodeText", testNodeText);
    Test.add_func ("/encoding/xml/testNodeChildren", testNodeChildren);
    Test.add_func ("/encoding/xml/testNodeChild", testNodeChild);
    Test.add_func ("/encoding/xml/testNodeChildMissing", testNodeChildMissing);
    Test.add_func ("/encoding/xml/testNodeAttr", testNodeAttr);
    Test.add_func ("/encoding/xml/testNodeAttrMissing", testNodeAttrMissing);
    Test.add_func ("/encoding/xml/testNodeChildrenByName", testNodeChildrenByName);
    Test.add_func ("/encoding/xml/testNodeChildrenSnapshot", testNodeChildrenSnapshot);
    Test.add_func ("/encoding/xml/testNodeAttrsSnapshot", testNodeAttrsSnapshot);

    // Stringify
    Test.add_func ("/encoding/xml/testStringify", testStringify);
    Test.add_func ("/encoding/xml/testStringifySelfClosing", testStringifySelfClosing);
    Test.add_func ("/encoding/xml/testPretty", testPretty);

    // XPath
    Test.add_func ("/encoding/xml/testXpathDescendant", testXpathDescendant);
    Test.add_func ("/encoding/xml/testXpathAbsolute", testXpathAbsolute);
    Test.add_func ("/encoding/xml/testXpathAttrFilter", testXpathAttrFilter);
    Test.add_func ("/encoding/xml/testXpathFirst", testXpathFirst);
    Test.add_func ("/encoding/xml/testXpathNoMatch", testXpathNoMatch);

    // parseFile
    Test.add_func ("/encoding/xml/testParseFile", testParseFile);
    Test.add_func ("/encoding/xml/testParseFileMissing", testParseFileMissing);

    Test.run ();
}

string rootFor (string name) {
    return "%s/valacore/ut/xml_%s_%s".printf (Environment.get_tmp_dir (), name, GLib.Uuid.string_random ());
}

void cleanup (string path) {
    FileTree.deleteTree (new Vala.Io.Path (path));
}

// --- Parse basics ---

void testParseSimple () {
    XmlNode ? root = Xml.parse ("<root>Hello</root>");
    assert (root != null);
    assert (root.name () == "root");
    assert (root.text () == "Hello");
}

void testParseAttributes () {
    XmlNode ? root = Xml.parse ("<item id=\"42\" type=\"book\">Title</item>");
    assert (root != null);
    assert (root.name () == "item");
    assert (root.attr ("id") == "42");
    assert (root.attr ("type") == "book");
    assert (root.text () == "Title");
}

void testParseNested () {
    string xml = "<root><parent><child>text</child></parent></root>";
    XmlNode ? root = Xml.parse (xml);
    assert (root != null);
    assert (root.name () == "root");
    XmlNode ? parent = root.child ("parent");
    assert (parent != null);
    XmlNode ? child = parent.child ("child");
    assert (child != null);
    assert (child.text () == "text");
}

void testParseSelfClosing () {
    XmlNode ? root = Xml.parse ("<root><empty/></root>");
    assert (root != null);
    XmlNode ? empty = root.child ("empty");
    assert (empty != null);
    assert (empty.text () == "");
    assert (empty.children ().size () == 0);
}

void testParseEntities () {
    XmlNode ? root = Xml.parse ("<r>&lt;a&gt; &amp; &quot;b&quot; &apos;c&apos;</r>");
    assert (root != null);
    assert (root.text () == "<a> & \"b\" 'c'");
}

void testParseProlog () {
    string xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<root>data</root>";
    XmlNode ? root = Xml.parse (xml);
    assert (root != null);
    assert (root.name () == "root");
    assert (root.text () == "data");
}

void testParseComment () {
    string xml = "<root><!-- comment --><item>val</item></root>";
    XmlNode ? root = Xml.parse (xml);
    assert (root != null);
    XmlNode ? item = root.child ("item");
    assert (item != null);
    assert (item.text () == "val");
}

void testParseCDATA () {
    string xml = "<root><![CDATA[raw <data> & stuff]]></root>";
    XmlNode ? root = Xml.parse (xml);
    assert (root != null);
    assert (root.text () == "raw <data> & stuff");
}

void testParseMultipleChildren () {
    string xml = "<list><item>a</item><item>b</item><item>c</item></list>";
    XmlNode ? root = Xml.parse (xml);
    assert (root != null);
    ArrayList<XmlNode> items = root.childrenByName ("item");
    assert (items.size () == 3);
    assert (items.get (0).text () == "a");
    assert (items.get (1).text () == "b");
    assert (items.get (2).text () == "c");
}

void testParseInvalid () {
    XmlNode ? root = Xml.parse ("");
    assert (root == null);

    XmlNode ? root2 = Xml.parse ("not xml at all");
    assert (root2 == null);
}

// --- Node access ---

void testNodeText () {
    XmlNode ? root = Xml.parse ("<r>hello world</r>");
    assert (root != null);
    assert (root.text () == "hello world");
}

void testNodeChildren () {
    string xml = "<r><a/><b/><c/></r>";
    XmlNode ? root = Xml.parse (xml);
    assert (root != null);
    ArrayList<XmlNode> ch = root.children ();
    assert (ch.size () == 3);
    assert (ch.get (0).name () == "a");
    assert (ch.get (1).name () == "b");
    assert (ch.get (2).name () == "c");
}

void testNodeChild () {
    string xml = "<r><first>1</first><second>2</second></r>";
    XmlNode ? root = Xml.parse (xml);
    assert (root != null);
    XmlNode ? first = root.child ("first");
    assert (first != null);
    assert (first.text () == "1");
    XmlNode ? second = root.child ("second");
    assert (second != null);
    assert (second.text () == "2");
}

void testNodeChildMissing () {
    XmlNode ? root = Xml.parse ("<r><a/></r>");
    assert (root != null);
    assert (root.child ("missing") == null);
}

void testNodeAttr () {
    XmlNode ? root = Xml.parse ("<r key=\"val\" num=\"123\"/>");
    assert (root != null);
    assert (root.attr ("key") == "val");
    assert (root.attr ("num") == "123");
}

void testNodeAttrMissing () {
    XmlNode ? root = Xml.parse ("<r key=\"val\"/>");
    assert (root != null);
    assert (root.attr ("missing") == null);
}

void testNodeChildrenByName () {
    string xml = "<r><a>1</a><b>2</b><a>3</a></r>";
    XmlNode ? root = Xml.parse (xml);
    assert (root != null);
    ArrayList<XmlNode> aNodes = root.childrenByName ("a");
    assert (aNodes.size () == 2);
    assert (aNodes.get (0).text () == "1");
    assert (aNodes.get (1).text () == "3");
}

void testNodeChildrenSnapshot () {
    XmlNode ? root = Xml.parse ("<r><a/><b/></r>");
    assert (root != null);
    ArrayList<XmlNode> snapshot = root.children ();
    assert (snapshot.size () == 2);
    snapshot.clear ();
    ArrayList<XmlNode> latest = root.children ();
    assert (latest.size () == 2);
}

void testNodeAttrsSnapshot () {
    XmlNode ? root = Xml.parse ("<r id=\"1\"/>");
    assert (root != null);
    HashMap<string, string> snapshot = root.attrs ();
    snapshot.put ("id", "changed");
    snapshot.put ("extra", "x");
    assert (root.attr ("id") == "1");
    assert (root.attr ("extra") == null);
}

// --- Stringify ---

void testStringify () {
    XmlNode ? root = Xml.parse ("<root><item>Hello</item></root>");
    assert (root != null);
    string xml = Xml.stringify (root);
    assert (xml.contains ("<root>"));
    assert (xml.contains ("<item>Hello</item>"));
    assert (xml.contains ("</root>"));
}

void testStringifySelfClosing () {
    XmlNode ? root = Xml.parse ("<r><empty/></r>");
    assert (root != null);
    string xml = Xml.stringify (root);
    assert (xml.contains ("<empty/>"));
}

void testPretty () {
    XmlNode ? root = Xml.parse ("<root><a>1</a><b>2</b></root>");
    assert (root != null);
    string xml = Xml.pretty (root, 2);
    assert (xml.contains ("\n"));
    assert (xml.contains ("  <a>"));
}

// --- XPath ---

void testXpathDescendant () {
    string xml = "<root><a><b>1</b></a><b>2</b></root>";
    XmlNode ? root = Xml.parse (xml);
    assert (root != null);
    ArrayList<XmlNode> results = Xml.xpath (root, "//b");
    assert (results.size () == 2);
    assert (results.get (0).text () == "1");
    assert (results.get (1).text () == "2");
}

void testXpathAbsolute () {
    string xml = "<root><items><item>a</item><item>b</item></items></root>";
    XmlNode ? root = Xml.parse (xml);
    assert (root != null);
    ArrayList<XmlNode> results = Xml.xpath (root, "/root/items/item");
    assert (results.size () == 2);
    assert (results.get (0).text () == "a");
    assert (results.get (1).text () == "b");
}

void testXpathAttrFilter () {
    string xml = "<root><item id=\"1\">a</item><item id=\"2\">b</item></root>";
    XmlNode ? root = Xml.parse (xml);
    assert (root != null);
    ArrayList<XmlNode> results = Xml.xpath (root, "//item[@id=\"2\"]");
    assert (results.size () == 1);
    assert (results.get (0).text () == "b");
}

void testXpathFirst () {
    string xml = "<root><a>1</a><a>2</a></root>";
    XmlNode ? root = Xml.parse (xml);
    assert (root != null);
    XmlNode ? first = Xml.xpathFirst (root, "//a");
    assert (first != null);
    assert (first.text () == "1");
}

void testXpathNoMatch () {
    XmlNode ? root = Xml.parse ("<root><a/></root>");
    assert (root != null);
    ArrayList<XmlNode> results = Xml.xpath (root, "//missing");
    assert (results.size () == 0);
    assert (Xml.xpathFirst (root, "//missing") == null);
}

// --- parseFile ---

void testParseFile () {
    string root = rootFor ("file");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    string filePath = root + "/test.xml";
    try {
        GLib.FileUtils.set_contents (filePath, "<data><value>42</value></data>");
    } catch (GLib.FileError e) {
        assert_not_reached ();
    }

    XmlNode ? node = Xml.parseFile (new Vala.Io.Path (filePath));
    assert (node != null);
    assert (node.name () == "data");
    XmlNode ? val = node.child ("value");
    assert (val != null);
    assert (val.text () == "42");
    cleanup (root);
}

void testParseFileMissing () {
    string root = rootFor ("missing");
    cleanup (root);
    XmlNode ? node = Xml.parseFile (new Vala.Io.Path (root + "/nonexist.xml"));
    assert (node == null);
    cleanup (root);
}
