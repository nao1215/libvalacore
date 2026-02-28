using Vala.Lang;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/lang/stringescape/testEscapeHtml", testEscapeHtml);
    Test.add_func ("/lang/stringescape/testEscapeJson", testEscapeJson);
    Test.add_func ("/lang/stringescape/testEscapeXml", testEscapeXml);
    Test.run ();
}

void testEscapeHtml () {
    string src = "<div class=\"x\">Tom & Jerry's</div>";
    string expected = "&lt;div class=&quot;x&quot;&gt;Tom &amp; Jerry&#39;s&lt;/div&gt;";
    assert (StringEscape.escapeHtml (src) == expected);
}

void testEscapeJson () {
    string src = "line1\n\"quoted\"\\path\t";
    string expected = "line1\\n\\\"quoted\\\"\\\\path\\t";
    assert (StringEscape.escapeJson (src) == expected);
}

void testEscapeXml () {
    string src = "<tag attr=\"v\">A&B's</tag>";
    string expected = "&lt;tag attr=&quot;v&quot;&gt;A&amp;B&apos;s&lt;/tag&gt;";
    assert (StringEscape.escapeXml (src) == expected);
}
