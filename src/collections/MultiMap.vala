namespace Vala.Collections {
    /**
     * A map that can store multiple values per key.
     */
    public class MultiMap<K, V>: GLib.Object {
        private HashMap<K, ArrayList<V> > _map;
        private GLib.EqualFunc<V> ? _value_equal;

        /**
         * Creates an empty MultiMap.
         *
         * @param hash_func hash function for keys.
         * @param key_equal equality function for keys.
         * @param value_equal optional equality function for values.
         */
        public MultiMap (GLib.HashFunc<K> hash_func,
                         GLib.EqualFunc<K> key_equal,
                         GLib.EqualFunc<V> ? value_equal = null) {
            _map = new HashMap<K, ArrayList<V> >(hash_func, key_equal);
            _value_equal = value_equal;
        }

        /**
         * Adds a value for the given key.
         *
         * @param key key to insert.
         * @param value value to append.
         */
        public void put (owned K key, owned V value) {
            ArrayList<V> ? list = _map.get (key);
            if (list == null) {
                list = new ArrayList<V>(_value_equal);
                list.add ((owned) value);
                _map.put ((owned) key, list);
                return;
            }
            list.add ((owned) value);
        }

        /**
         * Returns values for a key.
         *
         * @param key lookup key.
         * @return values list, or an empty list when missing.
         */
        public ArrayList<V> get (K key) {
            ArrayList<V> ? list = _map.get (key);
            if (list != null) {
                return list;
            }
            return new ArrayList<V>(_value_equal);
        }

        /**
         * Returns whether a key exists.
         *
         * @param key key to check.
         * @return true if key has at least one value.
         */
        public bool containsKey (K key) {
            return _map.containsKey (key);
        }

        /**
         * Removes the first matching value for a key.
         *
         * @param key target key.
         * @param value target value.
         * @return true when a value is removed.
         */
        public bool remove (K key, V value) {
            ArrayList<V> ? list = _map.get (key);
            if (list == null) {
                return false;
            }

            int index = list.indexOf (value);
            if (index < 0) {
                return false;
            }

            list.removeAt (index);
            if (list.isEmpty ()) {
                _map.remove (key);
            }
            return true;
        }

        /**
         * Removes all values for a key.
         *
         * @param key key to remove.
         * @return true when key existed.
         */
        public bool removeAll (K key) {
            return _map.remove (key);
        }

        /**
         * Returns number of keys.
         *
         * @return key count.
         */
        public uint size () {
            return _map.size ();
        }

        /**
         * Returns whether this map is empty.
         *
         * @return true when no keys are stored.
         */
        public bool isEmpty () {
            return _map.isEmpty ();
        }

        /**
         * Removes all entries.
         */
        public void clear () {
            _map.clear ();
        }
    }
}
