namespace Vala.Collections {
    /**
     * A hash table-based map from keys to values.
     *
     * HashMap provides O(1) average-time lookup, insertion, and deletion.
     * Inspired by Java's HashMap and Go's map.
     *
     * For string keys and values, use GLib.str_hash and GLib.str_equal.
     *
     * Example:
     * {{{
     *     var map = new HashMap<string,string> (GLib.str_hash, GLib.str_equal);
     *     map.put ("name", "Alice");
     *     map.put ("city", "Tokyo");
     *     assert (map.get ("name") == "Alice");
     *     assert (map.size () == 2);
     * }}}
     */
    public class HashMap<K, V>: GLib.Object {
        private GLib.HashTable<K, V> _table;
        private GLib.HashFunc<K> _hash_func;
        private GLib.EqualFunc<K> _equal_func;

        /**
         * Creates an empty HashMap with the given hash and equality functions.
         *
         * For string keys, pass GLib.str_hash and GLib.str_equal.
         * For integer or pointer keys, pass GLib.direct_hash and
         * GLib.direct_equal.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string,string> (GLib.str_hash, GLib.str_equal);
         *     assert (map.isEmpty ());
         * }}}
         *
         * @param hash_func the hash function for keys.
         * @param equal_func the equality function for keys.
         */
        public HashMap (GLib.HashFunc<K> hash_func, GLib.EqualFunc<K> equal_func) {
            _hash_func = hash_func;
            _equal_func = equal_func;
            _table = new GLib.HashTable<K, V> (hash_func, equal_func);
        }

        /**
         * Associates the specified value with the specified key.
         * If the key already exists, the value is replaced.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string,string> (GLib.str_hash, GLib.str_equal);
         *     map.put ("key", "value");
         *     assert (map.get ("key") == "value");
         * }}}
         *
         * @param key the key.
         * @param value the value.
         */
        public void put (owned K key, owned V value) {
            _table.replace ((owned) key, (owned) value);
        }

        /**
         * Returns the value associated with the specified key.
         * Returns null if the key is not found.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string,string> (GLib.str_hash, GLib.str_equal);
         *     map.put ("key", "value");
         *     assert (map.get ("key") == "value");
         *     assert (map.get ("missing") == null);
         * }}}
         *
         * @param key the key to look up.
         * @return the associated value, or null if not found.
         */
        public new V ? get (K key) {
            return _table.lookup (key);
        }

        /**
         * Returns the value associated with the specified key, or the
         * default value if the key is not found.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string,string> (GLib.str_hash, GLib.str_equal);
         *     assert (map.getOrDefault ("missing", "fallback") == "fallback");
         * }}}
         *
         * @param key the key to look up.
         * @param defaultValue the value to return if the key is not found.
         * @return the associated value, or defaultValue if not found.
         */
        public V getOrDefault (K key, V defaultValue) {
            if (_table.contains (key)) {
                return _table.lookup (key);
            }
            return defaultValue;
        }

        /**
         * Returns whether the map contains the specified key.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string,string> (GLib.str_hash, GLib.str_equal);
         *     map.put ("key", "value");
         *     assert (map.containsKey ("key"));
         *     assert (!map.containsKey ("other"));
         * }}}
         *
         * @param key the key to check.
         * @return true if the key exists.
         */
        public bool containsKey (K key) {
            return _table.contains (key);
        }

        /**
         * Returns whether the map contains the specified value.
         * This requires a linear scan of all values.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string,string> (GLib.str_hash, GLib.str_equal);
         *     map.put ("key", "value");
         *     assert (map.containsValue ("value"));
         * }}}
         *
         * @param value the value to check.
         * @param value_equal the equality function for values.
         * @return true if the value exists.
         */
        public bool containsValue (V value, GLib.EqualFunc<V> value_equal) {
            var vals = _table.get_values ();
            foreach (unowned V v in vals) {
                if (value_equal (v, value)) {
                    return true;
                }
            }
            return false;
        }

        /**
         * Removes the entry with the specified key.
         * Returns true if the key was found and removed.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string,string> (GLib.str_hash, GLib.str_equal);
         *     map.put ("key", "value");
         *     assert (map.remove ("key"));
         *     assert (!map.containsKey ("key"));
         * }}}
         *
         * @param key the key to remove.
         * @return true if the key was removed.
         */
        public bool remove (K key) {
            return _table.remove (key);
        }

        /**
         * Returns the number of entries in the map.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string,string> (GLib.str_hash, GLib.str_equal);
         *     map.put ("a", "1");
         *     assert (map.size () == 1);
         * }}}
         *
         * @return the number of key-value pairs.
         */
        public uint size () {
            return _table.size ();
        }

        /**
         * Returns whether the map is empty.
         *
         * @return true if the map has no entries.
         */
        public bool isEmpty () {
            return _table.size () == 0;
        }

        /**
         * Removes all entries from the map.
         */
        public void clear () {
            _table.remove_all ();
        }

        /**
         * Returns a list of all keys in the map.
         * The order is not guaranteed.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string,string> (GLib.str_hash, GLib.str_equal);
         *     map.put ("a", "1");
         *     map.put ("b", "2");
         *     GLib.List<unowned string> k = map.keys ();
         *     assert (k.length () == 2);
         * }}}
         *
         * @return a list of keys.
         */
        public GLib.List<unowned K> keys () {
            return _table.get_keys ();
        }

        /**
         * Returns a list of all values in the map.
         * The order is not guaranteed.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string,string> (GLib.str_hash, GLib.str_equal);
         *     map.put ("a", "1");
         *     map.put ("b", "2");
         *     GLib.List<unowned string> v = map.values ();
         *     assert (v.length () == 2);
         * }}}
         *
         * @return a list of values.
         */
        public GLib.List<unowned V> values () {
            return _table.get_values ();
        }

        /**
         * Applies the given function to each key-value pair in the map.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string,string> (GLib.str_hash, GLib.str_equal);
         *     map.put ("a", "1");
         *     map.forEach ((k, v) => {
         *         print ("%s=%s\n", k, v);
         *     });
         * }}}
         *
         * @param func the function to apply to each entry.
         */
        public void forEach (owned BiConsumerFunc<K, V> func) {
            _table.foreach ((k, v) => {
                func (k, v);
            });
        }

        /**
         * Associates the value with the key only if the key is not
         * already present. Returns true if the value was added.
         *
         * Example:
         * {{{
         *     var map = new HashMap<string,string> (GLib.str_hash, GLib.str_equal);
         *     assert (map.putIfAbsent ("key", "first"));
         *     assert (!map.putIfAbsent ("key", "second"));
         *     assert (map.get ("key") == "first");
         * }}}
         *
         * @param key the key.
         * @param value the value to set if key is absent.
         * @return true if the value was added.
         */
        public bool putIfAbsent (owned K key, owned V value) {
            if (_table.contains (key)) {
                return false;
            }
            _table.replace ((owned) key, (owned) value);
            return true;
        }

        /**
         * Copies all entries from the other map into this map.
         * Existing keys are overwritten.
         *
         * Example:
         * {{{
         *     var map1 = new HashMap<string,string> (GLib.str_hash, GLib.str_equal);
         *     map1.put ("a", "1");
         *     var map2 = new HashMap<string,string> (GLib.str_hash, GLib.str_equal);
         *     map2.put ("b", "2");
         *     map1.merge (map2);
         *     assert (map1.size () == 2);
         * }}}
         *
         * @param other the map to merge from.
         */
        public void merge (HashMap<K, V> other) {
            other.forEach ((k, v) => {
                _table.replace (k, v);
            });
        }
    }

    /**
     * A function that takes two arguments and returns nothing.
     *
     * @param a the first argument.
     * @param b the second argument.
     */
    public delegate void BiConsumerFunc<A, B> (A a, B b);
}
