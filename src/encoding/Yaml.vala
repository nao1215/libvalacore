using Vala.Collections;

namespace Vala.Encoding {
    /**
     * Represents a YAML value (scalar, mapping, or sequence).
     *
     * YamlValue is an immutable representation of a parsed YAML node.
     *
     * Example:
     * {{{
     *     YamlValue ? root = Yaml.parse ("name: Alice\nage: 30");
     *     string name = root.get ("name").asString ();
     * }}}
     */
    public class YamlValue : GLib.Object {
        private enum Kind {
            STRING,
            INT,
            DOUBLE,
            BOOL,
            NULL_VAL,
            MAPPING,
            SEQUENCE
        }

        private Kind _kind;
        private string _str_val;
        private int64 _int_val;
        private double _double_val;
        private bool _bool_val;
        private HashMap<string, YamlValue> _map;
        private ArrayList<YamlValue> _list;
        private ArrayList<string> _key_order;

        private YamlValue () {
            _kind = Kind.NULL_VAL;
            _str_val = "";
            _int_val = 0;
            _double_val = 0.0;
            _bool_val = false;
            _map = new HashMap<string, YamlValue> (GLib.str_hash, GLib.str_equal);
            _list = new ArrayList<YamlValue> ();
            _key_order = new ArrayList<string> ();
        }

        internal static YamlValue ofString (string val) {
            var v = new YamlValue ();
            v._kind = Kind.STRING;
            v._str_val = val;
            return v;
        }

        internal static YamlValue ofInt (int64 val) {
            var v = new YamlValue ();
            v._kind = Kind.INT;
            v._int_val = val;
            return v;
        }

        internal static YamlValue ofDouble (double val) {
            var v = new YamlValue ();
            v._kind = Kind.DOUBLE;
            v._double_val = val;
            return v;
        }

        internal static YamlValue ofBool (bool val) {
            var v = new YamlValue ();
            v._kind = Kind.BOOL;
            v._bool_val = val;
            return v;
        }

        internal static YamlValue ofNull () {
            var v = new YamlValue ();
            v._kind = Kind.NULL_VAL;
            return v;
        }

        internal static YamlValue ofMapping () {
            var v = new YamlValue ();
            v._kind = Kind.MAPPING;
            return v;
        }

        internal static YamlValue ofSequence () {
            var v = new YamlValue ();
            v._kind = Kind.SEQUENCE;
            return v;
        }

        internal void mapPut (string key, YamlValue val) {
            if (!_map.containsKey (key)) {
                _key_order.add (key);
            }
            _map.put (key, val);
        }

        internal void listAdd (YamlValue val) {
            _list.add (val);
        }

        /**
         * Returns true if this value is a string scalar.
         *
         * @return true for string values.
         */
        public bool isString () {
            return _kind == Kind.STRING;
        }

        /**
         * Returns true if this value is an integer scalar.
         *
         * @return true for integer values.
         */
        public bool isInt () {
            return _kind == Kind.INT;
        }

        /**
         * Returns true if this value is a floating-point scalar.
         *
         * @return true for double values.
         */
        public bool isDouble () {
            return _kind == Kind.DOUBLE;
        }

        /**
         * Returns true if this value is a boolean scalar.
         *
         * @return true for boolean values.
         */
        public bool isBool () {
            return _kind == Kind.BOOL;
        }

        /**
         * Returns true if this value is null.
         *
         * @return true for null values.
         */
        public bool isNull () {
            return _kind == Kind.NULL_VAL;
        }

        /**
         * Returns true if this value is a mapping (object/dict).
         *
         * @return true for mapping values.
         */
        public bool isMapping () {
            return _kind == Kind.MAPPING;
        }

        /**
         * Returns true if this value is a sequence (array/list).
         *
         * @return true for sequence values.
         */
        public bool isSequence () {
            return _kind == Kind.SEQUENCE;
        }

        /**
         * Returns the string value, or null if not a string.
         *
         * @return string value.
         */
        public string ? asString () {
            if (_kind == Kind.STRING) {
                return _str_val;
            }
            return null;
        }

        /**
         * Returns the integer value, or 0 if not an integer.
         *
         * @return integer value.
         */
        public int64 asInt () {
            if (_kind == Kind.INT) {
                return _int_val;
            }
            return 0;
        }

        /**
         * Returns the double value, or 0.0 if not a double.
         *
         * @return double value.
         */
        public double asDouble () {
            if (_kind == Kind.DOUBLE) {
                return _double_val;
            }
            if (_kind == Kind.INT) {
                return (double) _int_val;
            }
            return 0.0;
        }

        /**
         * Returns the boolean value, or false if not a boolean.
         *
         * @return boolean value.
         */
        public bool asBool () {
            if (_kind == Kind.BOOL) {
                return _bool_val;
            }
            return false;
        }

        /**
         * Returns a child value by key (for mappings).
         *
         * @param key mapping key.
         * @return child YamlValue, or null if key not found or not a mapping.
         */
        public new YamlValue ? get (string key) {
            if (_kind != Kind.MAPPING) {
                return null;
            }
            return _map.get (key);
        }

        /**
         * Returns a child value by index (for sequences).
         *
         * @param index zero-based index.
         * @return child YamlValue, or null if out of range or not a sequence.
         */
        public YamlValue ? at (int index) {
            if (_kind != Kind.SEQUENCE) {
                return null;
            }
            if (index < 0 || index >= _list.size ()) {
                return null;
            }
            return _list.get (index);
        }

        /**
         * Returns the number of entries (for mappings or sequences).
         *
         * @return number of entries, or 0 if not a collection.
         */
        public int size () {
            if (_kind == Kind.MAPPING) {
                return (int) _map.size ();
            }
            if (_kind == Kind.SEQUENCE) {
                return (int) _list.size ();
            }
            return 0;
        }

        /**
         * Returns the keys of a mapping in insertion order.
         *
         * @return list of keys, or null if not a mapping.
         */
        public ArrayList<string> ? keys () {
            if (_kind != Kind.MAPPING) {
                return null;
            }
            var copy = new ArrayList<string> ();
            for (int i = 0; i < _key_order.size (); i++) {
                string key = _key_order.get (i);
                copy.add (key);
            }
            return copy;
        }
    }

    /**
     * YAML parsing, serialization, and query utilities.
     *
     * Supports a subset of YAML: mappings, sequences, scalars
     * (strings, integers, doubles, booleans, null), block style,
     * flow style for inline sequences/mappings, multi-line strings,
     * comments, and multi-document YAML.
     *
     * Example:
     * {{{
     *     YamlValue ? root = Yaml.parse ("name: Alice\nage: 30");
     *     string name = root.get ("name").asString ();
     * }}}
     */
    public class Yaml : GLib.Object {
        /**
         * Parses a YAML string into a YamlValue tree.
         *
         * @param yaml YAML string.
         * @return root YamlValue, or null on error.
         */
        public static YamlValue ? parse (string yaml) {
            string[] lines = yaml.split ("\n");
            int pos = 0;
            // Skip document start marker
            if (pos < lines.length && lines[pos].strip () == "---") {
                pos++;
            }
            return parseBlock (lines, ref pos, 0);
        }

        /**
         * Reads and parses a YAML file.
         *
         * @param path path to YAML file.
         * @return root YamlValue, or null on error.
         */
        public static YamlValue ? parseFile (Vala.Io.Path path) {
            string ? content = Vala.Io.Files.readAllText (path);
            if (content == null) {
                return null;
            }
            return parse (content);
        }

        /**
         * Parses a multi-document YAML string.
         *
         * Documents are separated by "---" lines.
         *
         * @param yaml YAML string.
         * @return list of YamlValue roots.
         */
        public static ArrayList<YamlValue> parseAll (string yaml) {
            var results = new ArrayList<YamlValue> ();
            string[] documents = splitDocuments (yaml);
            foreach (string doc in documents) {
                string trimmed = doc.strip ();
                if (trimmed.length == 0) {
                    continue;
                }
                YamlValue ? val = parse (trimmed);
                if (val != null) {
                    results.add (val);
                }
            }
            return results;
        }

        /**
         * Serializes a YamlValue tree to a YAML string.
         *
         * @param value root YamlValue.
         * @return YAML string.
         */
        public static string stringify (YamlValue value) {
            var sb = new GLib.StringBuilder ();
            writeValue (value, sb, 0, false);
            return sb.str;
        }

        /**
         * Queries a YamlValue tree using dot notation with array indices.
         *
         * Path segments are separated by dots. Array indices use
         * bracket notation.
         *
         * Example: "server.hosts[0]" accesses the first element of
         * the "hosts" sequence under the "server" mapping.
         *
         * @param root root YamlValue.
         * @param path dot-separated path.
         * @return matching YamlValue, or null if not found.
         */
        public static YamlValue ? query (YamlValue root, string path) {
            string[] parts = splitPath (path);
            YamlValue ? current = root;
            foreach (string part in parts) {
                if (current == null) {
                    return null;
                }
                // Check for array index: name[idx]
                int bracketIdx = part.index_of ("[");
                if (bracketIdx >= 0) {
                    string keyPart = part.substring (0, bracketIdx);
                    if (keyPart.length > 0) {
                        current = current.get (keyPart);
                        if (current == null) {
                            return null;
                        }
                    }

                    int cursor = bracketIdx;
                    while (cursor < part.length) {
                        if (part[cursor] != '[') {
                            return null;
                        }

                        int closeBracket = part.index_of ("]", cursor);
                        if (closeBracket < 0) {
                            return null;
                        }
                        string idxStr = part.substring (cursor + 1, closeBracket - cursor - 1);
                        int64 idx;
                        if (!int64.try_parse (idxStr, out idx)) {
                            return null;
                        }
                        if (idx < 0 || idx > int.MAX) {
                            return null;
                        }
                        current = current.at ((int) idx);
                        if (current == null) {
                            return null;
                        }
                        cursor = closeBracket + 1;
                    }
                } else {
                    current = current.get (part);
                }
            }
            return current;
        }

        // --- Parser ---

        private static YamlValue ? parseBlock (string[] lines, ref int pos, int minIndent) {
            skipEmptyAndComments (lines, ref pos);
            if (pos >= lines.length) {
                return null;
            }

            string line = lines[pos];
            int indent = countIndent (line);
            string trimmed = stripComment (line.strip ());

            if (indent < minIndent) {
                return null;
            }

            // Flow sequence: [...]
            if (trimmed.has_prefix ("[")) {
                pos++;
                return parseFlowSequence (trimmed);
            }

            // Flow mapping: {...}
            if (trimmed.has_prefix ("{")) {
                pos++;
                return parseFlowMapping (trimmed);
            }

            // Sequence item: "- ..."
            if (trimmed.has_prefix ("- ")) {
                return parseSequenceBlock (lines, ref pos, indent);
            }
            if (trimmed == "-") {
                return parseSequenceBlock (lines, ref pos, indent);
            }

            // Mapping: "key: value"
            int colonIdx = findColonSeparator (trimmed);
            if (colonIdx > 0) {
                return parseMappingBlock (lines, ref pos, indent);
            }

            // Scalar
            pos++;
            return parseScalar (trimmed);
        }

        private static YamlValue parseMappingBlock (string[] lines, ref int pos, int baseIndent) {
            var mapping = YamlValue.ofMapping ();
            while (pos < lines.length) {
                skipEmptyAndComments (lines, ref pos);
                if (pos >= lines.length) {
                    break;
                }
                string line = lines[pos];
                int indent = countIndent (line);
                if (indent < baseIndent) {
                    break;
                }
                if (indent > baseIndent) {
                    break;
                }
                string trimmed = stripComment (line.strip ());
                if (trimmed.length == 0) {
                    pos++;
                    continue;
                }

                // Must be a key: value pair
                int colonIdx = findColonSeparator (trimmed);
                if (colonIdx <= 0) {
                    break;
                }

                string key = trimmed.substring (0, colonIdx).strip ();
                string valPart = trimmed.substring (colonIdx + 1).strip ();
                pos++;

                YamlValue val;
                if (valPart.length == 0) {
                    // Value is on next lines (block)
                    val = parseBlock (lines, ref pos, baseIndent + 1) ?? YamlValue.ofNull ();
                } else {
                    val = parseInlineValue (valPart, lines, ref pos, baseIndent + 1);
                }
                mapping.mapPut (key, val);
            }
            return mapping;
        }

        private static YamlValue parseSequenceBlock (string[] lines, ref int pos, int baseIndent) {
            var seq = YamlValue.ofSequence ();
            while (pos < lines.length) {
                skipEmptyAndComments (lines, ref pos);
                if (pos >= lines.length) {
                    break;
                }
                string line = lines[pos];
                int indent = countIndent (line);
                if (indent < baseIndent) {
                    break;
                }
                if (indent > baseIndent) {
                    break;
                }
                string trimmed = stripComment (line.strip ());
                if (!trimmed.has_prefix ("- ") && trimmed != "-") {
                    break;
                }

                pos++;
                string itemPart;
                if (trimmed == "-") {
                    itemPart = "";
                } else {
                    itemPart = trimmed.substring (2).strip ();
                }

                YamlValue item;
                if (itemPart.length == 0) {
                    item = parseBlock (lines, ref pos, baseIndent + 1) ?? YamlValue.ofNull ();
                } else {
                    // Check if the item is a mapping key
                    int colonIdx = findColonSeparator (itemPart);
                    if (colonIdx > 0) {
                        // Inline mapping in sequence
                        var inlineMapping = YamlValue.ofMapping ();
                        string key = itemPart.substring (0, colonIdx).strip ();
                        string val = itemPart.substring (colonIdx + 1).strip ();
                        if (val.length > 0) {
                            inlineMapping.mapPut (key,
                                                  parseInlineValue (val,
                                                                    lines,
                                                                    ref pos,
                                                                    baseIndent + 2));
                        } else {
                            inlineMapping.mapPut (key,
                                                  parseBlock (lines, ref pos, baseIndent + 2)
                                                  ?? YamlValue.ofNull ());
                        }
                        // Read remaining keys at the same inline level
                        while (pos < lines.length) {
                            skipEmptyAndComments (lines, ref pos);
                            if (pos >= lines.length) {
                                break;
                            }
                            string nextLine = lines[pos];
                            int nextIndent = countIndent (nextLine);
                            if (nextIndent <= baseIndent) {
                                break;
                            }
                            string nextTrimmed = stripComment (nextLine.strip ());
                            int nextColon = findColonSeparator (nextTrimmed);
                            if (nextColon <= 0) {
                                break;
                            }
                            string nkey = nextTrimmed.substring (0, nextColon).strip ();
                            string nval = nextTrimmed.substring (nextColon + 1).strip ();
                            pos++;
                            if (nval.length > 0) {
                                inlineMapping.mapPut (nkey,
                                                      parseInlineValue (nval,
                                                                        lines,
                                                                        ref pos,
                                                                        nextIndent + 1));
                            } else {
                                inlineMapping.mapPut (nkey,
                                                      parseBlock (lines, ref pos, nextIndent + 1)
                                                      ?? YamlValue.ofNull ());
                            }
                        }
                        item = inlineMapping;
                    } else if (itemPart.has_prefix ("[")) {
                        item = parseFlowSequence (itemPart);
                    } else if (itemPart.has_prefix ("{")) {
                        item = parseFlowMapping (itemPart);
                    } else {
                        item = parseScalar (itemPart);
                    }
                }
                seq.listAdd (item);
            }
            return seq;
        }

        private static YamlValue parseMultilineString (string[] lines, ref int pos,
                                                       int minIndent, bool literal) {
            var sb = new GLib.StringBuilder ();
            bool first = true;
            while (pos < lines.length) {
                string line = lines[pos];
                if (line.strip ().length == 0) {
                    sb.append ("\n");
                    pos++;
                    continue;
                }
                int indent = countIndent (line);
                if (indent < minIndent) {
                    break;
                }
                if (!first) {
                    if (literal) {
                        sb.append ("\n");
                    } else {
                        sb.append (" ");
                    }
                }
                sb.append (line.substring (minIndent < line.length ? minIndent : 0).chomp ());
                first = false;
                pos++;
            }
            return YamlValue.ofString (sb.str);
        }

        private static YamlValue parseFlowSequence (string text) {
            var seq = YamlValue.ofSequence ();
            string inner = text.strip ();
            if (inner.has_prefix ("[")) {
                inner = inner.substring (1);
            }
            if (inner.has_suffix ("]")) {
                inner = inner.substring (0, inner.length - 1);
            }
            if (inner.strip ().length == 0) {
                return seq;
            }
            string[] items = splitFlowItems (inner);
            foreach (string item in items) {
                string trimmed = item.strip ();
                if (trimmed.length > 0) {
                    seq.listAdd (parseFlowValue (trimmed));
                }
            }
            return seq;
        }

        private static YamlValue parseFlowMapping (string text) {
            var mapping = YamlValue.ofMapping ();
            string inner = text.strip ();
            if (inner.has_prefix ("{")) {
                inner = inner.substring (1);
            }
            if (inner.has_suffix ("}")) {
                inner = inner.substring (0, inner.length - 1);
            }
            if (inner.strip ().length == 0) {
                return mapping;
            }
            string[] pairs = splitFlowItems (inner);
            foreach (string pair in pairs) {
                string trimmed = pair.strip ();
                int colonIdx = findColonSeparator (trimmed);
                if (colonIdx > 0) {
                    string key = trimmed.substring (0, colonIdx).strip ();
                    string val = trimmed.substring (colonIdx + 1).strip ();
                    mapping.mapPut (key, parseFlowValue (val));
                }
            }
            return mapping;
        }

        private static YamlValue parseInlineValue (string valuePart, string[] lines, ref int pos,
                                                   int blockIndent) {
            string val = valuePart.strip ();
            if (val.has_prefix ("[")) {
                return parseFlowSequence (val);
            }
            if (val.has_prefix ("{")) {
                return parseFlowMapping (val);
            }
            if (val.has_prefix ("|") || val.has_prefix (">")) {
                return parseMultilineString (lines, ref pos, blockIndent, val.has_prefix ("|"));
            }
            return parseScalar (val);
        }

        private static YamlValue parseFlowValue (string text) {
            string trimmed = text.strip ();
            if (trimmed.has_prefix ("{")) {
                return parseFlowMapping (trimmed);
            }
            if (trimmed.has_prefix ("[")) {
                return parseFlowSequence (trimmed);
            }
            return parseScalar (trimmed);
        }

        private static string[] splitFlowItems (string text) {
            var items = new GLib.Array<string> ();
            int depth = 0;
            int start = 0;
            char quote = 0;
            bool escaped = false;
            for (int i = 0; i < text.length; i++) {
                char c = text[i];

                if (quote != 0) {
                    if (escaped) {
                        escaped = false;
                        continue;
                    }
                    if (quote == '"' && c == '\\') {
                        escaped = true;
                        continue;
                    }
                    if (c == quote) {
                        quote = 0;
                    }
                    continue;
                }

                if (c == '"' || c == '\'') {
                    quote = c;
                    continue;
                }
                if (c == '[' || c == '{') {
                    depth++;
                } else if (c == ']' || c == '}') {
                    depth--;
                } else if (c == ',' && depth == 0) {
                    items.append_val (text.substring (start, i - start));
                    start = i + 1;
                }
            }
            if (start < text.length) {
                items.append_val (text.substring (start));
            }
            string[] result = new string[items.length];
            for (uint i = 0; i < items.length; i++) {
                result[i] = items.index (i);
            }
            return result;
        }

        private static YamlValue parseScalar (string text) {
            string val = text.strip ();

            // Remove surrounding quotes
            if (val.length >= 2) {
                if ((val[0] == '"' && val[val.length - 1] == '"')
                    || (val[0] == '\'' && val[val.length - 1] == '\'')) {
                    string inner = val.substring (1, val.length - 2);
                    if (val[0] == '\'') {
                        return YamlValue.ofString (inner.replace ("''", "'"));
                    }
                    return YamlValue.ofString (unescapeQuotedScalar (inner));
                }
            }

            // Null
            if (val == "null" || val == "~" || val == "") {
                return YamlValue.ofNull ();
            }

            // Boolean
            if (val == "true" || val == "True" || val == "TRUE"
                || val == "yes" || val == "Yes" || val == "YES"
                || val == "on" || val == "On" || val == "ON") {
                return YamlValue.ofBool (true);
            }
            if (val == "false" || val == "False" || val == "FALSE"
                || val == "no" || val == "No" || val == "NO"
                || val == "off" || val == "Off" || val == "OFF") {
                return YamlValue.ofBool (false);
            }

            // Integer
            int64 intVal;
            if (int64.try_parse (val, out intVal)) {
                // Make sure it's not a float string like "1.0"
                if (!val.contains (".")) {
                    return YamlValue.ofInt (intVal);
                }
            }

            // Double
            double dblVal;
            if (double.try_parse (val, out dblVal)) {
                return YamlValue.ofDouble (dblVal);
            }

            return YamlValue.ofString (val);
        }

        private static string unescapeQuotedScalar (string input) {
            var sb = new GLib.StringBuilder ();
            for (int i = 0; i < input.length; i++) {
                char c = input[i];
                if (c != '\\') {
                    sb.append_c (c);
                    continue;
                }
                if (i + 1 >= input.length) {
                    sb.append_c ('\\');
                    break;
                }

                i++;
                char esc = input[i];
                switch (esc) {
                    case 'n' :
                        sb.append_c ('\n');
                        break;
                    case 'r' :
                        sb.append_c ('\r');
                        break;
                    case 't' :
                        sb.append_c ('\t');
                        break;
                    case 'b' :
                        sb.append_c ('\b');
                        break;
                    case 'f' :
                        sb.append_c ('\f');
                        break;
                    case '\\' :
                        sb.append_c ('\\');
                        break;
                    case '"' :
                        sb.append_c ('"');
                        break;
                    case '\'' :
                        sb.append_c ('\'');
                        break;
                    case '0':
                        sb.append_c ('\0');
                        break;
                    case 'x':
                    {
                        int code = 0;
                        if (parseHexDigits (input, i + 1, 2, out code)) {
                            sb.append_unichar ((unichar) code);
                            i += 2;
                        } else {
                            sb.append ("\\x");
                        }
                        break;
                    }
                    case 'u':
                    {
                        int code = 0;
                        if (parseHexDigits (input, i + 1, 4, out code)) {
                            sb.append_unichar ((unichar) code);
                            i += 4;
                        } else {
                            sb.append ("\\u");
                        }
                        break;
                    }
                    default:
                        sb.append_c (esc);
                        break;
                }
            }
            return sb.str;
        }

        private static bool parseHexDigits (string text, int start, int count, out int value) {
            value = 0;
            if (start < 0 || start + count > text.length) {
                return false;
            }
            for (int i = 0; i < count; i++) {
                int d = hexDigitValue (text[start + i]);
                if (d < 0) {
                    return false;
                }
                value = (value << 4) | d;
            }
            return true;
        }

        private static int hexDigitValue (char c) {
            if (c >= '0' && c <= '9') {
                return c - '0';
            }
            if (c >= 'a' && c <= 'f') {
                return 10 + c - 'a';
            }
            if (c >= 'A' && c <= 'F') {
                return 10 + c - 'A';
            }
            return -1;
        }

        private static int countIndent (string line) {
            int count = 0;
            for (int i = 0; i < line.length; i++) {
                if (line[i] == ' ') {
                    count++;
                } else {
                    break;
                }
            }
            return count;
        }

        private static void skipEmptyAndComments (string[] lines, ref int pos) {
            while (pos < lines.length) {
                string trimmed = lines[pos].strip ();
                if (trimmed.length == 0 || trimmed.has_prefix ("#")) {
                    pos++;
                } else if (trimmed == "---" || trimmed == "...") {
                    pos++;
                } else {
                    break;
                }
            }
        }

        private static string stripComment (string line) {
            // Remove trailing comment (but not inside quotes)
            bool inSingleQuote = false;
            bool inDoubleQuote = false;
            for (int i = 0; i < line.length; i++) {
                char c = line[i];
                if (c == '\'' && !inDoubleQuote) {
                    inSingleQuote = !inSingleQuote;
                } else if (c == '"' && !inSingleQuote) {
                    inDoubleQuote = !inDoubleQuote;
                } else if (c == '#' && !inSingleQuote && !inDoubleQuote
                           && i > 0 && line[i - 1] == ' ') {
                    return line.substring (0, i).strip ();
                }
            }
            return line;
        }

        private static int findColonSeparator (string line) {
            // Find ":" that separates key/value, but not inside quotes.
            bool inSingleQuote = false;
            bool inDoubleQuote = false;
            for (int i = 0; i < line.length; i++) {
                char c = line[i];
                if (c == '\'' && !inDoubleQuote) {
                    inSingleQuote = !inSingleQuote;
                } else if (c == '"' && !inSingleQuote) {
                    inDoubleQuote = !inDoubleQuote;
                } else if (c == ':' && !inSingleQuote && !inDoubleQuote) {
                    if (i + 1 >= line.length) {
                        return i;
                    }
                    char next = line[i + 1];
                    // Keep common URL scheme literals (e.g., "http://...") as scalars.
                    if (next == '/' && i + 2 < line.length && line[i + 2] == '/') {
                        continue;
                    }
                    return i;
                }
            }
            return -1;
        }

        private static string[] splitDocuments (string yaml) {
            var docs = new GLib.Array<string> ();
            string[] lines = yaml.split ("\n");
            var current = new GLib.StringBuilder ();
            bool started = false;
            foreach (string line in lines) {
                if (line.strip () == "---") {
                    if (started && current.len > 0) {
                        docs.append_val (current.str);
                        current.truncate (0);
                    }
                    started = true;
                    continue;
                }
                if (line.strip () == "...") {
                    if (current.len > 0) {
                        docs.append_val (current.str);
                        current.truncate (0);
                    }
                    continue;
                }
                current.append (line);
                current.append ("\n");
            }
            if (current.len > 0) {
                docs.append_val (current.str);
            }
            string[] result = new string[docs.length];
            for (uint i = 0; i < docs.length; i++) {
                result[i] = docs.index (i);
            }
            return result;
        }

        private static string[] splitPath (string path) {
            var parts = new GLib.Array<string> ();
            var current = new GLib.StringBuilder ();
            for (int i = 0; i < path.length; i++) {
                char c = path[i];
                if (c == '.') {
                    if (current.len > 0) {
                        parts.append_val (current.str);
                        current.truncate (0);
                    }
                } else {
                    current.append_c (c);
                }
            }
            if (current.len > 0) {
                parts.append_val (current.str);
            }
            string[] result = new string[parts.length];
            for (uint i = 0; i < parts.length; i++) {
                result[i] = parts.index (i);
            }
            return result;
        }

        // --- Serializer ---

        private static void writeValue (YamlValue value, GLib.StringBuilder sb,
                                        int indent, bool inlineItem) {
            if (value.isNull ()) {
                sb.append ("null\n");
            } else if (value.isString ()) {
                string s = value.asString ();
                if (needsQuoting (s)) {
                    sb.append ("\"");
                    sb.append (escapeYamlString (s));
                    sb.append ("\"\n");
                } else {
                    sb.append (s);
                    sb.append ("\n");
                }
            } else if (value.isInt ()) {
                sb.append (value.asInt ().to_string ());
                sb.append ("\n");
            } else if (value.isDouble ()) {
                sb.append (value.asDouble ().to_string ());
                sb.append ("\n");
            } else if (value.isBool ()) {
                sb.append (value.asBool () ? "true" : "false");
                sb.append ("\n");
            } else if (value.isMapping ()) {
                ArrayList<string> ? keysList = value.keys ();
                if (keysList == null || keysList.size () == 0) {
                    sb.append ("{}\n");
                    return;
                }
                for (int i = 0; i < keysList.size (); i++) {
                    string key = keysList.get (i);
                    YamlValue ? val = value.get (key);
                    appendIndent (sb, indent);
                    sb.append (key);
                    sb.append (":");
                    if (val != null && (val.isMapping () || val.isSequence ())
                        && val.size () > 0) {
                        sb.append ("\n");
                        writeValue (val, sb, indent + 2, false);
                    } else {
                        sb.append (" ");
                        writeValue (val ?? YamlValue.ofNull (), sb, indent + 2, false);
                    }
                }
            } else if (value.isSequence ()) {
                if (value.size () == 0) {
                    sb.append ("[]\n");
                    return;
                }
                for (int i = 0; i < value.size (); i++) {
                    YamlValue ? item = value.at (i);
                    appendIndent (sb, indent);
                    sb.append ("- ");
                    if (item != null && item.isMapping () && item.size () > 0) {
                        // Inline first key
                        ArrayList<string> ? mkeys = item.keys ();
                        if (mkeys != null && mkeys.size () > 0) {
                            string firstKey = mkeys.get (0);
                            YamlValue ? firstVal = item.get (firstKey);
                            sb.append (firstKey);
                            sb.append (": ");
                            writeValue (firstVal ?? YamlValue.ofNull (), sb, indent + 4, true);
                            for (int j = 1; j < mkeys.size (); j++) {
                                string k = mkeys.get (j);
                                YamlValue ? v = item.get (k);
                                appendIndent (sb, indent + 2);
                                sb.append (k);
                                sb.append (": ");
                                writeValue (v ?? YamlValue.ofNull (), sb, indent + 4, true);
                            }
                        }
                    } else {
                        writeValue (item ?? YamlValue.ofNull (), sb, indent + 2, true);
                    }
                }
            }
        }

        private static bool needsQuoting (string s) {
            if (s.length == 0) {
                return true;
            }
            if (s != s.strip ()) {
                return true;
            }
            string lower = s.down ();
            if (lower == "true" || lower == "false" || lower == "null"
                || lower == "yes" || lower == "no"
                || lower == "on" || lower == "off"
                || s == "~") {
                return true;
            }
            if (s.contains (":") || s.contains ("#") || s.contains ("\"")
                || s.contains ("'") || s.contains ("\n")
                || s.contains ("\r") || s.contains ("\t")) {
                return true;
            }
            // Check if it looks like a number
            int64 i;
            if (int64.try_parse (s, out i)) {
                return true;
            }
            double d;
            if (double.try_parse (s, out d)) {
                return true;
            }
            return false;
        }

        private static string escapeYamlString (string input) {
            var sb = new GLib.StringBuilder ();
            for (int i = 0; i < input.length; i++) {
                char c = input[i];
                switch (c) {
                    case '\\' :
                        sb.append ("\\\\");
                        break;
                    case '"' :
                        sb.append ("\\\"");
                        break;
                    case '\n' :
                        sb.append ("\\n");
                        break;
                    case '\r' :
                        sb.append ("\\r");
                        break;
                    case '\t' :
                        sb.append ("\\t");
                        break;
                    case '\0' :
                        sb.append ("\\0");
                        break;
                    default:
                        if ((uint) c < 0x20) {
                            sb.append ("\\u%04X".printf ((uint) c));
                        } else {
                            sb.append_c (c);
                        }
                        break;
                }
            }
            return sb.str;
        }

        private static void appendIndent (GLib.StringBuilder sb, int indent) {
            for (int i = 0; i < indent; i++) {
                sb.append_c (' ');
            }
        }
    }
}
