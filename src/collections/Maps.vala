namespace Vala.Collections {
    /**
     * Static utility methods for HashMap operations.
     *
     * Maps provides high-level operations like merge, filter, mapValues,
     * invert, and entries that would otherwise require 5-15 lines of
     * manual loop code.
     *
     * Example:
     * {{{
     *     var defaults = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
     *     defaults.put ("theme", "light");
     *     defaults.put ("lang", "en");
     *     var overrides = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
     *     overrides.put ("theme", "dark");
     *     var config = Maps.mergeString (defaults, overrides);
     *     // config: {"theme": "dark", "lang": "en"}
     * }}}
     */
    public class Maps : GLib.Object {
        /**
         * Merges two string maps into a new map.
         * When both maps contain the same key, the value from the
         * second map takes priority.
         *
         * Example:
         * {{{
         *     var defaults = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
         *     defaults.put ("theme", "light");
         *     defaults.put ("lang", "en");
         *     var overrides = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
         *     overrides.put ("theme", "dark");
         *     var merged = Maps.mergeString (defaults, overrides);
         *     // merged["theme"] == "dark", merged["lang"] == "en"
         * }}}
         *
         * @param a the base map.
         * @param b the override map (takes priority).
         * @return a new merged HashMap.
         */
        public static HashMap<string, string> mergeString (HashMap<string, string> a, HashMap<string, string> b) {
            var result = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            GLib.List<unowned string> aKeys = a.keys ();
            foreach (unowned string k in aKeys) {
                string ? v = a.get (k);
                if (v != null) {
                    result.put (k, v);
                }
            }
            GLib.List<unowned string> bKeys = b.keys ();
            foreach (unowned string k in bKeys) {
                string ? v = b.get (k);
                if (v != null) {
                    result.put (k, v);
                }
            }
            return result;
        }

        /**
         * Returns a new map containing only entries that match the predicate.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
         *     map.put ("name", "Alice");
         *     map.put ("age", "30");
         *     map.put ("note", "");
         *     var filtered = Maps.filterString (map, (k, v) => {
         *         return v.length > 0;
         *     });
         *     // filtered contains only "name" and "age"
         * }}}
         *
         * @param map the source map.
         * @param fn the predicate taking key and value.
         * @return a new filtered HashMap.
         */
        public static HashMap<string, string> filterString (HashMap<string, string> map, owned BiPredicateFunc<string, string> fn) {
            var result = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            GLib.List<unowned string> keyList = map.keys ();
            foreach (unowned string k in keyList) {
                string ? v = map.get (k);
                if (v != null && fn (k, v)) {
                    result.put (k, v);
                }
            }
            return result;
        }

        /**
         * Returns a new map with all values transformed by the function.
         * Keys are preserved.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
         *     map.put ("name", "alice");
         *     var upper = Maps.mapValuesString (map, (v) => { return v.up (); });
         *     // upper["name"] == "ALICE"
         * }}}
         *
         * @param map the source map.
         * @param fn the value transformation function.
         * @return a new HashMap with transformed values.
         */
        public static HashMap<string, string> mapValuesString (HashMap<string, string> map, owned MapFunc<string, string> fn) {
            var result = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            GLib.List<unowned string> keyList = map.keys ();
            foreach (unowned string k in keyList) {
                string ? v = map.get (k);
                if (v != null) {
                    result.put (k, fn (v));
                }
            }
            return result;
        }

        /**
         * Returns a new map with all keys transformed by the function.
         * Values are preserved. If multiple keys map to the same new key,
         * later entries overwrite earlier ones.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
         *     map.put ("Name", "Alice");
         *     var lower = Maps.mapKeysString (map, (k) => { return k.down (); });
         *     // lower["name"] == "Alice"
         * }}}
         *
         * @param map the source map.
         * @param fn the key transformation function.
         * @return a new HashMap with transformed keys.
         */
        public static HashMap<string, string> mapKeysString (HashMap<string, string> map, owned MapFunc<string, string> fn) {
            var result = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            GLib.List<unowned string> keyList = map.keys ();
            foreach (unowned string k in keyList) {
                string ? v = map.get (k);
                if (v != null) {
                    result.put (fn (k), v);
                }
            }
            return result;
        }

        /**
         * Returns a new map with keys and values swapped.
         * If multiple entries have the same value, later entries
         * overwrite earlier ones in the result.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
         *     map.put ("a", "1");
         *     map.put ("b", "2");
         *     var inv = Maps.invertString (map);
         *     // inv["1"] == "a", inv["2"] == "b"
         * }}}
         *
         * @param map the source map.
         * @return a new HashMap with keys and values swapped.
         */
        public static HashMap<string, string> invertString (HashMap<string, string> map) {
            var result = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            GLib.List<unowned string> keyList = map.keys ();
            foreach (unowned string k in keyList) {
                string ? v = map.get (k);
                if (v != null) {
                    result.put (v, k);
                }
            }
            return result;
        }

        /**
         * Returns the value for the key, or the default value if
         * the key is not found.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
         *     map.put ("host", "localhost");
         *     var host = Maps.getOrDefaultString (map, "host", "0.0.0.0");
         *     var port = Maps.getOrDefaultString (map, "port", "8080");
         *     // host == "localhost", port == "8080"
         * }}}
         *
         * @param map the source map.
         * @param key the key to look up.
         * @param defaultValue the value to return if key is absent.
         * @return the value for the key, or defaultValue.
         */
        public static string getOrDefaultString (HashMap<string, string> map, string key, string defaultValue) {
            if (map.containsKey (key)) {
                string ? v = map.get (key);
                if (v != null) {
                    return v;
                }
            }
            return defaultValue;
        }

        /**
         * Returns the value for the key. If the key is absent, computes
         * the value using the supplier function, stores it in the map,
         * and returns it.
         *
         * Note: this method modifies the original map when the key
         * is absent.
         *
         * Example:
         * {{{
         *     var cache = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
         *     var val = Maps.computeIfAbsentString (cache, "key", () => {
         *         return "computed";
         *     });
         *     // val == "computed", cache["key"] == "computed"
         * }}}
         *
         * @param map the map to query and potentially update.
         * @param key the key to look up.
         * @param fn the supplier function to compute the value if absent.
         * @return the existing or newly computed value.
         */
        public static string computeIfAbsentString (HashMap<string, string> map, string key, owned SupplierFunc<string> fn) {
            if (map.containsKey (key)) {
                string ? v = map.get (key);
                if (v != null) {
                    return v;
                }
            }
            string value = fn ();
            map.put (key, value);
            return value;
        }

        /**
         * Returns an ArrayList of all keys in the map.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
         *     map.put ("a", "1");
         *     map.put ("b", "2");
         *     var keyList = Maps.keysString (map);
         *     assert (keyList.size () == 2);
         * }}}
         *
         * @param map the source map.
         * @return an ArrayList of keys.
         */
        public static ArrayList<string> keysString (HashMap<string, string> map) {
            var result = new ArrayList<string> (GLib.str_equal);
            GLib.List<unowned string> keyList = map.keys ();
            foreach (unowned string k in keyList) {
                result.add (k);
            }
            return result;
        }

        /**
         * Returns an ArrayList of all values in the map.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
         *     map.put ("a", "1");
         *     map.put ("b", "2");
         *     var valList = Maps.valuesString (map);
         *     assert (valList.size () == 2);
         * }}}
         *
         * @param map the source map.
         * @return an ArrayList of values.
         */
        public static ArrayList<string> valuesString (HashMap<string, string> map) {
            var result = new ArrayList<string> (GLib.str_equal);
            GLib.List<unowned string> keyList = map.keys ();
            foreach (unowned string k in keyList) {
                string ? v = map.get (k);
                if (v != null) {
                    result.add (v);
                }
            }
            return result;
        }

        /**
         * Returns an ArrayList of key-value Pairs from the map.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
         *     map.put ("a", "1");
         *     var entries = Maps.entriesString (map);
         *     Pair<string, string> e = (Pair<string, string>) entries.get (0);
         *     // e.first () == "a", e.second () == "1"
         * }}}
         *
         * @param map the source map.
         * @return an ArrayList of Pair entries.
         */
        public static ArrayList<Pair<string, string> > entriesString (HashMap<string, string> map) {
            var result = new ArrayList<Pair<string, string> > ();
            GLib.List<unowned string> keyList = map.keys ();
            foreach (unowned string k in keyList) {
                string ? v = map.get (k);
                if (v != null) {
                    result.add (new Pair<string, string> (k, v));
                }
            }
            return result;
        }

        /**
         * Creates a HashMap from a list of key-value Pairs.
         * If duplicate keys exist, later Pairs overwrite earlier ones.
         *
         * Example:
         * {{{
         *     var pairs = new ArrayList<Pair<string, string> > ();
         *     pairs.add (new Pair<string, string> ("a", "1"));
         *     pairs.add (new Pair<string, string> ("b", "2"));
         *     var map = Maps.fromPairsString (pairs);
         *     // map["a"] == "1", map["b"] == "2"
         * }}}
         *
         * @param pairs the list of key-value Pairs.
         * @return a new HashMap.
         */
        public static HashMap<string, string> fromPairsString (ArrayList<Pair<string, string> > pairs) {
            var result = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            for (int i = 0; i < (int) pairs.size (); i++) {
                Pair<string, string> p = pairs.get (i);
                result.put ((string) p.first (), (string) p.second ());
            }
            return result;
        }

        /**
         * Returns whether the map is empty.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
         *     assert (Maps.isEmptyString (map));
         *     map.put ("key", "val");
         *     assert (!Maps.isEmptyString (map));
         * }}}
         *
         * @param map the map to check.
         * @return true if the map has no entries.
         */
        public static bool isEmptyString (HashMap<string, string> map) {
            return map.isEmpty ();
        }
    }

    /**
     * A function that takes two arguments and returns a boolean.
     *
     * @param a the first argument.
     * @param b the second argument.
     * @return true or false.
     */
    public delegate bool BiPredicateFunc<A, B> (A a, B b);
}
