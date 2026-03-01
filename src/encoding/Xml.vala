using Vala.Collections;

namespace Vala.Encoding {
    /**
     * Represents an XML node (element or text).
     *
     * Provides access to tag name, text content, attributes,
     * and child nodes.
     *
     * Example:
     * {{{
     *     XmlNode ? root = Xml.parse ("<root><item>hi</item></root>");
     *     assert (root.name () == "root");
     *     assert (root.child ("item").text () == "hi");
     * }}}
     */
    public class XmlNode : GLib.Object {
        private string _name;
        private string _text;
        private HashMap<string, string> _attrs;
        private ArrayList<XmlNode> _children;
        private bool _is_text;

        internal XmlNode (string name) {
            _name = name;
            _text = "";
            _attrs = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            _children = new ArrayList<XmlNode> ();
            _is_text = false;
        }

        internal XmlNode.text_node (string text) {
            _name = "";
            _text = text;
            _attrs = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            _children = new ArrayList<XmlNode> ();
            _is_text = true;
        }

        internal void addChild (XmlNode child) {
            _children.add (child);
        }

        internal void setAttribute (string name, string val) {
            _attrs.put (name, val);
        }

        internal void appendText (string text) {
            _text += text;
        }

        internal bool isTextNode () {
            return _is_text;
        }

        /**
         * Returns the tag name of this element.
         *
         * @return tag name, or empty string for text nodes.
         */
        public string name () {
            return _name;
        }

        /**
         * Returns the text content of this node.
         *
         * For element nodes, returns the concatenated text of all
         * direct text children.
         *
         * @return text content.
         */
        public string text () {
            if (_is_text) {
                return _text;
            }
            var sb = new GLib.StringBuilder ();
            for (int i = 0; i < _children.size (); i++) {
                XmlNode child = _children.get (i);
                if (child.isTextNode ()) {
                    sb.append (child._text);
                }
            }
            return sb.str;
        }

        /**
         * Returns the value of an attribute.
         *
         * @param attrName attribute name.
         * @return attribute value, or null if not present.
         */
        public string ? attr (string attrName) {
            return _attrs.get (attrName);
        }

        /**
         * Returns all child element nodes.
         *
         * Text nodes are excluded.
         *
         * @return list of child element nodes.
         */
        public ArrayList<XmlNode> children () {
            var result = new ArrayList<XmlNode> ();
            for (int i = 0; i < _children.size (); i++) {
                XmlNode c = _children.get (i);
                if (!c.isTextNode ()) {
                    result.add (c);
                }
            }
            return result;
        }

        /**
         * Returns the first child element with the given tag name.
         *
         * @param childName tag name to search for.
         * @return matching child node, or null if not found.
         */
        public XmlNode ? child (string childName) {
            for (int i = 0; i < _children.size (); i++) {
                XmlNode c = _children.get (i);
                if (!c.isTextNode () && c._name == childName) {
                    return c;
                }
            }
            return null;
        }

        /**
         * Returns all child elements with the given tag name.
         *
         * @param childName tag name to search for.
         * @return list of matching child nodes.
         */
        public ArrayList<XmlNode> childrenByName (string childName) {
            var result = new ArrayList<XmlNode> ();
            for (int i = 0; i < _children.size (); i++) {
                XmlNode c = _children.get (i);
                if (!c.isTextNode () && c._name == childName) {
                    result.add (c);
                }
            }
            return result;
        }

        /**
         * Returns all attributes as a HashMap.
         *
         * @return attribute map.
         */
        public HashMap<string, string> attrs () {
            return _attrs;
        }

        internal ArrayList<XmlNode> allChildren () {
            return _children;
        }
    }

    /**
     * XML parsing and serialization utilities.
     *
     * Provides parse, stringify, pretty-print, and simple
     * XPath-like query operations. Uses a hand-written parser
     * with no external dependencies.
     *
     * Example:
     * {{{
     *     XmlNode ? root = Xml.parse ("<root><item id=\"1\">Hello</item></root>");
     *     string val = Xml.xpathFirst (root, "//item").text ();
     * }}}
     */
    public class Xml : GLib.Object {
        /**
         * Parses an XML string into an XmlNode tree.
         *
         * Returns the root element node, or null on parse error.
         *
         * @param xml XML string.
         * @return root XmlNode, or null on error.
         */
        public static XmlNode ? parse (string xml) {
            int pos = 0;
            skipProlog (xml, ref pos);
            return parseElement (xml, ref pos);
        }

        /**
         * Reads an XML file and parses it into an XmlNode tree.
         *
         * @param path path to XML file.
         * @return root XmlNode, or null on error.
         */
        public static XmlNode ? parseFile (Vala.Io.Path path) {
            string ? content = Vala.Io.Files.readAllText (path);
            if (content == null) {
                return null;
            }
            return parse (content);
        }

        /**
         * Serializes an XmlNode tree to a compact XML string.
         *
         * @param node root node to serialize.
         * @return XML string.
         */
        public static string stringify (XmlNode node) {
            var sb = new GLib.StringBuilder ();
            writeNode (node, sb, -1, 0);
            return sb.str;
        }

        /**
         * Serializes an XmlNode tree to a formatted XML string.
         *
         * @param node root node to serialize.
         * @param indent number of spaces per indentation level.
         * @return formatted XML string.
         */
        public static string pretty (XmlNode node, int indent = 2) {
            var sb = new GLib.StringBuilder ();
            writeNode (node, sb, indent, 0);
            return sb.str;
        }

        /**
         * Finds nodes matching a simple XPath expression.
         *
         * Supports descendant search with double-slash prefix,
         * absolute paths from root, and attribute filters using
         * bracket notation.
         *
         * @param root root node.
         * @param expr XPath expression.
         * @return list of matching nodes.
         */
        public static ArrayList<XmlNode> xpath (XmlNode root, string expr) {
            var results = new ArrayList<XmlNode> ();
            if (expr.has_prefix ("//")) {
                string tagName = expr.substring (2);
                string ? attrFilter = null;
                string ? attrValue = null;
                parseAttrFilter (ref tagName, out attrFilter, out attrValue);
                findDescendants (root, tagName, attrFilter, attrValue, results);
            } else if (expr.has_prefix ("/")) {
                string[] parts = expr.substring (1).split ("/");
                var current = new ArrayList<XmlNode> ();
                current.add (root);
                for (int i = 0; i < parts.length; i++) {
                    string part = parts[i];
                    if (part.length == 0) {
                        continue;
                    }
                    string ? attrFilter = null;
                    string ? attrValue = null;
                    parseAttrFilter (ref part, out attrFilter, out attrValue);
                    var next = new ArrayList<XmlNode> ();
                    if (i == 0) {
                        // First part must match root
                        for (int j = 0; j < current.size (); j++) {
                            XmlNode n = current.get (j);
                            if (n.name () == part && matchesAttr (n, attrFilter, attrValue)) {
                                next.add (n);
                            }
                        }
                    } else {
                        for (int j = 0; j < current.size (); j++) {
                            XmlNode n = current.get (j);
                            ArrayList<XmlNode> ch = n.childrenByName (part);
                            for (int k = 0; k < ch.size (); k++) {
                                XmlNode c = ch.get (k);
                                if (matchesAttr (c, attrFilter, attrValue)) {
                                    next.add (c);
                                }
                            }
                        }
                    }
                    current = next;
                }
                for (int i = 0; i < current.size (); i++) {
                    results.add (current.get (i));
                }
            }
            return results;
        }

        /**
         * Finds the first node matching a simple XPath expression.
         *
         * @param root root node.
         * @param expr XPath expression.
         * @return first matching node, or null.
         */
        public static XmlNode ? xpathFirst (XmlNode root, string expr) {
            ArrayList<XmlNode> matches = xpath (root, expr);
            if (matches.size () > 0) {
                return matches.get (0);
            }
            return null;
        }

        // --- Parser ---

        private static void skipProlog (string xml, ref int pos) {
            skipWhitespace (xml, ref pos);
            // Skip XML declaration: <?xml ... ?>
            if (pos + 1 < xml.length && xml[pos] == '<' && xml[pos + 1] == '?') {
                int end = xml.index_of ("?>", pos);
                if (end >= 0) {
                    pos = end + 2;
                }
            }
            skipWhitespace (xml, ref pos);
            // Skip DOCTYPE
            if (pos + 8 < xml.length && xml.substring (pos, 9) == "<!DOCTYPE") {
                int end = xml.index_of (">", pos);
                if (end >= 0) {
                    pos = end + 1;
                }
            }
            skipWhitespace (xml, ref pos);
        }

        private static XmlNode ? parseElement (string xml, ref int pos) {
            skipWhitespace (xml, ref pos);
            if (pos >= xml.length || xml[pos] != '<') {
                return null;
            }

            pos++; // skip <

            // Skip comments: <!-- ... -->
            if (pos + 2 < xml.length && xml[pos] == '!' && xml[pos + 1] == '-' && xml[pos + 2] == '-') {
                int endComment = xml.index_of ("-->", pos);
                if (endComment >= 0) {
                    pos = endComment + 3;
                    return parseElement (xml, ref pos);
                }
                return null;
            }

            // Read tag name
            int nameStart = pos;
            while (pos < xml.length && xml[pos] != ' ' && xml[pos] != '>'
                   && xml[pos] != '/' && xml[pos] != '\t' && xml[pos] != '\n'
                   && xml[pos] != '\r') {
                pos++;
            }
            string tagName = xml.substring (nameStart, pos - nameStart);
            if (tagName.length == 0) {
                return null;
            }

            var node = new XmlNode (tagName);

            // Parse attributes
            while (pos < xml.length && xml[pos] != '>' && xml[pos] != '/') {
                skipWhitespace (xml, ref pos);
                if (pos < xml.length && (xml[pos] == '>' || xml[pos] == '/')) {
                    break;
                }
                // Read attribute name
                int attrStart = pos;
                while (pos < xml.length && xml[pos] != '=' && xml[pos] != ' '
                       && xml[pos] != '>' && xml[pos] != '/') {
                    pos++;
                }
                string attrName = xml.substring (attrStart, pos - attrStart).strip ();
                if (attrName.length == 0) {
                    break;
                }
                skipWhitespace (xml, ref pos);
                if (pos < xml.length && xml[pos] == '=') {
                    pos++; // skip =
                    skipWhitespace (xml, ref pos);
                    string attrVal = parseAttrValue (xml, ref pos);
                    node.setAttribute (attrName, decodeEntities (attrVal));
                }
            }

            // Self-closing tag
            if (pos < xml.length && xml[pos] == '/') {
                pos++; // skip /
                if (pos < xml.length && xml[pos] == '>') {
                    pos++; // skip >
                }
                return node;
            }

            if (pos < xml.length && xml[pos] == '>') {
                pos++; // skip >
            }

            // Parse children and text content
            while (pos < xml.length) {
                // Check for closing tag
                if (pos + 1 < xml.length && xml[pos] == '<' && xml[pos + 1] == '/') {
                    int closeEnd = xml.index_of (">", pos);
                    if (closeEnd < 0) {
                        return null;
                    }
                    string closeName = xml.substring (pos + 2, closeEnd - pos - 2).strip ();
                    if (closeName != tagName) {
                        return null;
                    }
                    pos = closeEnd + 1;
                    break;
                }

                if (xml[pos] == '<') {
                    // Check for comment
                    if (pos + 3 < xml.length && xml[pos + 1] == '!'
                        && xml[pos + 2] == '-' && xml[pos + 3] == '-') {
                        int endComment = xml.index_of ("-->", pos);
                        if (endComment >= 0) {
                            pos = endComment + 3;
                            continue;
                        }
                    }
                    // Check for CDATA
                    if (pos + 8 < xml.length && xml.substring (pos, 9) == "<![CDATA[") {
                        int cdataEnd = xml.index_of ("]]>", pos);
                        if (cdataEnd >= 0) {
                            string cdata = xml.substring (pos + 9, cdataEnd - pos - 9);
                            node.addChild (new XmlNode.text_node (cdata));
                            pos = cdataEnd + 3;
                            continue;
                        }
                    }
                    // Child element
                    XmlNode ? child = parseElement (xml, ref pos);
                    if (child != null) {
                        node.addChild (child);
                    }
                } else {
                    // Text content
                    int textStart = pos;
                    while (pos < xml.length && xml[pos] != '<') {
                        pos++;
                    }
                    string text = xml.substring (textStart, pos - textStart);
                    if (text.strip ().length > 0) {
                        node.addChild (new XmlNode.text_node (decodeEntities (text)));
                    }
                }
            }

            return node;
        }

        private static string parseAttrValue (string xml, ref int pos) {
            if (pos >= xml.length) {
                return "";
            }
            char quote = xml[pos];
            if (quote != '"' && quote != '\'') {
                // Unquoted value
                int start = pos;
                while (pos < xml.length && xml[pos] != ' ' && xml[pos] != '>'
                       && xml[pos] != '/') {
                    pos++;
                }
                return xml.substring (start, pos - start);
            }
            pos++; // skip opening quote
            int start = pos;
            while (pos < xml.length && xml[pos] != quote) {
                pos++;
            }
            string val = xml.substring (start, pos - start);
            if (pos < xml.length) {
                pos++; // skip closing quote
            }
            return val;
        }

        private static void skipWhitespace (string xml, ref int pos) {
            while (pos < xml.length && (xml[pos] == ' ' || xml[pos] == '\t'
                                        || xml[pos] == '\n' || xml[pos] == '\r')) {
                pos++;
            }
        }

        private static string decodeEntities (string text) {
            string result = text;
            result = result.replace ("&amp;", "&");
            result = result.replace ("&lt;", "<");
            result = result.replace ("&gt;", ">");
            result = result.replace ("&quot;", "\"");
            result = result.replace ("&apos;", "'");
            return result;
        }

        // --- Serializer ---

        private static void writeNode (XmlNode node, GLib.StringBuilder sb,
                                       int indent, int depth) {
            if (node.isTextNode ()) {
                sb.append (encodeEntities (node.text ()));
                return;
            }

            if (indent >= 0 && depth > 0) {
                sb.append_c ('\n');
                appendIndent (sb, indent, depth);
            }

            sb.append ("<");
            sb.append (node.name ());

            // Write attributes
            HashMap<string, string> attrs = node.attrs ();
            GLib.List<unowned string> keys = attrs.keys ();
            foreach (unowned string key in keys) {
                string ? val = attrs.get (key);
                if (val != null) {
                    sb.append (" ");
                    sb.append (key);
                    sb.append ("=\"");
                    sb.append (encodeEntities (val));
                    sb.append ("\"");
                }
            }

            ArrayList<XmlNode> ch = node.allChildren ();
            bool hasNoContent = (ch.size () == 0);

            if (hasNoContent) {
                sb.append ("/>");
                return;
            }

            sb.append (">");

            bool hasElementChild = false;
            bool hasTextChild = false;
            for (int i = 0; i < ch.size (); i++) {
                XmlNode child = ch.get (i);
                if (child.isTextNode ()) {
                    hasTextChild = true;
                } else {
                    hasElementChild = true;
                }
            }
            bool mixedContent = hasElementChild && hasTextChild;

            for (int i = 0; i < ch.size (); i++) {
                XmlNode child = ch.get (i);
                if (child.isTextNode ()) {
                    writeNode (child, sb, indent, depth + 1);
                } else if (mixedContent) {
                    writeNode (child, sb, -1, depth + 1);
                } else {
                    writeNode (child, sb, indent, depth + 1);
                }
            }

            if (indent >= 0 && hasElementChild && !mixedContent) {
                sb.append_c ('\n');
                appendIndent (sb, indent, depth);
            }

            sb.append ("</");
            sb.append (node.name ());
            sb.append (">");
        }

        private static string encodeEntities (string text) {
            string result = text;
            result = result.replace ("&", "&amp;");
            result = result.replace ("<", "&lt;");
            result = result.replace (">", "&gt;");
            result = result.replace ("\"", "&quot;");
            return result;
        }

        private static void appendIndent (GLib.StringBuilder sb, int indent, int depth) {
            int total = indent * depth;
            for (int i = 0; i < total; i++) {
                sb.append_c (' ');
            }
        }

        // --- XPath helpers ---

        private static void parseAttrFilter (ref string tagName,
                                             out string ? attrFilter,
                                             out string ? attrValue) {
            attrFilter = null;
            attrValue = null;
            int bracketIdx = tagName.index_of ("[@");
            if (bracketIdx < 0) {
                return;
            }
            string filterPart = tagName.substring (bracketIdx + 2);
            tagName = tagName.substring (0, bracketIdx);
            int closeBracket = filterPart.index_of ("]");
            if (closeBracket >= 0) {
                filterPart = filterPart.substring (0, closeBracket);
            }
            int eqIdx = filterPart.index_of ("=");
            if (eqIdx >= 0) {
                attrFilter = filterPart.substring (0, eqIdx).strip ();
                string val = filterPart.substring (eqIdx + 1).strip ();
                // Remove quotes
                if (val.length >= 2 && ((val[0] == '"' && val[val.length - 1] == '"')
                                        || (val[0] == '\'' && val[val.length - 1] == '\''))) {
                    val = val.substring (1, val.length - 2);
                }
                attrValue = val;
            } else {
                attrFilter = filterPart.strip ();
            }
        }

        private static bool matchesAttr (XmlNode node, string ? attrFilter,
                                         string ? attrValue) {
            if (attrFilter == null) {
                return true;
            }
            string ? actual = node.attr (attrFilter);
            if (attrValue != null) {
                return actual != null && actual == attrValue;
            }
            return actual != null;
        }

        private static void findDescendants (XmlNode node, string tagName,
                                             string ? attrFilter, string ? attrValue,
                                             ArrayList<XmlNode> results) {
            if (!node.isTextNode () && node.name () == tagName
                && matchesAttr (node, attrFilter, attrValue)) {
                results.add (node);
            }
            ArrayList<XmlNode> ch = node.children ();
            for (int i = 0; i < ch.size (); i++) {
                findDescendants (ch.get (i), tagName, attrFilter, attrValue, results);
            }
        }
    }
}
