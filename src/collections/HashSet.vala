namespace Vala.Collections {
    /**
     * A hash table-based set of unique elements.
     *
     * HashSet provides O(1) average-time add, remove, and contains.
     * Inspired by Java's HashSet and Python's set.
     *
     * Set operations (union, intersection, difference) return new sets
     * without modifying the originals.
     *
     * Example:
     * {{{
     *     var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
     *     set.add ("apple");
     *     set.add ("banana");
     *     set.add ("apple");
     *     assert (set.size () == 2);
     *     assert (set.contains ("apple"));
     * }}}
     */
    public class HashSet<T>: GLib.Object {
        private GLib.HashTable<T, bool> _table;
        private GLib.HashFunc<T> _hash_func;
        private GLib.EqualFunc<T> _equal_func;

        /**
         * Creates an empty HashSet with the given hash and equality
         * functions.
         *
         * For string elements, pass GLib.str_hash and GLib.str_equal.
         * For integer or pointer elements, pass GLib.direct_hash and
         * GLib.direct_equal.
         *
         * Example:
         * {{{
         *     var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     assert (set.isEmpty ());
         * }}}
         *
         * @param hash_func the hash function for elements.
         * @param equal_func the equality function for elements.
         */
        public HashSet (GLib.HashFunc<T> hash_func, GLib.EqualFunc<T> equal_func) {
            _hash_func = hash_func;
            _equal_func = equal_func;
            _table = new GLib.HashTable<T, bool> (hash_func, equal_func);
        }

        /**
         * Adds an element to the set. If the element already exists,
         * the set is not modified.
         *
         * Example:
         * {{{
         *     var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     assert (set.add ("apple"));
         *     assert (!set.add ("apple"));
         *     assert (set.size () == 1);
         * }}}
         *
         * @param element the element to add.
         * @return true if the element was added, false if already present.
         */
        public bool add (owned T element) {
            if (_table.contains (element)) {
                return false;
            }
            _table.replace ((owned) element, true);
            return true;
        }

        /**
         * Removes an element from the set.
         *
         * Example:
         * {{{
         *     var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     set.add ("apple");
         *     assert (set.remove ("apple"));
         *     assert (!set.remove ("apple"));
         * }}}
         *
         * @param element the element to remove.
         * @return true if the element was removed, false if not found.
         */
        public bool remove (T element) {
            return _table.remove (element);
        }

        /**
         * Returns whether the set contains the specified element.
         *
         * Example:
         * {{{
         *     var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     set.add ("apple");
         *     assert (set.contains ("apple"));
         *     assert (!set.contains ("banana"));
         * }}}
         *
         * @param element the element to check.
         * @return true if the element is in the set.
         */
        public bool contains (T element) {
            return _table.contains (element);
        }

        /**
         * Returns the number of elements in the set.
         *
         * Example:
         * {{{
         *     var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     set.add ("a");
         *     set.add ("b");
         *     assert (set.size () == 2);
         * }}}
         *
         * @return the number of elements.
         */
        public uint size () {
            return _table.size ();
        }

        /**
         * Returns whether the set is empty.
         *
         * Example:
         * {{{
         *     var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     assert (set.isEmpty ());
         *     set.add ("a");
         *     assert (!set.isEmpty ());
         * }}}
         *
         * @return true if the set has no elements.
         */
        public bool isEmpty () {
            return _table.size () == 0;
        }

        /**
         * Removes all elements from the set.
         *
         * Example:
         * {{{
         *     var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     set.add ("a");
         *     set.add ("b");
         *     set.clear ();
         *     assert (set.isEmpty ());
         * }}}
         */
        public void clear () {
            _table.remove_all ();
        }

        /**
         * Returns a new set containing all elements that are in either
         * this set or the other set (or both).
         *
         * Example:
         * {{{
         *     var a = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     a.add ("1");
         *     a.add ("2");
         *     var b = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     b.add ("2");
         *     b.add ("3");
         *     var u = a.union (b);
         *     assert (u.size () == 3);
         * }}}
         *
         * @param other the other set.
         * @return a new set representing the union.
         */
        public HashSet<T> union (HashSet<T> other) {
            var result = new HashSet<T> (_hash_func, _equal_func);
            _table.foreach ((k, v) => {
                result.add (k);
            });
            other._table.foreach ((k, v) => {
                result.add (k);
            });
            return result;
        }

        /**
         * Returns a new set containing only elements that are in both
         * this set and the other set.
         *
         * Example:
         * {{{
         *     var a = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     a.add ("1");
         *     a.add ("2");
         *     var b = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     b.add ("2");
         *     b.add ("3");
         *     var i = a.intersection (b);
         *     assert (i.size () == 1);
         *     assert (i.contains ("2"));
         * }}}
         *
         * @param other the other set.
         * @return a new set representing the intersection.
         */
        public HashSet<T> intersection (HashSet<T> other) {
            var result = new HashSet<T> (_hash_func, _equal_func);
            _table.foreach ((k, v) => {
                if (other.contains (k)) {
                    result.add (k);
                }
            });
            return result;
        }

        /**
         * Returns a new set containing elements that are in this set
         * but not in the other set.
         *
         * Example:
         * {{{
         *     var a = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     a.add ("1");
         *     a.add ("2");
         *     var b = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     b.add ("2");
         *     b.add ("3");
         *     var d = a.difference (b);
         *     assert (d.size () == 1);
         *     assert (d.contains ("1"));
         * }}}
         *
         * @param other the other set.
         * @return a new set representing the difference.
         */
        public HashSet<T> difference (HashSet<T> other) {
            var result = new HashSet<T> (_hash_func, _equal_func);
            _table.foreach ((k, v) => {
                if (!other.contains (k)) {
                    result.add (k);
                }
            });
            return result;
        }

        /**
         * Returns whether this set is a subset of the other set.
         * A set A is a subset of B if every element of A is also in B.
         * An empty set is a subset of any set.
         *
         * Example:
         * {{{
         *     var a = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     a.add ("1");
         *     var b = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     b.add ("1");
         *     b.add ("2");
         *     assert (a.isSubsetOf (b));
         *     assert (!b.isSubsetOf (a));
         * }}}
         *
         * @param other the other set to check against.
         * @return true if this set is a subset of the other.
         */
        public bool isSubsetOf (HashSet<T> other) {
            var keys = _table.get_keys ();
            foreach (unowned T k in keys) {
                if (!other.contains (k)) {
                    return false;
                }
            }
            return true;
        }

        /**
         * Returns the elements as a native array.
         *
         * Example:
         * {{{
         *     var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     set.add ("a");
         *     set.add ("b");
         *     T[] arr = set.toArray ();
         *     assert (arr.length == 2);
         * }}}
         *
         * @return a new array containing all elements.
         */
        public T[] toArray () {
            T[] result = new T[_table.size ()];
            int i = 0;
            _table.foreach ((k, v) => {
                result[i] = k;
                i++;
            });
            return result;
        }

        /**
         * Applies the given function to each element in the set.
         * The iteration order is not guaranteed.
         *
         * Example:
         * {{{
         *     var set = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     set.add ("hello");
         *     set.forEach ((s) => {
         *         print ("%s\n", s);
         *     });
         * }}}
         *
         * @param func the function to apply to each element.
         */
        public void forEach (owned ConsumerFunc<T> func) {
            _table.foreach ((k, v) => {
                func (k);
            });
        }

        /**
         * Adds all elements from another HashSet to this set.
         *
         * Example:
         * {{{
         *     var a = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     a.add ("1");
         *     var b = new HashSet<string> (GLib.str_hash, GLib.str_equal);
         *     b.add ("2");
         *     b.add ("3");
         *     a.addAll (b);
         *     assert (a.size () == 3);
         * }}}
         *
         * @param other the set whose elements are added.
         */
        public void addAll (HashSet<T> other) {
            other._table.foreach ((k, v) => {
                _table.replace (k, true);
            });
        }
    }
}
