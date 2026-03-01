using Vala.Collections;
using Vala.Io;

namespace Vala.Encoding {
    /**
     * TOML value type.
     */
    public enum TomlValueType {
        TABLE,
        STRING,
        INT,
        BOOL,
        DOUBLE
    }

    /**
     * Represents one TOML value.
     */
    public class TomlValue : GLib.Object {
        private TomlValueType _type;
        private HashMap<string, TomlValue> ? _table;
        private string ? _string_value;
        private int64 _int_value;
        private bool _bool_value;
        private double _double_value;

        private TomlValue (TomlValueType type) {
            _type = type;
            _table = null;
            _string_value = null;
            _int_value = 0;
            _bool_value = false;
            _double_value = 0.0;
        }

        /**
         * Creates table value.
         *
         * @return table value.
         */
        public static TomlValue table () {
            var value = new TomlValue (TomlValueType.TABLE);
            value._table = new HashMap<string, TomlValue> (GLib.str_hash, GLib.str_equal);
            return value;
        }

        /**
         * Creates string value.
         *
         * @param value string value.
         * @return TOML value.
         */
        public static TomlValue ofString (string value) {
            var result = new TomlValue (TomlValueType.STRING);
            result._string_value = value;
            return result;
        }

        /**
         * Creates integer value.
         *
         * @param value integer value.
         * @return TOML value.
         */
        public static TomlValue ofInt (int64 value) {
            var result = new TomlValue (TomlValueType.INT);
            result._int_value = value;
            return result;
        }

        /**
         * Creates boolean value.
         *
         * @param value boolean value.
         * @return TOML value.
         */
        public static TomlValue ofBool (bool value) {
            var result = new TomlValue (TomlValueType.BOOL);
            result._bool_value = value;
            return result;
        }

        /**
         * Creates double value.
         *
         * @param value floating-point value.
         * @return TOML value.
         */
        public static TomlValue ofDouble (double value) {
            var result = new TomlValue (TomlValueType.DOUBLE);
            result._double_value = value;
            return result;
        }

        /**
         * Returns value type.
         *
         * @return TOML value type.
         */
        public TomlValueType type () {
            return _type;
        }

        /**
         * Returns true when this value is table.
         *
         * @return true if table.
         */
        public bool isTable () {
            return _type == TomlValueType.TABLE;
        }

        /**
         * Returns child value by key.
         *
         * @param key key name.
         * @return child value or null.
         */
        public new TomlValue ? get (string key) {
            if (!isTable () || _table == null) {
                return null;
            }
            return _table.get (key);
        }

        /**
         * Sets child value for table.
         *
         * @param key key name.
         * @param value child value.
         */
        public void put (string key, TomlValue value) {
            if (!isTable () || _table == null) {
                return;
            }
            _table.put (key, value);
        }

        /**
         * Returns string representation when this is string value.
         *
         * @return string value or null.
         */
        public string ? asString () {
            if (_type != TomlValueType.STRING) {
                return null;
            }
            return _string_value;
        }

        /**
         * Returns integer representation when this is int value.
         *
         * @return integer value or null.
         */
        public int64 ? asInt () {
            if (_type != TomlValueType.INT) {
                return null;
            }
            return _int_value;
        }

        /**
         * Returns boolean representation when this is bool value.
         *
         * @return boolean value or null.
         */
        public bool ? asBool () {
            if (_type != TomlValueType.BOOL) {
                return null;
            }
            return _bool_value;
        }

        /**
         * Returns double representation when this is double value.
         *
         * @return double value or null.
         */
        public double ? asDouble () {
            if (_type != TomlValueType.DOUBLE) {
                return null;
            }
            return _double_value;
        }

        internal HashMap<string, TomlValue> ? asTable () {
            return _table;
        }
    }

    /**
     * Static utility methods for TOML parsing and querying.
     */
    public class Toml : GLib.Object {
        /**
         * Parses TOML text into TOML value tree.
         *
         * @param toml TOML text.
         * @return root table value or null when invalid.
         */
        public static TomlValue ? parse (string toml) {
            if (toml.strip ().length == 0) {
                return TomlValue.table ();
            }

            TomlValue root = TomlValue.table ();
            TomlValue current = root;
            string[] lines = toml.split ("\n");
            for (int i = 0; i < lines.length; i++) {
                string raw = stripComment (lines[i]).strip ();
                if (raw.length == 0) {
                    continue;
                }

                if (raw.has_prefix ("[") && raw.has_suffix ("]")) {
                    string section = raw.substring (1, raw.length - 2).strip ();
                    TomlValue ? sectionTable = ensureTablePath (root, section);
                    if (sectionTable == null) {
                        return null;
                    }
                    current = sectionTable;
                    continue;
                }

                int eq = raw.index_of ("=");
                if (eq <= 0 || eq >= raw.length - 1) {
                    return null;
                }

                string key = raw.substring (0, eq).strip ();
                string valueText = raw.substring (eq + 1).strip ();
                if (key.length == 0) {
                    return null;
                }

                TomlValue ? parsed = parseValue (valueText);
                if (parsed == null) {
                    return null;
                }
                current.put (key, parsed);
            }
            return root;
        }

        /**
         * Parses TOML file into TOML value tree.
         *
         * @param path TOML file path.
         * @return root table value or null when read/parse failed.
         */
        public static TomlValue ? parseFile (Vala.Io.Path path) {
            string ? text = Files.readAllText (path);
            if (text == null) {
                return null;
            }
            return parse (text);
        }

        /**
         * Converts TOML value tree into TOML text.
         *
         * @param value TOML value tree.
         * @return TOML text.
         */
        public static string stringify (TomlValue value) {
            if (!value.isTable ()) {
                return "";
            }

            var builder = new GLib.StringBuilder ();
            writeTable (value, "", builder);
            return builder.str;
        }

        /**
         * Gets value by dot-path.
         *
         * @param root root TOML value.
         * @param path dot path (example: "server.port").
         * @return TOML value or null when path not found.
         */
        public static new TomlValue ? get (TomlValue root, string path) {
            if (!root.isTable () || path.strip ().length == 0) {
                return null;
            }

            TomlValue current = root;
            string[] parts = path.split (".");
            for (int i = 0; i < parts.length; i++) {
                string key = parts[i].strip ();
                if (key.length == 0) {
                    return null;
                }

                TomlValue ? next = current.get (key);
                if (next == null) {
                    return null;
                }

                if (i < parts.length - 1 && !next.isTable ()) {
                    return null;
                }
                current = next;
            }
            return current;
        }

        /**
         * Gets string value by path with fallback.
         *
         * @param root root TOML value.
         * @param path dot path.
         * @param fallback fallback string.
         * @return string value or fallback.
         */
        public static string getStringOr (TomlValue root, string path, string fallback) {
            TomlValue ? value = get (root, path);
            if (value == null) {
                return fallback;
            }
            string ? text = value.asString ();
            return text ?? fallback;
        }

        /**
         * Gets int value by path with fallback.
         *
         * @param root root TOML value.
         * @param path dot path.
         * @param fallback fallback int.
         * @return int value or fallback.
         */
        public static int getIntOr (TomlValue root, string path, int fallback) {
            TomlValue ? value = get (root, path);
            if (value == null) {
                return fallback;
            }
            int64 ? number = value.asInt ();
            if (number == null) {
                return fallback;
            }
            if (number < int.MIN || number > int.MAX) {
                return fallback;
            }
            return (int) number;
        }

        private static string stripComment (string line) {
            bool inQuote = false;
            bool escaped = false;
            var out = new GLib.StringBuilder ();
            int i = 0;
            unichar c;
            while (line.get_next_char (ref i, out c)) {
                if (escaped) {
                    out.append_unichar (c);
                    escaped = false;
                    continue;
                }

                if (c == '\\') {
                    out.append_unichar (c);
                    escaped = true;
                    continue;
                }

                if (c == '"') {
                    inQuote = !inQuote;
                    out.append_unichar (c);
                    continue;
                }

                if (c == '#' && !inQuote) {
                    break;
                }
                out.append_unichar (c);
            }
            return out.str;
        }

        private static TomlValue ? ensureTablePath (TomlValue root, string path) {
            if (path.strip ().length == 0) {
                return null;
            }

            TomlValue current = root;
            string[] parts = path.split (".");
            for (int i = 0; i < parts.length; i++) {
                string key = parts[i].strip ();
                if (key.length == 0) {
                    return null;
                }

                TomlValue ? child = current.get (key);
                if (child == null) {
                    child = TomlValue.table ();
                    current.put (key, child);
                }

                if (!child.isTable ()) {
                    return null;
                }
                current = child;
            }
            return current;
        }

        private static TomlValue ? parseValue (string valueText) {
            string raw = valueText.strip ();
            if (raw.length == 0) {
                return null;
            }

            if (raw.has_prefix ("\"") && raw.has_suffix ("\"") && raw.length >= 2) {
                string inner = raw.substring (1, raw.length - 2);
                return TomlValue.ofString (unescapeString (inner));
            }

            if (raw == "true") {
                return TomlValue.ofBool (true);
            }
            if (raw == "false") {
                return TomlValue.ofBool (false);
            }

            int64 ivalue;
            if (int64.try_parse (raw, out ivalue)) {
                return TomlValue.ofInt (ivalue);
            }

            double dvalue;
            if (double.try_parse (raw, out dvalue)) {
                return TomlValue.ofDouble (dvalue);
            }

            return null;
        }

        private static string unescapeString (string text) {
            var out = new GLib.StringBuilder ();
            bool escaped = false;
            for (int i = 0; i < text.length; i++) {
                char c = text[i];
                if (!escaped) {
                    if (c == '\\') {
                        escaped = true;
                        continue;
                    }
                    out.append_c (c);
                    continue;
                }

                escaped = false;
                switch (c) {
                    case 'n' :
                        out.append_c ('\n');
                        break;
                    case 't' :
                        out.append_c ('\t');
                        break;
                    case '"' :
                        out.append_c ('"');
                        break;
                    case '\\' :
                        out.append_c ('\\');
                        break;
                        default :
                        out.append_c (c);
                        break;
                }
            }
            if (escaped) {
                out.append_c ('\\');
            }
            return out.str;
        }

        private static void writeTable (TomlValue table, string section, GLib.StringBuilder builder) {
            HashMap<string, TomlValue> ? map = table.asTable ();
            if (map == null) {
                return;
            }

            ArrayList<string> scalarKeys = new ArrayList<string> (GLib.str_equal);
            ArrayList<string> tableKeys = new ArrayList<string> (GLib.str_equal);
            GLib.List<unowned string> keys = map.keys ();
            foreach (unowned string key in keys) {
                TomlValue ? value = map.get (key);
                if (value == null) {
                    continue;
                }
                if (value.isTable ()) {
                    tableKeys.add (key);
                } else {
                    scalarKeys.add (key);
                }
            }

            scalarKeys.sort ((a, b) => {
                return a.collate (b);
            });
            tableKeys.sort ((a, b) => {
                return a.collate (b);
            });

            for (int i = 0; i < scalarKeys.size (); i++) {
                string ? key = scalarKeys.get (i);
                if (key == null) {
                    continue;
                }
                TomlValue ? value = map.get (key);
                if (value == null) {
                    continue;
                }
                builder.append (formatPair (key, value));
                builder.append ("\n");
            }

            for (int i = 0; i < tableKeys.size (); i++) {
                string ? key = tableKeys.get (i);
                if (key == null) {
                    continue;
                }
                TomlValue ? value = map.get (key);
                if (value == null || !value.isTable ()) {
                    continue;
                }

                string name = section.length == 0 ? key : "%s.%s".printf (section, key);
                if (builder.len > 0 && !builder.str.has_suffix ("\n\n")) {
                    builder.append ("\n");
                }
                builder.append ("[%s]\n".printf (name));
                writeTable (value, name, builder);
            }
        }

        private static string formatPair (string key, TomlValue value) {
            switch (value.type ()) {
                case TomlValueType.STRING :
                    string text = value.asString () ?? "";
                    return "%s = \"%s\"".printf (key, escapeString (text));
                case TomlValueType.INT :
                    int64 ? ivalue = value.asInt ();
                    return "%s = %s".printf (key, ivalue != null ? ivalue.to_string () : "0");
                case TomlValueType.BOOL :
                    bool ? bvalue = value.asBool ();
                    return "%s = %s".printf (key, bvalue != null && bvalue ? "true" : "false");
                case TomlValueType.DOUBLE :
                    double ? dvalue = value.asDouble ();
                    return "%s = %s".printf (key, dvalue != null ? dvalue.to_string () : "0.0");
                    default :
                    return "";
            }
        }

        private static string escapeString (string text) {
            var out = new GLib.StringBuilder ();
            for (int i = 0; i < text.length; i++) {
                char c = text[i];
                switch (c) {
                    case '\\' :
                        out.append ("\\\\");
                        break;
                    case '"' :
                        out.append ("\\\"");
                        break;
                    case '\n' :
                        out.append ("\\n");
                        break;
                    case '\t' :
                        out.append ("\\t");
                        break;
                        default :
                        out.append_c (c);
                        break;
                }
            }
            return out.str;
        }
    }
}
