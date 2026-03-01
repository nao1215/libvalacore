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
         * Merges two maps into a new map.
         * When both maps contain the same key, the value from
         * the second map takes priority.
         *
         * @param a the base map.
         * @param b the override map.
         * @param hash_func hash function for key type K.
         * @param equal_func equality function for key type K.
         * @return a new merged map.
         */
        public static HashMap<K, V> merge<K, V> (HashMap<K, V> a,
                                                 HashMap<K, V> b,
                                                 GLib.HashFunc<K> hash_func,
                                                 GLib.EqualFunc<K> equal_func) {
            var result = new HashMap<K, V> (hash_func, equal_func);
            GLib.List<unowned K> aKeys = a.keys ();
            foreach (unowned K k in aKeys) {
                V ? v = a.get (k);
                if (v != null) {
                    result.put (k, v);
                }
            }
            GLib.List<unowned K> bKeys = b.keys ();
            foreach (unowned K k in bKeys) {
                V ? v = b.get (k);
                if (v != null) {
                    result.put (k, v);
                }
            }
            return result;
        }

        /**
         * Returns a new map containing only entries that match
         * the predicate.
         *
         * @param map the source map.
         * @param fn predicate taking key and value.
         * @param hash_func hash function for key type K.
         * @param equal_func equality function for key type K.
         * @return a new filtered map.
         */
        public static HashMap<K, V> filter<K, V> (HashMap<K, V> map,
                                                  owned BiPredicateFunc<K, V> fn,
                                                  GLib.HashFunc<K> hash_func,
                                                  GLib.EqualFunc<K> equal_func) {
            var result = new HashMap<K, V> (hash_func, equal_func);
            GLib.List<unowned K> keyList = map.keys ();
            foreach (unowned K k in keyList) {
                V ? v = map.get (k);
                if (v != null && fn (k, v)) {
                    result.put (k, v);
                }
            }
            return result;
        }

        /**
         * Returns a new map with transformed values and
         * preserved keys.
         *
         * @param map the source map.
         * @param fn value transformation function.
         * @param hash_func hash function for key type K.
         * @param equal_func equality function for key type K.
         * @return a new map with transformed values.
         */
        public static HashMap<K, U> mapValues<K, V, U> (HashMap<K, V> map,
                                                        owned MapFunc<V, U> fn,
                                                        GLib.HashFunc<K> hash_func,
                                                        GLib.EqualFunc<K> equal_func) {
            var result = new HashMap<K, U> (hash_func, equal_func);
            GLib.List<unowned K> keyList = map.keys ();
            foreach (unowned K k in keyList) {
                V ? v = map.get (k);
                if (v != null) {
                    result.put (k, fn (v));
                }
            }
            return result;
        }

        /**
         * Returns a new map with transformed keys and
         * preserved values.
         *
         * If multiple entries map to the same transformed key,
         * later entries overwrite earlier ones unless conflict
         * resolver is provided.
         *
         * @param map the source map.
         * @param fn key transformation function.
         * @param hash_func hash function for transformed key type J.
         * @param equal_func equality function for transformed key type J.
         * @param on_conflict optional resolver for key collisions.
         * @return a new map with transformed keys.
         */
        public static HashMap<J, V> mapKeys<K, V, J> (HashMap<K, V> map,
                                                      owned MapFunc<K, J> fn,
                                                      GLib.HashFunc<J> hash_func,
                                                      GLib.EqualFunc<J> equal_func,
                                                      owned ConflictResolverFunc<V> ? on_conflict = null) {
            var result = new HashMap<J, V> (hash_func, equal_func);
            GLib.List<unowned K> keyList = map.keys ();
            foreach (unowned K k in keyList) {
                V ? v = map.get (k);
                if (v != null) {
                    J newKey = fn (k);
                    if (on_conflict != null && result.containsKey (newKey)) {
                        V ? existing = result.get (newKey);
                        if (existing != null) {
                            result.put (newKey, on_conflict (existing, v));
                            continue;
                        }
                    }
                    result.put (newKey, v);
                }
            }
            return result;
        }

        /**
         * Returns a new map with keys and values swapped.
         *
         * If multiple entries map to the same value key, later entries
         * overwrite earlier ones unless conflict resolver is provided.
         *
         * @param map the source map.
         * @param hash_func hash function for value type V.
         * @param equal_func equality function for value type V.
         * @param on_conflict optional resolver for value-key collisions.
         * @return a new inverted map.
         */
        public static HashMap<V, K> invert<K, V> (HashMap<K, V> map,
                                                  GLib.HashFunc<V> hash_func,
                                                  GLib.EqualFunc<V> equal_func,
                                                  owned ConflictResolverFunc<K> ? on_conflict = null) {
            var result = new HashMap<V, K> (hash_func, equal_func);
            GLib.List<unowned K> keyList = map.keys ();
            foreach (unowned K k in keyList) {
                V ? v = map.get (k);
                if (v != null) {
                    if (on_conflict != null && result.containsKey (v)) {
                        K ? existing = result.get (v);
                        if (existing != null) {
                            result.put (v, on_conflict (existing, k));
                            continue;
                        }
                    }
                    result.put (v, k);
                }
            }
            return result;
        }

        /**
         * Returns the value for the key, or defaultValue
         * when key is missing.
         *
         * @param map the source map.
         * @param key the key to look up.
         * @param defaultValue fallback value for missing key.
         * @return the mapped value or fallback.
         */
        public static V getOrDefault<K, V> (HashMap<K, V> map, K key, V defaultValue) {
            if (map.containsKey (key)) {
                V ? v = map.get (key);
                if (v != null) {
                    return v;
                }
            }
            return defaultValue;
        }

        /**
         * Returns the value for the key. If absent, computes
         * value with fn, stores it, and returns it.
         *
         * @param map the map to query and update.
         * @param key the key to look up.
         * @param fn supplier function for missing values.
         * @return existing or computed value.
         */
        public static V computeIfAbsent<K, V> (HashMap<K, V> map,
                                               K key,
                                               owned SupplierFunc<V> fn) {
            if (map.containsKey (key)) {
                V ? v = map.get (key);
                if (v != null) {
                    return v;
                }
            }
            V value = fn ();
            map.put (key, value);
            return value;
        }

        /**
         * Returns all keys as an ArrayList.
         *
         * @param map the source map.
         * @return a list of keys.
         */
        public static ArrayList<K> keys<K, V> (HashMap<K, V> map) {
            var result = new ArrayList<K> ();
            GLib.List<unowned K> keyList = map.keys ();
            foreach (unowned K k in keyList) {
                result.add (k);
            }
            return result;
        }

        /**
         * Returns all values as an ArrayList.
         *
         * @param map the source map.
         * @return a list of values.
         */
        public static ArrayList<V> values<K, V> (HashMap<K, V> map) {
            var result = new ArrayList<V> ();
            GLib.List<unowned K> keyList = map.keys ();
            foreach (unowned K k in keyList) {
                V ? v = map.get (k);
                if (v != null) {
                    result.add (v);
                }
            }
            return result;
        }

        /**
         * Returns all key-value entries as Pair list.
         *
         * @param map the source map.
         * @return list of key-value pairs.
         */
        public static ArrayList<Pair<K, V> > entries<K, V> (HashMap<K, V> map) {
            var result = new ArrayList<Pair<K, V> > ();
            GLib.List<unowned K> keyList = map.keys ();
            foreach (unowned K k in keyList) {
                V ? v = map.get (k);
                if (v != null) {
                    result.add (new Pair<K, V> (k, v));
                }
            }
            return result;
        }

        /**
         * Creates a map from key-value pairs.
         *
         * If duplicate keys exist, later pairs overwrite earlier ones.
         *
         * @param pairs list of key-value pairs.
         * @param hash_func hash function for key type K.
         * @param equal_func equality function for key type K.
         * @return a new map.
         */
        public static HashMap<K, V> fromPairs<K, V> (ArrayList<Pair<K, V> > pairs,
                                                     GLib.HashFunc<K> hash_func,
                                                     GLib.EqualFunc<K> equal_func) {
            var result = new HashMap<K, V> (hash_func, equal_func);
            for (int i = 0; i < (int) pairs.size (); i++) {
                Pair<K, V> p = pairs.get (i);
                result.put (p.first (), p.second ());
            }
            return result;
        }

        /**
         * Returns whether the map has no entries.
         *
         * @param map the map to check.
         * @return true if map is empty.
         */
        public static bool isEmpty<K, V> (HashMap<K, V> map) {
            return map.isEmpty ();
        }

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
        public static HashMap<string, string> filterString (HashMap<string, string> map,
                                                            owned BiPredicateFunc<string, string> fn) {
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
        public static HashMap<string, string> mapValuesString (HashMap<string, string> map,
                                                               owned MapFunc<string, string> fn) {
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
         * later entries overwrite earlier ones unless conflict resolver is provided.
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
         * @param on_conflict optional resolver for key collisions.
         * @return a new HashMap with transformed keys.
         */
        public static HashMap<string, string> mapKeysString (HashMap<string, string> map,
                                                             owned MapFunc<string, string> fn,
                                                             owned ConflictResolverFunc<string> ? on_conflict = null) {
            var result = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            GLib.List<unowned string> keyList = map.keys ();
            foreach (unowned string k in keyList) {
                string ? v = map.get (k);
                if (v != null) {
                    string newKey = fn (k);
                    if (on_conflict != null && result.containsKey (newKey)) {
                        string ? existing = result.get (newKey);
                        if (existing != null) {
                            result.put (newKey, on_conflict (existing, v));
                            continue;
                        }
                    }
                    result.put (newKey, v);
                }
            }
            return result;
        }

        /**
         * Returns a new map with keys and values swapped.
         * If multiple entries have the same value, later entries
         * overwrite earlier ones in the result unless conflict resolver is provided.
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
         * @param on_conflict optional resolver for value-key collisions.
         * @return a new HashMap with keys and values swapped.
         */
        public static HashMap<string, string> invertString (HashMap<string, string> map,
                                                            owned ConflictResolverFunc<string> ? on_conflict = null) {
            var result = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            GLib.List<unowned string> keyList = map.keys ();
            foreach (unowned string k in keyList) {
                string ? v = map.get (k);
                if (v != null) {
                    if (on_conflict != null && result.containsKey (v)) {
                        string ? existing = result.get (v);
                        if (existing != null) {
                            result.put (v, on_conflict (existing, k));
                            continue;
                        }
                    }
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
        public static string computeIfAbsentString (HashMap<string, string> map,
                                                    string key,
                                                    owned SupplierFunc<string> fn) {
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

    /**
     * Resolves collision by choosing one of two values.
     *
     * @param existing value already stored.
     * @param incoming new value for the same key.
     * @return value to keep.
     */
    public delegate T ConflictResolverFunc<T> (T existing, T incoming);
}
