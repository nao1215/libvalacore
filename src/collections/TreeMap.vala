namespace Vala.Collections {
    /**
     * A sorted map backed by a balanced binary search tree.
     *
     * Keys are ordered according to a comparison function provided
     * at construction time. Provides O(log n) lookup, insertion, and
     * deletion. Inspired by Java's TreeMap.
     *
     * Example:
     * {{{
     *     var map = new TreeMap<string,string> ((a, b) => {
     *         return strcmp (a, b);
     *     });
     *     map.put ("banana", "yellow");
     *     map.put ("apple", "red");
     *     map.put ("cherry", "red");
     *     assert (map.firstKey () == "apple");
     *     assert (map.lastKey () == "cherry");
     * }}}
     */
    public class TreeMap<K, V>: GLib.Object {
        private _TreeNode<K, V> ? _root;
        private ComparatorFunc<K> _comparator;
        private int _size;

        /**
         * Creates an empty TreeMap with the given comparison function.
         *
         * The comparator determines key ordering: negative means
         * a < b, zero means a == b, positive means a > b.
         *
         * Example:
         * {{{
         *     var map = new TreeMap<string,string> ((a, b) => {
         *         return strcmp (a, b);
         *     });
         *     assert (map.isEmpty ());
         * }}}
         *
         * @param comparator the comparison function for keys.
         */
        public TreeMap (owned ComparatorFunc<K> comparator) {
            _root = null;
            _comparator = (owned) comparator;
            _size = 0;
        }

        /**
         * Associates the specified value with the specified key.
         * If the key already exists, the value is replaced.
         *
         * Example:
         * {{{
         *     var map = new TreeMap<string,string> ((a, b) => {
         *         return strcmp (a, b);
         *     });
         *     map.put ("key", "value");
         *     assert (map.get ("key") == "value");
         * }}}
         *
         * @param key the key.
         * @param value the value.
         */
        public void put (owned K key, owned V value) {
            _root = _insert (_root, (owned) key, (owned) value);
        }

        /**
         * Returns the value associated with the specified key.
         * Returns null if the key is not found.
         *
         * Example:
         * {{{
         *     var map = new TreeMap<string,string> ((a, b) => {
         *         return strcmp (a, b);
         *     });
         *     map.put ("key", "value");
         *     assert (map.get ("key") == "value");
         *     assert (map.get ("missing") == null);
         * }}}
         *
         * @param key the key to look up.
         * @return the associated value, or null if not found.
         */
        public new V ? get (K key) {
            unowned _TreeNode<K, V> ? node = _find (_root, key);
            if (node == null) {
                return null;
            }
            return node.value;
        }

        /**
         * Returns whether the map contains the specified key.
         *
         * @param key the key to check.
         * @return true if the key exists.
         */
        public bool containsKey (K key) {
            return _find (_root, key) != null;
        }

        /**
         * Removes the entry with the specified key.
         * Returns true if the key was found and removed.
         *
         * @param key the key to remove.
         * @return true if the key was removed.
         */
        public bool remove (K key) {
            if (_find (_root, key) == null) {
                return false;
            }
            _root = _remove (_root, key);
            _size--;
            return true;
        }

        /**
         * Returns the smallest key in the map.
         * Returns null if the map is empty.
         *
         * Example:
         * {{{
         *     var map = new TreeMap<string,string> ((a, b) => {
         *         return strcmp (a, b);
         *     });
         *     map.put ("b", "2");
         *     map.put ("a", "1");
         *     assert (map.firstKey () == "a");
         * }}}
         *
         * @return the smallest key, or null if empty.
         */
        public K ? firstKey () {
            if (_root == null) {
                return null;
            }
            unowned _TreeNode<K, V> node = _root;
            while (node.left != null) {
                node = node.left;
            }
            return node.key;
        }

        /**
         * Returns the largest key in the map.
         * Returns null if the map is empty.
         *
         * Example:
         * {{{
         *     var map = new TreeMap<string,string> ((a, b) => {
         *         return strcmp (a, b);
         *     });
         *     map.put ("a", "1");
         *     map.put ("c", "3");
         *     assert (map.lastKey () == "c");
         * }}}
         *
         * @return the largest key, or null if empty.
         */
        public K ? lastKey () {
            if (_root == null) {
                return null;
            }
            unowned _TreeNode<K, V> node = _root;
            while (node.right != null) {
                node = node.right;
            }
            return node.key;
        }

        /**
         * Returns the greatest key less than or equal to the given key.
         * Returns null if no such key exists.
         *
         * Example:
         * {{{
         *     var map = new TreeMap<string,string> ((a, b) => {
         *         return strcmp (a, b);
         *     });
         *     map.put ("a", "1");
         *     map.put ("c", "3");
         *     map.put ("e", "5");
         *     assert (map.floorKey ("d") == "c");
         *     assert (map.floorKey ("c") == "c");
         * }}}
         *
         * @param key the reference key.
         * @return the floor key, or null if none.
         */
        public K ? floorKey (K key) {
            return _floor (_root, key);
        }

        /**
         * Returns the smallest key greater than or equal to the given
         * key. Returns null if no such key exists.
         *
         * Example:
         * {{{
         *     var map = new TreeMap<string,string> ((a, b) => {
         *         return strcmp (a, b);
         *     });
         *     map.put ("a", "1");
         *     map.put ("c", "3");
         *     map.put ("e", "5");
         *     assert (map.ceilingKey ("b") == "c");
         *     assert (map.ceilingKey ("c") == "c");
         * }}}
         *
         * @param key the reference key.
         * @return the ceiling key, or null if none.
         */
        public K ? ceilingKey (K key) {
            return _ceiling (_root, key);
        }

        /**
         * Returns a new TreeMap containing entries whose keys are
         * in the range [''from'', ''to'') (from inclusive, to exclusive).
         *
         * Example:
         * {{{
         *     var map = new TreeMap<string,string> ((a, b) => {
         *         return strcmp (a, b);
         *     });
         *     map.put ("a", "1");
         *     map.put ("b", "2");
         *     map.put ("c", "3");
         *     map.put ("d", "4");
         *     var sub = map.subMap ("b", "d");
         *     assert (sub.size () == 2);
         *     assert (sub.containsKey ("b"));
         *     assert (sub.containsKey ("c"));
         * }}}
         *
         * @param from the lower bound (inclusive).
         * @param to the upper bound (exclusive).
         * @return a new TreeMap with the sub-range.
         */
        public TreeMap<K, V> subMap (K from, K to) {
            var result = new TreeMap<K, V> ((a, b) => {
                return _comparator (a, b);
            });
            _collect_range (_root, from, to, result);
            return result;
        }

        /**
         * Returns the number of entries in the map.
         *
         * @return the number of key-value pairs.
         */
        public int size () {
            return _size;
        }

        /**
         * Returns whether the map is empty.
         *
         * @return true if the map has no entries.
         */
        public bool isEmpty () {
            return _size == 0;
        }

        /**
         * Removes all entries from the map.
         */
        public void clear () {
            _root = null;
            _size = 0;
        }

        /**
         * Returns all keys in sorted order as an ArrayList.
         *
         * Example:
         * {{{
         *     var map = new TreeMap<string,string> ((a, b) => {
         *         return strcmp (a, b);
         *     });
         *     map.put ("c", "3");
         *     map.put ("a", "1");
         *     map.put ("b", "2");
         *     var keys = map.keys ();
         *     assert (keys.get (0) == "a");
         *     assert (keys.get (1) == "b");
         *     assert (keys.get (2) == "c");
         * }}}
         *
         * @return an ArrayList of keys in sorted order.
         */
        public ArrayList<K> keys () {
            var result = new ArrayList<K> ();
            _inorder_keys (_root, result);
            return result;
        }

        /**
         * Applies the given function to each entry in key order.
         *
         * @param func the function to apply.
         */
        public void forEach (owned BiConsumerFunc<K, V> func) {
            _inorder_foreach (_root, func);
        }

        private _TreeNode<K, V> ? _insert (_TreeNode<K, V> ? node,
                                           owned K key, owned V value) {
            if (node == null) {
                _size++;
                return new _TreeNode<K, V> ((owned) key, (owned) value);
            }
            int cmp = _comparator (key, node.key);
            if (cmp < 0) {
                node.left = _insert (node.left, (owned) key, (owned) value);
            } else if (cmp > 0) {
                node.right = _insert (node.right, (owned) key, (owned) value);
            } else {
                node.value = (owned) value;
            }
            return node;
        }

        private unowned _TreeNode<K, V> ? _find (_TreeNode<K, V> ? node, K key) {
            if (node == null) {
                return null;
            }
            int cmp = _comparator (key, node.key);
            if (cmp < 0) {
                return _find (node.left, key);
            } else if (cmp > 0) {
                return _find (node.right, key);
            }
            return node;
        }

        private _TreeNode<K, V> ? _remove (_TreeNode<K, V> ? node, K key) {
            if (node == null) {
                return null;
            }
            int cmp = _comparator (key, node.key);
            if (cmp < 0) {
                node.left = _remove (node.left, key);
            } else if (cmp > 0) {
                node.right = _remove (node.right, key);
            } else {
                if (node.left == null) {
                    return node.right;
                }
                if (node.right == null) {
                    return node.left;
                }
                // find in-order successor
                unowned _TreeNode<K, V> succ = node.right;
                while (succ.left != null) {
                    succ = succ.left;
                }
                node.key = succ.key;
                node.value = succ.value;
                node.right = _remove (node.right, succ.key);
            }
            return node;
        }

        private K ? _floor (_TreeNode<K, V> ? node, K key) {
            if (node == null) {
                return null;
            }
            int cmp = _comparator (key, node.key);
            if (cmp == 0) {
                return node.key;
            }
            if (cmp < 0) {
                return _floor (node.left, key);
            }
            K ? right_floor = _floor (node.right, key);
            if (right_floor != null) {
                return right_floor;
            }
            return node.key;
        }

        private K ? _ceiling (_TreeNode<K, V> ? node, K key) {
            if (node == null) {
                return null;
            }
            int cmp = _comparator (key, node.key);
            if (cmp == 0) {
                return node.key;
            }
            if (cmp > 0) {
                return _ceiling (node.right, key);
            }
            K ? left_ceiling = _ceiling (node.left, key);
            if (left_ceiling != null) {
                return left_ceiling;
            }
            return node.key;
        }

        private void _collect_range (_TreeNode<K, V> ? node,
                                     K from, K to,
                                     TreeMap<K, V> result) {
            if (node == null) {
                return;
            }
            int cmp_from = _comparator (node.key, from);
            int cmp_to = _comparator (node.key, to);
            if (cmp_from > 0) {
                _collect_range (node.left, from, to, result);
            }
            if (cmp_from >= 0 && cmp_to < 0) {
                result.put (node.key, node.value);
            }
            if (cmp_to < 0) {
                _collect_range (node.right, from, to, result);
            }
        }

        private void _inorder_keys (_TreeNode<K, V> ? node, ArrayList<K> list) {
            if (node == null) {
                return;
            }
            _inorder_keys (node.left, list);
            list.add (node.key);
            _inorder_keys (node.right, list);
        }

        private void _inorder_foreach (_TreeNode<K, V> ? node,
                                       BiConsumerFunc<K, V> func) {
            if (node == null) {
                return;
            }
            _inorder_foreach (node.left, func);
            func (node.key, node.value);
            _inorder_foreach (node.right, func);
        }
    }

    private class _TreeNode<K, V> {
        public K key;
        public V value;
        public _TreeNode<K, V> ? left;
        public _TreeNode<K, V> ? right;

        public _TreeNode (owned K key, owned V value) {
            this.key = (owned) key;
            this.value = (owned) value;
            this.left = null;
            this.right = null;
        }
    }
}
