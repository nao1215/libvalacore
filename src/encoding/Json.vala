using Vala.Collections;
using Vala.Io;

namespace Vala.Encoding {
    /**
     * Recoverable JSON operation errors.
     */
    public errordomain JsonError {
        INVALID_PATH,
        NOT_FOUND
    }

    /**
     * JSON value type.
     */
    public enum JsonValueType {
        OBJECT,
        ARRAY,
        STRING,
        NUMBER_INT,
        NUMBER_DOUBLE,
        BOOL,
        NULL
    }

    /**
     * Represents one JSON value.
     *
     * JsonValue is the core type for all JSON data. It can represent
     * objects, arrays, strings, numbers, booleans, and null.
     *
     * Use factory methods to create values:
     * {{{
     *     var s = JsonValue.ofString ("hello");
     *     var n = JsonValue.ofInt (42);
     *     var obj = JsonValue.object ()
     *         .put ("name", JsonValue.ofString ("Alice"))
     *         .build ();
     * }}}
     */
    public class JsonValue : GLib.Object {
        private JsonValueType _type;
        private HashMap<string, JsonValue> ? _object;
        private ArrayList<JsonValue> ? _array;
        private string ? _string_value;
        private int _int_value;
        private double _double_value;
        private bool _bool_value;

        private JsonValue (JsonValueType type) {
            _type = type;
            _object = null;
            _array = null;
            _string_value = null;
            _int_value = 0;
            _double_value = 0.0;
            _bool_value = false;
        }

        /**
         * Creates a string JSON value.
         *
         * Example:
         * {{{
         *     var v = JsonValue.ofString ("hello");
         *     assert (v.asString () == "hello");
         * }}}
         *
         * @param value string content.
         * @return JSON string value.
         */
        public static JsonValue ofString (string value) {
            var result = new JsonValue (JsonValueType.STRING);
            result._string_value = value;
            return result;
        }

        /**
         * Creates an integer JSON value.
         *
         * Example:
         * {{{
         *     var v = JsonValue.ofInt (42);
         *     assert (v.asInt () == 42);
         * }}}
         *
         * @param value integer content.
         * @return JSON number value.
         */
        public static JsonValue ofInt (int value) {
            var result = new JsonValue (JsonValueType.NUMBER_INT);
            result._int_value = value;
            result._double_value = (double) value;
            return result;
        }

        /**
         * Creates a floating-point JSON value.
         *
         * Example:
         * {{{
         *     var v = JsonValue.ofDouble (3.14);
         * }}}
         *
         * @param value floating-point content.
         * @return JSON number value.
         */
        public static JsonValue ofDouble (double value) {
            var result = new JsonValue (JsonValueType.NUMBER_DOUBLE);
            result._double_value = value;
            result._int_value = (int) value;
            return result;
        }

        /**
         * Creates a boolean JSON value.
         *
         * Example:
         * {{{
         *     var v = JsonValue.ofBool (true);
         *     assert (v.asBool () == true);
         * }}}
         *
         * @param value boolean content.
         * @return JSON boolean value.
         */
        public static JsonValue ofBool (bool value) {
            var result = new JsonValue (JsonValueType.BOOL);
            result._bool_value = value;
            return result;
        }

        /**
         * Creates a null JSON value.
         *
         * Example:
         * {{{
         *     var v = JsonValue.ofNull ();
         *     assert (v.isNull ());
         * }}}
         *
         * @return JSON null value.
         */
        public static JsonValue ofNull () {
            return new JsonValue (JsonValueType.NULL);
        }

        /**
         * Creates a new JsonObjectBuilder for building JSON objects.
         *
         * Example:
         * {{{
         *     var obj = JsonValue.object ()
         *         .put ("name", JsonValue.ofString ("Alice"))
         *         .put ("age", JsonValue.ofInt (30))
         *         .build ();
         * }}}
         *
         * @return a new object builder.
         */
        public static JsonObjectBuilder object () {
            return new JsonObjectBuilder ();
        }

        /**
         * Creates a new JsonArrayBuilder for building JSON arrays.
         *
         * Example:
         * {{{
         *     var arr = JsonValue.array ()
         *         .add (JsonValue.ofInt (1))
         *         .add (JsonValue.ofInt (2))
         *         .build ();
         * }}}
         *
         * @return a new array builder.
         */
        public static JsonArrayBuilder array () {
            return new JsonArrayBuilder ();
        }

        /**
         * Creates a JSON object value directly from a HashMap.
         *
         * @param map the key-value pairs.
         * @return JSON object value.
         */
        internal static JsonValue fromObject (HashMap<string, JsonValue> map) {
            var result = new JsonValue (JsonValueType.OBJECT);
            result._object = map;
            return result;
        }

        /**
         * Creates a JSON array value directly from an ArrayList.
         *
         * @param list the elements.
         * @return JSON array value.
         */
        internal static JsonValue fromArray (ArrayList<JsonValue> list) {
            var result = new JsonValue (JsonValueType.ARRAY);
            result._array = list;
            return result;
        }

        // --- Type checks ---

        /**
         * Returns true if this value is a JSON object.
         *
         * @return true if object type.
         */
        public bool isObject () {
            return _type == JsonValueType.OBJECT;
        }

        /**
         * Returns true if this value is a JSON array.
         *
         * @return true if array type.
         */
        public bool isArray () {
            return _type == JsonValueType.ARRAY;
        }

        /**
         * Returns true if this value is a JSON string.
         *
         * @return true if string type.
         */
        public bool isString () {
            return _type == JsonValueType.STRING;
        }

        /**
         * Returns true if this value is a JSON number (int or double).
         *
         * @return true if number type.
         */
        public bool isNumber () {
            return _type == JsonValueType.NUMBER_INT || _type == JsonValueType.NUMBER_DOUBLE;
        }

        /**
         * Returns true if this value is a JSON boolean.
         *
         * @return true if boolean type.
         */
        public bool isBool () {
            return _type == JsonValueType.BOOL;
        }

        /**
         * Returns true if this value is JSON null.
         *
         * @return true if null type.
         */
        public bool isNull () {
            return _type == JsonValueType.NULL;
        }

        // --- Type-safe getters ---

        /**
         * Returns the string content if this is a string value.
         *
         * @return string value or null if not a string.
         */
        public string ? asString () {
            if (_type != JsonValueType.STRING) {
                return null;
            }
            return _string_value;
        }

        /**
         * Returns the integer content if this is a number value.
         *
         * @return integer value or null if not a number.
         */
        public int ? asInt () {
            if (_type != JsonValueType.NUMBER_INT && _type != JsonValueType.NUMBER_DOUBLE) {
                return null;
            }
            return _int_value;
        }

        /**
         * Returns the double content if this is a number value.
         *
         * @return double value or null if not a number.
         */
        public double ? asDouble () {
            if (_type != JsonValueType.NUMBER_INT && _type != JsonValueType.NUMBER_DOUBLE) {
                return null;
            }
            return _double_value;
        }

        /**
         * Returns the boolean content if this is a boolean value.
         *
         * @return boolean value or null if not a boolean.
         */
        public bool ? asBool () {
            if (_type != JsonValueType.BOOL) {
                return null;
            }
            return _bool_value;
        }

        // --- Fallback getters ---

        /**
         * Returns the string content or a fallback if not a string.
         *
         * @param fallback value to return if not a string.
         * @return string value or fallback.
         */
        public string asStringOr (string fallback) {
            string ? s = asString ();
            return s ?? fallback;
        }

        /**
         * Returns the integer content or a fallback if not a number.
         *
         * @param fallback value to return if not a number.
         * @return integer value or fallback.
         */
        public int asIntOr (int fallback) {
            int ? i = asInt ();
            if (i == null) {
                return fallback;
            }
            return i;
        }

        // --- Object/Array access ---

        /**
         * Returns the value for a key in a JSON object.
         *
         * @param key the key to look up.
         * @return the value or null if not found or not an object.
         */
        public new JsonValue ? get (string key) {
            if (_type != JsonValueType.OBJECT || _object == null) {
                return null;
            }
            return _object.get (key);
        }

        /**
         * Returns the value at an index in a JSON array.
         *
         * @param index zero-based array index.
         * @return the value or null if out of bounds or not an array.
         */
        public JsonValue ? at (int index) {
            if (_type != JsonValueType.ARRAY || _array == null) {
                return null;
            }
            if (index < 0 || index >= _array.size ()) {
                return null;
            }
            return _array.get (index);
        }

        /**
         * Returns the keys of a JSON object.
         *
         * @return list of keys or null if not an object.
         */
        public ArrayList<string> ? keys () {
            if (_type != JsonValueType.OBJECT || _object == null) {
                return null;
            }
            var result = new ArrayList<string> (GLib.str_equal);
            GLib.List<unowned string> k = _object.keys ();
            foreach (unowned string key in k) {
                result.add (key);
            }
            return result;
        }

        /**
         * Returns the number of entries (object keys or array elements).
         *
         * @return entry count, or 0 if not an object or array.
         */
        public int size () {
            if (_type == JsonValueType.OBJECT && _object != null) {
                return (int) _object.size ();
            }
            if (_type == JsonValueType.ARRAY && _array != null) {
                return (int) _array.size ();
            }
            return 0;
        }

        /**
         * Converts a JSON array to an ArrayList.
         *
         * @return list of values or null if not an array.
         */
        public ArrayList<JsonValue> ? toList () {
            if (_type != JsonValueType.ARRAY || _array == null) {
                return null;
            }
            var result = new ArrayList<JsonValue> ();
            for (int i = 0; i < _array.size (); i++) {
                JsonValue ? v = _array.get (i);
                if (v != null) {
                    result.add (v);
                }
            }
            return result;
        }

        /**
         * Structural equality comparison.
         *
         * Two JSON values are equal if they have the same type and
         * the same content. Objects are compared key-by-key; arrays
         * are compared element-by-element.
         *
         * @param other the other value.
         * @return true if structurally equal.
         */
        public bool equals (JsonValue other) {
            if (_type != other._type) {
                return false;
            }
            switch (_type) {
                case JsonValueType.NULL :
                    return true;
                case JsonValueType.BOOL :
                    return _bool_value == other._bool_value;
                case JsonValueType.NUMBER_INT :
                    return _int_value == other._int_value;
                case JsonValueType.NUMBER_DOUBLE :
                    return (_double_value - other._double_value).abs () < 1e-10;
                case JsonValueType.STRING :
                    return _string_value == other._string_value;
                case JsonValueType.OBJECT :
                    return objectEquals (other);
                case JsonValueType.ARRAY :
                    return arrayEquals (other);
                default:
                    return false;
            }
        }

        private bool objectEquals (JsonValue other) {
            if (_object == null || other._object == null) {
                return _object == null && other._object == null;
            }
            if (_object.size () != other._object.size ()) {
                return false;
            }
            GLib.List<unowned string> k = _object.keys ();
            foreach (unowned string key in k) {
                JsonValue ? v1 = _object.get (key);
                JsonValue ? v2 = other._object.get (key);
                if (v1 == null || v2 == null) {
                    return false;
                }
                if (!v1.equals (v2)) {
                    return false;
                }
            }
            return true;
        }

        private bool arrayEquals (JsonValue other) {
            if (_array == null || other._array == null) {
                return _array == null && other._array == null;
            }
            if (_array.size () != other._array.size ()) {
                return false;
            }
            for (int i = 0; i < _array.size (); i++) {
                JsonValue ? v1 = _array.get (i);
                JsonValue ? v2 = other._array.get (i);
                if (v1 == null || v2 == null) {
                    return false;
                }
                if (!v1.equals (v2)) {
                    return false;
                }
            }
            return true;
        }

        /**
         * Returns the internal object map (for internal use).
         */
        internal HashMap<string, JsonValue> ? asObject () {
            return _object;
        }

        /**
         * Returns the internal array list (for internal use).
         */
        internal ArrayList<JsonValue> ? asArrayList () {
            return _array;
        }

        /**
         * Returns the value type.
         *
         * @return JSON value type.
         */
        public JsonValueType valueType () {
            return _type;
        }
    }

    /**
     * Builder for constructing JSON objects fluently.
     *
     * Example:
     * {{{
     *     var obj = JsonValue.object ()
     *         .put ("name", JsonValue.ofString ("Alice"))
     *         .build ();
     * }}}
     */
    public class JsonObjectBuilder : GLib.Object {
        private HashMap<string, JsonValue> _map;

        internal JsonObjectBuilder () {
            _map = new HashMap<string, JsonValue> (GLib.str_hash, GLib.str_equal);
        }

        /**
         * Adds a key-value pair to the object.
         *
         * @param key the key.
         * @param value the value.
         * @return this builder for chaining.
         */
        public JsonObjectBuilder put (string key, JsonValue value) {
            _map.put (key, value);
            return this;
        }

        /**
         * Builds the JSON object value.
         *
         * @return the constructed JSON object.
         */
        public JsonValue build () {
            var snapshot = new HashMap<string, JsonValue> (GLib.str_hash, GLib.str_equal);
            GLib.List<unowned string> keys = _map.keys ();
            foreach (unowned string key in keys) {
                JsonValue ? value = _map.get (key);
                if (value != null) {
                    snapshot.put (key, value);
                }
            }
            _map = new HashMap<string, JsonValue> (GLib.str_hash, GLib.str_equal);
            return JsonValue.fromObject (snapshot);
        }
    }

    /**
     * Builder for constructing JSON arrays fluently.
     *
     * Example:
     * {{{
     *     var arr = JsonValue.array ()
     *         .add (JsonValue.ofInt (1))
     *         .add (JsonValue.ofInt (2))
     *         .build ();
     * }}}
     */
    public class JsonArrayBuilder : GLib.Object {
        private ArrayList<JsonValue> _list;

        internal JsonArrayBuilder () {
            _list = new ArrayList<JsonValue> ();
        }

        /**
         * Adds an element to the array.
         *
         * @param value the element.
         * @return this builder for chaining.
         */
        public JsonArrayBuilder add (JsonValue value) {
            _list.add (value);
            return this;
        }

        /**
         * Builds the JSON array value.
         *
         * @return the constructed JSON array.
         */
        public JsonValue build () {
            var snapshot = new ArrayList<JsonValue> ();
            for (int i = 0; i < _list.size (); i++) {
                JsonValue ? value = _list.get (i);
                if (value != null) {
                    snapshot.add (value);
                }
            }
            _list = new ArrayList<JsonValue> ();
            return JsonValue.fromArray (snapshot);
        }
    }

    /**
     * Static utility methods for JSON parsing, serialization, and querying.
     *
     * JSON is handled as a value tree rooted in JsonValue. The typical
     * workflow is `parse` -> `query` -> `asString` to reach data in
     * three steps.
     *
     * Example:
     * {{{
     *     var root = Json.parse ("{\"user\": {\"name\": \"Alice\"}}");
     *     var name = Json.getString (root, "$.user.name", "unknown");
     *     assert (name == "Alice");
     * }}}
     */
    public class Json : GLib.Object {
        /**
         * Parses a JSON string into a JsonValue tree.
         *
         * Example:
         * {{{
         *     JsonValue? v = Json.parse ("{\"a\": 1}");
         *     assert (v != null && v.isObject ());
         * }}}
         *
         * @param json the JSON text.
         * @return parsed value or null if invalid.
         */
        public static JsonValue ? parse (string json) {
            if (json.strip ().length == 0) {
                return null;
            }
            int pos = 0;
            JsonValue ? result = parseValue (json, ref pos);
            if (result == null) {
                return null;
            }
            skipWhitespace (json, ref pos);
            if (pos < json.length) {
                return null;
            }
            return result;
        }

        /**
         * Parses a JSON file into a JsonValue tree.
         *
         * Example:
         * {{{
         *     var root = Json.parseFile (new Path ("/path/to/data.json"));
         * }}}
         *
         * @param path the file path.
         * @return parsed value or null if read/parse failed.
         */
        public static JsonValue ? parseFile (Vala.Io.Path path) {
            string ? text = Files.readAllText (path);
            if (text == null) {
                return null;
            }
            return parse (text);
        }

        /**
         * Serializes a JsonValue tree to a compact JSON string.
         *
         * Example:
         * {{{
         *     string s = Json.stringify (value);
         * }}}
         *
         * @param value the value to serialize.
         * @return compact JSON string.
         */
        public static string stringify (JsonValue value) {
            var builder = new GLib.StringBuilder ();
            writeValue (value, builder, "", -1);
            return builder.str;
        }

        /**
         * Serializes a JsonValue tree to an indented JSON string.
         *
         * Example:
         * {{{
         *     string s = Json.pretty (value, 2);
         * }}}
         *
         * @param value the value to serialize.
         * @param indent spaces per indentation level (default 2).
         * @return indented JSON string.
         */
        public static string pretty (JsonValue value, int indent = 2) {
            var builder = new GLib.StringBuilder ();
            writeValue (value, builder, "", indent);
            builder.append ("\n");
            return builder.str;
        }

        /**
         * Queries a value by JSON path expression.
         *
         * Supports `$.key`, `$.key[index]`, and nested paths like
         * `$.users[0].address.city`.
         *
         * Example:
         * {{{
         *     var city = Json.query (root, "$.users[0].address.city");
         * }}}
         *
         * @param root the root value.
         * @param path the JSON path expression starting with `$`.
         * @return the value at the path or null if not found.
         */
        public static JsonValue ? query (JsonValue root, string path) {
            string p = path.strip ();
            if (p.length == 0) {
                return null;
            }
            if (p == "$") {
                return root;
            }
            if (!p.has_prefix ("$.")) {
                return null;
            }
            string rest = p.substring (2);
            return queryPath (root, rest);
        }

        /**
         * Returns a string value at the given path with a fallback.
         *
         * Example:
         * {{{
         *     string name = Json.getString (root, "$.user.name", "unknown");
         * }}}
         *
         * @param root root value.
         * @param path JSON path expression.
         * @param fallback value to return if path not found or type mismatch.
         * @return string value or fallback.
         */
        public static string getString (JsonValue root, string path, string fallback = "") {
            JsonValue ? v = query (root, path);
            if (v == null) {
                return fallback;
            }
            string ? s = v.asString ();
            return s ?? fallback;
        }

        /**
         * Returns an integer value at the given path with a fallback.
         *
         * Example:
         * {{{
         *     int count = Json.getInt (root, "$.count", 0);
         * }}}
         *
         * @param root root value.
         * @param path JSON path expression.
         * @param fallback value to return if path not found or type mismatch.
         * @return integer value or fallback.
         */
        public static int getInt (JsonValue root, string path, int fallback = 0) {
            JsonValue ? v = query (root, path);
            if (v == null) {
                return fallback;
            }
            int ? i = v.asInt ();
            if (i == null) {
                return fallback;
            }
            return i;
        }

        /**
         * Returns a boolean value at the given path with a fallback.
         *
         * Example:
         * {{{
         *     bool active = Json.getBool (root, "$.active", false);
         * }}}
         *
         * @param root root value.
         * @param path JSON path expression.
         * @param fallback value to return if path not found or type mismatch.
         * @return boolean value or fallback.
         */
        public static bool getBool (JsonValue root, string path, bool fallback = false) {
            JsonValue ? v = query (root, path);
            if (v == null) {
                return fallback;
            }
            bool ? b = v.asBool ();
            if (b == null) {
                return fallback;
            }
            return b;
        }

        /**
         * Returns a value at path or throws when missing.
         *
         * Example:
         * {{{
         *     JsonValue value = Json.must (root, "$.user.id");
         * }}}
         *
         * @param root root value.
         * @param path JSON path expression.
         * @return value at path.
         * @throws JsonError.INVALID_PATH when path is empty.
         * @throws JsonError.NOT_FOUND when no value exists at path.
         */
        public static JsonValue must (JsonValue root, string path) throws JsonError {
            if (path.strip ().length == 0) {
                throw new JsonError.INVALID_PATH ("path must not be empty");
            }
            JsonValue ? v = query (root, path);
            if (v == null) {
                throw new JsonError.NOT_FOUND ("value is required at path: %s".printf (path));
            }
            return v;
        }

        /**
         * Sets a value at the given path, returning a new tree.
         *
         * The original tree is not modified (immutable operation).
         * Only single-level set on object keys is supported
         * (e.g. `$.key`).
         *
         * Example:
         * {{{
         *     var updated = Json.set (root, "$.name", JsonValue.ofString ("Bob"));
         * }}}
         *
         * @param root root value (must be an object).
         * @param path JSON path expression (e.g. `$.key`).
         * @param value the value to set.
         * @return new tree with the value set, or null if path invalid.
         */
        public static new JsonValue ? set (JsonValue root, string path, JsonValue value) {
            if (!root.isObject ()) {
                return null;
            }
            string p = path.strip ();
            if (!p.has_prefix ("$.")) {
                return null;
            }
            string key = p.substring (2);
            if (key.length == 0) {
                return null;
            }

            var copy = deepCopyObject (root);
            if (copy == null) {
                return null;
            }
            HashMap<string, JsonValue> ? map = copy.asObject ();
            if (map == null) {
                return null;
            }
            map.put (key, value);
            return copy;
        }

        /**
         * Removes a key at the given path, returning a new tree.
         *
         * The original tree is not modified (immutable operation).
         *
         * Example:
         * {{{
         *     var cleaned = Json.remove (root, "$.temp");
         * }}}
         *
         * @param root root value (must be an object).
         * @param path JSON path expression (e.g. `$.key`).
         * @return new tree with the key removed, or null if path invalid.
         */
        public static JsonValue ? remove (JsonValue root, string path) {
            if (!root.isObject ()) {
                return null;
            }
            string p = path.strip ();
            if (!p.has_prefix ("$.")) {
                return null;
            }
            string key = p.substring (2);
            if (key.length == 0) {
                return null;
            }

            var copy = deepCopyObject (root);
            if (copy == null) {
                return null;
            }
            HashMap<string, JsonValue> ? map = copy.asObject ();
            if (map == null) {
                return null;
            }
            map.remove (key);
            return copy;
        }

        /**
         * Merges two JSON objects, with the second taking precedence.
         *
         * Returns a new tree. The originals are not modified.
         *
         * Example:
         * {{{
         *     var merged = Json.merge (defaults, overrides);
         * }}}
         *
         * @param a first object.
         * @param b second object (keys here override a).
         * @return merged object, or null if either is not an object.
         */
        public static JsonValue ? merge (JsonValue a, JsonValue b) {
            if (!a.isObject () || !b.isObject ()) {
                return null;
            }
            var builder = new JsonObjectBuilder ();
            HashMap<string, JsonValue> ? mapA = a.asObject ();
            HashMap<string, JsonValue> ? mapB = b.asObject ();
            if (mapA == null || mapB == null) {
                return null;
            }
            GLib.List<unowned string> keysA = mapA.keys ();
            foreach (unowned string key in keysA) {
                JsonValue ? v = mapA.get (key);
                if (v != null) {
                    builder.put (key, v);
                }
            }
            GLib.List<unowned string> keysB = mapB.keys ();
            foreach (unowned string key in keysB) {
                JsonValue ? v = mapB.get (key);
                if (v != null) {
                    builder.put (key, v);
                }
            }
            return builder.build ();
        }

        /**
         * Computes structural differences between two JSON values.
         *
         * The result is an array of objects:
         * `[{ "path": "$.x", "left": ..., "right": ... }]`
         *
         * @param a left JSON value.
         * @param b right JSON value.
         * @return array of diff entries.
         */
        public static JsonValue diff (JsonValue a, JsonValue b) {
            var builder = new JsonArrayBuilder ();
            diffRecurse (a, b, "$", builder);
            return builder.build ();
        }

        /**
         * Flattens a nested JSON object into dot-notation keys.
         *
         * Nested objects are converted to dot-notation keys.
         * For example, an object with nested key "a.b" becomes flat.
         *
         * Example:
         * {{{
         *     var flat = Json.flatten (root);
         *     var v = flat.get ("config.db.port");
         * }}}
         *
         * @param root the root value (must be an object).
         * @return flat map of dot-notation keys to leaf values,
         *         or null if not an object.
         */
        public static HashMap<string, JsonValue> ? flatten (JsonValue root) {
            if (!root.isObject ()) {
                return null;
            }
            var result = new HashMap<string, JsonValue> (GLib.str_hash, GLib.str_equal);
            flattenRecurse (root, "", result);
            return result;
        }

        // --- Internal parser ---

        private static void skipWhitespace (string json, ref int pos) {
            while (pos < json.length) {
                char c = json[pos];
                if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
                    pos++;
                } else {
                    break;
                }
            }
        }

        private static JsonValue ? parseValue (string json, ref int pos) {
            skipWhitespace (json, ref pos);
            if (pos >= json.length) {
                return null;
            }
            char c = json[pos];
            if (c == '"') {
                return parseString (json, ref pos);
            }
            if (c == '{') {
                return parseObject (json, ref pos);
            }
            if (c == '[') {
                return parseArray (json, ref pos);
            }
            if (c == 't' || c == 'f') {
                return parseBool (json, ref pos);
            }
            if (c == 'n') {
                return parseNull (json, ref pos);
            }
            if (c == '-' || (c >= '0' && c <= '9')) {
                return parseNumber (json, ref pos);
            }
            return null;
        }

        private static JsonValue ? parseString (string json, ref int pos) {
            if (pos >= json.length || json[pos] != '"') {
                return null;
            }
            pos++;
            var builder = new GLib.StringBuilder ();
            while (pos < json.length) {
                char c = json[pos];
                if (c == '"') {
                    pos++;
                    return JsonValue.ofString (builder.str);
                }
                if (c == '\\') {
                    pos++;
                    if (pos >= json.length) {
                        return null;
                    }
                    char esc = json[pos];
                    switch (esc) {
                        case '"' :
                            builder.append_c ('"');
                            break;
                        case '\\' :
                            builder.append_c ('\\');
                            break;
                        case '/' :
                            builder.append_c ('/');
                            break;
                        case 'b' :
                            builder.append_c ('\b');
                            break;
                        case 'f' :
                            builder.append_c ('\f');
                            break;
                        case 'n' :
                            builder.append_c ('\n');
                            break;
                        case 'r' :
                            builder.append_c ('\r');
                            break;
                        case 't' :
                            builder.append_c ('\t');
                            break;
                        case 'u' :
                            if (pos + 5 > json.length) {
                                return null;
                            }
                            uint high = 0;
                            if (!parseHex4 (json.substring (pos + 1, 4), out high)) {
                                return null;
                            }

                            if (high >= 0xD800 && high <= 0xDBFF) {
                                if (pos + 11 > json.length
                                    || json[pos + 5] != '\\'
                                    || json[pos + 6] != 'u') {
                                    return null;
                                }

                                uint low = 0;
                                if (!parseHex4 (json.substring (pos + 7, 4), out low)
                                    || low < 0xDC00 || low > 0xDFFF) {
                                    return null;
                                }

                                uint combined = 0x10000
                                                + ((high - 0xD800) << 10)
                                                + (low - 0xDC00);
                                builder.append (unicodeToUtf8 (combined));
                                pos += 10;
                            } else if (high >= 0xDC00 && high <= 0xDFFF) {
                                return null;
                            } else {
                                builder.append (unicodeToUtf8 (high));
                                pos += 4;
                            }
                            break;
                            default :
                            return null;
                    }
                } else {
                    if ((uint) c < 0x20) {
                        return null;
                    }
                    builder.append_c (c);
                }
                pos++;
            }
            return null;
        }

        private static bool parseHex4 (string hex, out uint result) {
            result = 0;
            if (hex.length < 4) {
                return false;
            }
            for (int i = 0; i < 4; i++) {
                char c = hex[i];
                uint digit;
                if (c >= '0' && c <= '9') {
                    digit = c - '0';
                } else if (c >= 'a' && c <= 'f') {
                    digit = 10 + c - 'a';
                } else if (c >= 'A' && c <= 'F') {
                    digit = 10 + c - 'A';
                } else {
                    return false;
                }
                result = (result << 4) | digit;
            }
            return true;
        }

        private static string unicodeToUtf8 (uint cp) {
            char[] buf = new char[5];
            if (cp < 0x80) {
                buf[0] = (char) cp;
                buf[1] = '\0';
            } else if (cp < 0x800) {
                buf[0] = (char) (0xC0 | (cp >> 6));
                buf[1] = (char) (0x80 | (cp & 0x3F));
                buf[2] = '\0';
            } else if (cp < 0x10000) {
                buf[0] = (char) (0xE0 | (cp >> 12));
                buf[1] = (char) (0x80 | ((cp >> 6) & 0x3F));
                buf[2] = (char) (0x80 | (cp & 0x3F));
                buf[3] = '\0';
            } else {
                buf[0] = (char) (0xF0 | (cp >> 18));
                buf[1] = (char) (0x80 | ((cp >> 12) & 0x3F));
                buf[2] = (char) (0x80 | ((cp >> 6) & 0x3F));
                buf[3] = (char) (0x80 | (cp & 0x3F));
                buf[4] = '\0';
            }
            return (string) buf;
        }

        private static JsonValue ? parseNumber (string json, ref int pos) {
            int start = pos;
            bool hasDecimal = false;
            bool hasExp = false;

            if (pos < json.length && json[pos] == '-') {
                pos++;
            }
            if (pos >= json.length || json[pos] < '0' || json[pos] > '9') {
                return null;
            }
            if (json[pos] == '0') {
                if (pos + 1 < json.length && json[pos + 1] >= '0' && json[pos + 1] <= '9') {
                    return null;
                }
                pos++;
            } else {
                while (pos < json.length && json[pos] >= '0' && json[pos] <= '9') {
                    pos++;
                }
            }
            if (pos < json.length && json[pos] == '.') {
                hasDecimal = true;
                pos++;
                if (pos >= json.length || json[pos] < '0' || json[pos] > '9') {
                    return null;
                }
                while (pos < json.length && json[pos] >= '0' && json[pos] <= '9') {
                    pos++;
                }
            }
            if (pos < json.length && (json[pos] == 'e' || json[pos] == 'E')) {
                hasExp = true;
                pos++;
                if (pos < json.length && (json[pos] == '+' || json[pos] == '-')) {
                    pos++;
                }
                if (pos >= json.length || json[pos] < '0' || json[pos] > '9') {
                    return null;
                }
                while (pos < json.length && json[pos] >= '0' && json[pos] <= '9') {
                    pos++;
                }
            }

            string numStr = json.substring (start, pos - start);
            if (hasDecimal || hasExp) {
                double d;
                if (double.try_parse (numStr, out d)) {
                    return JsonValue.ofDouble (d);
                }
                return null;
            }
            int64 i;
            if (int64.try_parse (numStr, out i)) {
                if (i >= int.MIN && i <= int.MAX) {
                    return JsonValue.ofInt ((int) i);
                }
                return JsonValue.ofDouble ((double) i);
            }
            return null;
        }

        private static JsonValue ? parseBool (string json, ref int pos) {
            if (pos + 4 <= json.length && json.substring (pos, 4) == "true") {
                pos += 4;
                return JsonValue.ofBool (true);
            }
            if (pos + 5 <= json.length && json.substring (pos, 5) == "false") {
                pos += 5;
                return JsonValue.ofBool (false);
            }
            return null;
        }

        private static JsonValue ? parseNull (string json, ref int pos) {
            if (pos + 4 <= json.length && json.substring (pos, 4) == "null") {
                pos += 4;
                return JsonValue.ofNull ();
            }
            return null;
        }

        private static JsonValue ? parseObject (string json, ref int pos) {
            if (pos >= json.length || json[pos] != '{') {
                return null;
            }
            pos++;
            skipWhitespace (json, ref pos);

            var map = new HashMap<string, JsonValue> (GLib.str_hash, GLib.str_equal);
            if (pos < json.length && json[pos] == '}') {
                pos++;
                return JsonValue.fromObject (map);
            }

            while (true) {
                skipWhitespace (json, ref pos);
                if (pos >= json.length || json[pos] != '"') {
                    return null;
                }
                JsonValue ? keyVal = parseString (json, ref pos);
                if (keyVal == null) {
                    return null;
                }
                string ? key = keyVal.asString ();
                if (key == null) {
                    return null;
                }

                skipWhitespace (json, ref pos);
                if (pos >= json.length || json[pos] != ':') {
                    return null;
                }
                pos++;

                JsonValue ? value = parseValue (json, ref pos);
                if (value == null) {
                    return null;
                }
                map.put (key, value);

                skipWhitespace (json, ref pos);
                if (pos >= json.length) {
                    return null;
                }
                if (json[pos] == '}') {
                    pos++;
                    return JsonValue.fromObject (map);
                }
                if (json[pos] != ',') {
                    return null;
                }
                pos++;
            }
        }

        private static JsonValue ? parseArray (string json, ref int pos) {
            if (pos >= json.length || json[pos] != '[') {
                return null;
            }
            pos++;
            skipWhitespace (json, ref pos);

            var list = new ArrayList<JsonValue> ();
            if (pos < json.length && json[pos] == ']') {
                pos++;
                return JsonValue.fromArray (list);
            }

            while (true) {
                JsonValue ? value = parseValue (json, ref pos);
                if (value == null) {
                    return null;
                }
                list.add (value);

                skipWhitespace (json, ref pos);
                if (pos >= json.length) {
                    return null;
                }
                if (json[pos] == ']') {
                    pos++;
                    return JsonValue.fromArray (list);
                }
                if (json[pos] != ',') {
                    return null;
                }
                pos++;
            }
        }

        // --- Serializer ---

        private static void writeValue (JsonValue value, GLib.StringBuilder builder,
                                        string currentIndent, int indentSize) {
            switch (value.valueType ()) {
                case JsonValueType.NULL :
                    builder.append ("null");
                    break;
                case JsonValueType.BOOL :
                    bool ? b = value.asBool ();
                    builder.append ((b != null && b) ? "true" : "false");
                    break;
                case JsonValueType.NUMBER_INT :
                    int ? i = value.asInt ();
                    builder.append (i != null ? i.to_string () : "0");
                    break;
                case JsonValueType.NUMBER_DOUBLE :
                    double ? d = value.asDouble ();
                    if (d != null) {
                        builder.append (formatDouble (d));
                    } else {
                        builder.append ("0");
                    }
                    break;
                case JsonValueType.STRING :
                    builder.append ("\"");
                    builder.append (escapeJsonString (value.asString () ?? ""));
                    builder.append ("\"");
                    break;
                case JsonValueType.OBJECT :
                    writeObject (value, builder, currentIndent, indentSize);
                    break;
                case JsonValueType.ARRAY :
                    writeArray (value, builder, currentIndent, indentSize);
                    break;
            }
        }

        private static string formatDouble (double d) {
            string s = "%g".printf (d);
            if (!s.contains (".") && !s.contains ("e") && !s.contains ("E")) {
                s += ".0";
            }
            return s;
        }

        private static void writeObject (JsonValue value, GLib.StringBuilder builder,
                                         string currentIndent, int indentSize) {
            HashMap<string, JsonValue> ? map = value.asObject ();
            if (map == null || map.size () == 0) {
                builder.append ("{}");
                return;
            }

            bool pretty = indentSize >= 0;
            string childIndent = pretty ? currentIndent + string.nfill (indentSize, ' ') : "";
            string nl = pretty ? "\n" : "";
            string sep = pretty ? ": " : ":";

            builder.append ("{");
            builder.append (nl);

            ArrayList<string> sortedKeys = new ArrayList<string> (GLib.str_equal);
            GLib.List<unowned string> k = map.keys ();
            foreach (unowned string key in k) {
                sortedKeys.add (key);
            }
            sortedKeys.sort ((a, b) => {
                return a.collate (b);
            });

            for (int i = 0; i < sortedKeys.size (); i++) {
                string ? key = sortedKeys.get (i);
                if (key == null) {
                    continue;
                }
                JsonValue ? v = map.get (key);
                if (v == null) {
                    continue;
                }
                if (pretty) {
                    builder.append (childIndent);
                }
                builder.append ("\"");
                builder.append (escapeJsonString (key));
                builder.append ("\"");
                builder.append (sep);
                writeValue (v, builder, childIndent, indentSize);
                if (i < sortedKeys.size () - 1) {
                    builder.append (",");
                }
                builder.append (nl);
            }

            if (pretty) {
                builder.append (currentIndent);
            }
            builder.append ("}");
        }

        private static void writeArray (JsonValue value, GLib.StringBuilder builder,
                                        string currentIndent, int indentSize) {
            ArrayList<JsonValue> ? list = value.asArrayList ();
            if (list == null || list.size () == 0) {
                builder.append ("[]");
                return;
            }

            bool pretty = indentSize >= 0;
            string childIndent = pretty ? currentIndent + string.nfill (indentSize, ' ') : "";
            string nl = pretty ? "\n" : "";

            builder.append ("[");
            builder.append (nl);

            for (int i = 0; i < list.size (); i++) {
                JsonValue ? v = list.get (i);
                if (v == null) {
                    continue;
                }
                if (pretty) {
                    builder.append (childIndent);
                }
                writeValue (v, builder, childIndent, indentSize);
                if (i < list.size () - 1) {
                    builder.append (",");
                }
                builder.append (nl);
            }

            if (pretty) {
                builder.append (currentIndent);
            }
            builder.append ("]");
        }

        private static string escapeJsonString (string text) {
            var builder = new GLib.StringBuilder ();
            for (int i = 0; i < text.length; i++) {
                char c = text[i];
                switch (c) {
                    case '\\' :
                        builder.append ("\\\\");
                        break;
                    case '"' :
                        builder.append ("\\\"");
                        break;
                    case '\n' :
                        builder.append ("\\n");
                        break;
                    case '\r' :
                        builder.append ("\\r");
                        break;
                    case '\t' :
                        builder.append ("\\t");
                        break;
                    case '\b' :
                        builder.append ("\\b");
                        break;
                    case '\f' :
                        builder.append ("\\f");
                        break;
                        default :
                        builder.append_c (c);
                        break;
                }
            }
            return builder.str;
        }

        // --- Query engine ---

        private static JsonValue ? queryPath (JsonValue current, string path) {
            if (path.length == 0) {
                return current;
            }

            int dotIdx = -1;
            int bracketIdx = -1;
            for (int i = 0; i < path.length; i++) {
                if (path[i] == '.' && dotIdx < 0 && bracketIdx < 0) {
                    dotIdx = i;
                    break;
                }
                if (path[i] == '[' && bracketIdx < 0) {
                    bracketIdx = i;
                    break;
                }
            }

            if (bracketIdx == 0) {
                int closeBracket = path.index_of ("]");
                if (closeBracket < 0) {
                    return null;
                }
                string indexStr = path.substring (1, closeBracket - 1);
                int64 idx;
                if (!int64.try_parse (indexStr, out idx)) {
                    return null;
                }
                JsonValue ? elem = current.at ((int) idx);
                if (elem == null) {
                    return null;
                }
                string remaining = path.substring (closeBracket + 1);
                if (remaining.has_prefix (".")) {
                    remaining = remaining.substring (1);
                }
                if (remaining.length == 0) {
                    return elem;
                }
                return queryPath (elem, remaining);
            }

            string key;
            string rest;

            if (bracketIdx > 0 && (dotIdx < 0 || bracketIdx < dotIdx)) {
                key = path.substring (0, bracketIdx);
                rest = path.substring (bracketIdx);
            } else if (dotIdx >= 0) {
                key = path.substring (0, dotIdx);
                rest = path.substring (dotIdx + 1);
            } else {
                key = path;
                rest = "";
            }

            JsonValue ? child = current.get (key);
            if (child == null) {
                return null;
            }
            if (rest.length == 0) {
                return child;
            }
            return queryPath (child, rest);
        }

        // --- Deep copy ---

        private static JsonValue ? deepCopyObject (JsonValue src) {
            if (!src.isObject ()) {
                return null;
            }
            HashMap<string, JsonValue> ? srcMap = src.asObject ();
            if (srcMap == null) {
                return null;
            }
            var builder = new JsonObjectBuilder ();
            GLib.List<unowned string> k = srcMap.keys ();
            foreach (unowned string key in k) {
                JsonValue ? v = srcMap.get (key);
                if (v != null) {
                    builder.put (key, v);
                }
            }
            return builder.build ();
        }

        // --- Diff helper ---

        private static void diffRecurse (JsonValue left,
                                         JsonValue right,
                                         string path,
                                         JsonArrayBuilder outBuilder) {
            if (left.valueType () != right.valueType ()) {
                appendDiff (outBuilder, path, left, right);
                return;
            }

            if (left.isObject () && right.isObject ()) {
                HashMap<string, JsonValue> ? leftMap = left.asObject ();
                HashMap<string, JsonValue> ? rightMap = right.asObject ();
                if (leftMap == null || rightMap == null) {
                    appendDiff (outBuilder, path, left, right);
                    return;
                }

                var keySet = new HashSet<string> (GLib.str_hash, GLib.str_equal);
                GLib.List<unowned string> leftKeys = leftMap.keys ();
                foreach (unowned string key in leftKeys) {
                    keySet.add (key);
                }
                GLib.List<unowned string> rightKeys = rightMap.keys ();
                foreach (unowned string key in rightKeys) {
                    keySet.add (key);
                }

                ArrayList<string> sortedKeys = new ArrayList<string> (GLib.str_equal);
                keySet.forEach ((key) => {
                    sortedKeys.add (key);
                });
                sortedKeys.sort ((a, b) => {
                    return a.collate (b);
                });

                for (int i = 0; i < sortedKeys.size (); i++) {
                    string key = sortedKeys.get (i);
                    JsonValue ? l = leftMap.get (key);
                    JsonValue ? r = rightMap.get (key);
                    string childPath = path + "." + key;
                    if (l == null || r == null) {
                        appendDiff (outBuilder, childPath, l, r);
                        continue;
                    }
                    diffRecurse (l, r, childPath, outBuilder);
                }
                return;
            }

            if (left.isArray () && right.isArray ()) {
                ArrayList<JsonValue> ? leftList = left.asArrayList ();
                ArrayList<JsonValue> ? rightList = right.asArrayList ();
                if (leftList == null || rightList == null) {
                    appendDiff (outBuilder, path, left, right);
                    return;
                }
                int max = int.max ((int) leftList.size (), (int) rightList.size ());
                for (int i = 0; i < max; i++) {
                    JsonValue ? l = i < leftList.size () ? leftList.get (i) : null;
                    JsonValue ? r = i < rightList.size () ? rightList.get (i) : null;
                    string childPath = "%s[%d]".printf (path, i);
                    if (l == null || r == null) {
                        appendDiff (outBuilder, childPath, l, r);
                        continue;
                    }
                    diffRecurse (l, r, childPath, outBuilder);
                }
                return;
            }

            if (!left.equals (right)) {
                appendDiff (outBuilder, path, left, right);
            }
        }

        private static void appendDiff (JsonArrayBuilder outBuilder,
                                        string path,
                                        JsonValue ? left,
                                        JsonValue ? right) {
            outBuilder.add (JsonValue.object ()
                             .put ("path", JsonValue.ofString (path))
                             .put ("left", left ?? JsonValue.ofNull ())
                             .put ("right", right ?? JsonValue.ofNull ())
                             .build ());
        }

        // --- Flatten helper ---

        private static void flattenRecurse (JsonValue value, string prefix,
                                            HashMap<string, JsonValue> result) {
            if (value.isObject ()) {
                HashMap<string, JsonValue> ? map = value.asObject ();
                if (map == null) {
                    return;
                }
                GLib.List<unowned string> k = map.keys ();
                foreach (unowned string key in k) {
                    JsonValue ? v = map.get (key);
                    if (v == null) {
                        continue;
                    }
                    string newPrefix = prefix.length == 0 ? key : prefix + "." + key;
                    flattenRecurse (v, newPrefix, result);
                }
            } else {
                result.put (prefix, value);
            }
        }
    }
}
