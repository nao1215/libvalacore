namespace Vala.Collections {
    /**
     * A dynamic array-backed list that grows automatically as elements are added.
     *
     * ArrayList provides O(1) indexed access and amortized O(1) append.
     * Inspired by Java's ArrayList, Go's slice, and Python's list.
     *
     * For element comparison in methods like contains() and indexOf(),
     * pass an equality function to the constructor. For string lists,
     * use GLib.str_equal.
     *
     * Example:
     * {{{
     *     var list = new ArrayList<string> (GLib.str_equal);
     *     list.add ("hello");
     *     list.add ("world");
     *     assert (list.size () == 2);
     *     assert (list.get (0) == "hello");
     *     assert (list.contains ("hello"));
     *
     *     var filtered = list.filter ((s) => { return s == "hello"; });
     *     assert (filtered.size () == 1);
     * }}}
     */
    public class ArrayList<T>: GLib.Object {
        private GLib.GenericArray<T> _array;
        private GLib.EqualFunc<T> ? _equal_func;

        /**
         * Creates an empty ArrayList.
         *
         * The optional equal_func is used by contains() and indexOf()
         * for element comparison. For string lists, pass GLib.str_equal.
         * If null, pointer equality is used.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     assert (list.isEmpty ());
         * }}}
         *
         * @param equal_func the equality function for element comparison,
         *        or null for pointer equality.
         */
        public ArrayList (GLib.EqualFunc<T> ? equal_func = null) {
            _array = new GLib.GenericArray<T> ();
            _equal_func = equal_func;
        }

        /**
         * Adds an element to the end of the list.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     list.add ("hello");
         *     assert (list.size () == 1);
         * }}}
         *
         * @param element the element to add.
         */
        public void add (owned T element) {
            _array.add ((owned) element);
        }

        /**
         * Adds all elements from another ArrayList to the end of this list.
         *
         * Example:
         * {{{
         *     var list1 = new ArrayList<string> (GLib.str_equal);
         *     list1.add ("a");
         *     var list2 = new ArrayList<string> (GLib.str_equal);
         *     list2.add ("b");
         *     list1.addAll (list2);
         *     assert (list1.size () == 2);
         * }}}
         *
         * @param other the ArrayList whose elements are added.
         */
        public void addAll (ArrayList<T> other) {
            for (int i = 0; i < (int) other.size (); i++) {
                _array.add (other.get (i));
            }
        }

        /**
         * Returns the element at the specified index.
         * Returns null if the index is out of bounds.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     list.add ("hello");
         *     assert (list.get (0) == "hello");
         *     assert (list.get (99) == null);
         * }}}
         *
         * @param index the zero-based index.
         * @return the element at the index, or null if out of bounds.
         */
        public new T ? get (int index) {
            if (index < 0 || index >= (int) _array.length) {
                return null;
            }
            return _array[index];
        }

        /**
         * Replaces the element at the specified index.
         * Returns false if the index is out of bounds.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     list.add ("hello");
         *     assert (list.set (0, "world"));
         *     assert (list.get (0) == "world");
         * }}}
         *
         * @param index the zero-based index.
         * @param element the new element.
         * @return true if the element was replaced, false if out of bounds.
         */
        public new bool set (int index, owned T element) {
            if (index < 0 || index >= (int) _array.length) {
                return false;
            }
            _array[index] = (owned) element;
            return true;
        }

        /**
         * Removes and returns the element at the specified index.
         * Returns null if the index is out of bounds.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     list.add ("a");
         *     list.add ("b");
         *     assert (list.removeAt (0) == "a");
         *     assert (list.size () == 1);
         * }}}
         *
         * @param index the zero-based index.
         * @return the removed element, or null if out of bounds.
         */
        public T ? removeAt (int index) {
            if (index < 0 || index >= (int) _array.length) {
                return null;
            }
            T element = _array[index];
            _array.remove_index (index);
            return element;
        }

        /**
         * Returns whether the list contains the specified element.
         * Uses the equality function provided in the constructor, or
         * pointer equality if none was provided.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     list.add ("hello");
         *     assert (list.contains ("hello"));
         *     assert (!list.contains ("world"));
         * }}}
         *
         * @param element the element to search for.
         * @return true if the element is found.
         */
        public bool contains (T element) {
            return indexOf (element) >= 0;
        }

        /**
         * Returns the index of the first occurrence of the specified element.
         * Returns -1 if the element is not found. Uses the equality function
         * provided in the constructor, or pointer equality if none was
         * provided.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     list.add ("a");
         *     list.add ("b");
         *     assert (list.indexOf ("b") == 1);
         *     assert (list.indexOf ("z") == -1);
         * }}}
         *
         * @param element the element to search for.
         * @return the index of the element, or -1 if not found.
         */
        public int indexOf (T element) {
            if (_equal_func != null) {
                uint index;
                if (_array.find_with_equal_func (element, _equal_func, out index)) {
                    return (int) index;
                }
                return -1;
            }
            for (int i = 0; i < (int) _array.length; i++) {
                if (_array[i] == element) {
                    return i;
                }
            }
            return -1;
        }

        /**
         * Returns the number of elements in the list.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     list.add ("a");
         *     assert (list.size () == 1);
         * }}}
         *
         * @return the number of elements.
         */
        public uint size () {
            return _array.length;
        }

        /**
         * Returns whether the list is empty.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     assert (list.isEmpty ());
         *     list.add ("a");
         *     assert (!list.isEmpty ());
         * }}}
         *
         * @return true if the list has no elements.
         */
        public bool isEmpty () {
            return _array.length == 0;
        }

        /**
         * Removes all elements from the list.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     list.add ("a");
         *     list.clear ();
         *     assert (list.isEmpty ());
         * }}}
         */
        public void clear () {
            _array = new GLib.GenericArray<T> ();
        }

        /**
         * Returns the elements as a native array.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     list.add ("a");
         *     list.add ("b");
         *     string[] arr = list.toArray ();
         *     assert (arr.length == 2);
         * }}}
         *
         * @return a new array containing all elements.
         */
        public T[] toArray () {
            T[] result = new T[_array.length];
            for (int i = 0; i < (int) _array.length; i++) {
                result[i] = _array[i];
            }
            return result;
        }

        /**
         * Sorts the list in-place using the provided comparison function.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     list.add ("c");
         *     list.add ("a");
         *     list.add ("b");
         *     list.sort ((a, b) => { return strcmp (a, b); });
         *     assert (list.get (0) == "a");
         * }}}
         *
         * @param func the comparison function. Must return negative if
         *        a < b, zero if a == b, positive if a > b.
         */
        public void sort (owned ComparatorFunc<T> func) {
            _array.sort_with_data ((a, b) => {
                return func (a, b);
            });
        }

        /**
         * Applies the given function to each element in the list.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     list.add ("hello");
         *     list.forEach ((s) => {
         *         print ("%s\n", s);
         *     });
         * }}}
         *
         * @param func the function to apply to each element.
         */
        public void forEach (owned ConsumerFunc<T> func) {
            for (int i = 0; i < (int) _array.length; i++) {
                func (_array[i]);
            }
        }

        /**
         * Returns a new ArrayList containing the results of applying the
         * given function to each element.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     list.add ("hello");
         *     var upper = list.map<string> ((s) => { return s.up (); });
         *     assert (upper.get (0) == "HELLO");
         * }}}
         *
         * @param func the transformation function.
         * @return a new ArrayList with the transformed elements.
         */
        public ArrayList<U> map<U>(owned MapFunc<T, U> func) {
            var result = new ArrayList<U> ();
            for (int i = 0; i < (int) _array.length; i++) {
                result.add (func (_array[i]));
            }
            return result;
        }

        /**
         * Returns a new ArrayList containing only the elements that match
         * the given predicate.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     list.add ("apple");
         *     list.add ("banana");
         *     var a_words = list.filter ((s) => { return s.has_prefix ("a"); });
         *     assert (a_words.size () == 1);
         * }}}
         *
         * @param func the predicate to test each element.
         * @return a new ArrayList with matching elements.
         */
        public ArrayList<T> filter (owned PredicateFunc<T> func) {
            var result = new ArrayList<T>(_equal_func);
            for (int i = 0; i < (int) _array.length; i++) {
                if (func (_array[i])) {
                    result.add (_array[i]);
                }
            }
            return result;
        }

        /**
         * Reduces the list to a single value by applying the given function
         * to each element, accumulating the result from the initial value.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     list.add ("a");
         *     list.add ("b");
         *     list.add ("c");
         *     var joined = list.reduce<string> ("", (acc, s) => {
         *         return acc + s;
         *     });
         *     assert (joined == "abc");
         * }}}
         *
         * @param initial the initial accumulator value.
         * @param func the reduction function.
         * @return the final accumulated value.
         */
        public U reduce<U>(U initial, owned ReduceFunc<T, U> func) {
            U result = initial;
            for (int i = 0; i < (int) _array.length; i++) {
                result = func (result, _array[i]);
            }
            return result;
        }

        /**
         * Returns an Optional containing the first element that matches
         * the given predicate. Returns an empty Optional if no element
         * matches.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     list.add ("apple");
         *     list.add ("banana");
         *     var found = list.find ((s) => { return s == "banana"; });
         *     assert (found.isPresent ());
         *     assert (found.get () == "banana");
         * }}}
         *
         * @param func the predicate to test each element.
         * @return an Optional containing the first matching element.
         */
        public Optional<T> find (owned PredicateFunc<T> func) {
            for (int i = 0; i < (int) _array.length; i++) {
                if (func (_array[i])) {
                    return Optional.of<T>(_array[i]);
                }
            }
            return Optional.empty<T> ();
        }

        /**
         * Returns a new ArrayList containing elements from index
         * ''from'' (inclusive) to index ''to'' (exclusive).
         * If the indices are out of bounds, they are clamped to valid
         * range. If ''from >= to'', returns an empty list.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     list.add ("a");
         *     list.add ("b");
         *     list.add ("c");
         *     var sub = list.subList (0, 2);
         *     assert (sub.size () == 2);
         *     assert (sub.get (0) == "a");
         *     assert (sub.get (1) == "b");
         * }}}
         *
         * @param from the start index (inclusive).
         * @param to the end index (exclusive).
         * @return a new ArrayList containing the sub-range.
         */
        public ArrayList<T> subList (int from, int to) {
            var result = new ArrayList<T>(_equal_func);
            int len = (int) _array.length;
            int start = from < 0 ? 0 : from;
            int end = to > len ? len : to;
            for (int i = start; i < end; i++) {
                result.add (_array[i]);
            }
            return result;
        }
    }

    /**
     * A function that accumulates a value by combining an accumulator
     * with each element.
     *
     * @param accumulator the current accumulated value.
     * @param element the current element.
     * @return the new accumulated value.
     */
    public delegate U ReduceFunc<T, U>(U accumulator, T element);

    /**
     * A function that compares two values for ordering.
     *
     * @param a the first value.
     * @param b the second value.
     * @return negative if a < b, zero if equal, positive if a > b.
     */
    public delegate int ComparatorFunc<T>(T a, T b);
}
