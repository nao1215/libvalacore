namespace Vala.Collections {
    /**
     * A doubly-linked list that supports efficient insertion and removal
     * at both ends.
     *
     * LinkedList provides O(1) addFirst/addLast and removeFirst/removeLast.
     * It can be used as a queue, stack, or deque.
     * Inspired by Java's LinkedList and Go's container/list.
     *
     * For element comparison in methods like contains() and indexOf(),
     * pass an equality function to the constructor. For string lists,
     * use GLib.str_equal.
     *
     * Example:
     * {{{
     *     var list = new LinkedList<string> (GLib.str_equal);
     *     list.addLast ("a");
     *     list.addLast ("b");
     *     list.addFirst ("z");
     *     assert (list.peekFirst () == "z");
     *     assert (list.peekLast () == "b");
     *     assert (list.size () == 3);
     * }}}
     */
    public class LinkedList<T>: GLib.Object {
        private GLib.Queue<T> _queue;
        private GLib.EqualFunc<T> ? _equal_func;

        /**
         * Creates an empty LinkedList.
         *
         * The optional equal_func is used by contains() and indexOf()
         * for element comparison. For string lists, pass GLib.str_equal.
         * If null, pointer equality is used.
         *
         * Example:
         * {{{
         *     var list = new LinkedList<string> (GLib.str_equal);
         *     assert (list.isEmpty ());
         * }}}
         *
         * @param equal_func the equality function for element comparison,
         *        or null for pointer equality.
         */
        public LinkedList (GLib.EqualFunc<T> ? equal_func = null) {
            _queue = new GLib.Queue<T> ();
            _equal_func = equal_func;
        }

        /**
         * Adds an element to the front of the list.
         *
         * Example:
         * {{{
         *     var list = new LinkedList<string> (GLib.str_equal);
         *     list.addFirst ("a");
         *     list.addFirst ("b");
         *     assert (list.peekFirst () == "b");
         * }}}
         *
         * @param element the element to add.
         */
        public void addFirst (owned T element) {
            _queue.push_head ((owned) element);
        }

        /**
         * Adds an element to the end of the list.
         *
         * Example:
         * {{{
         *     var list = new LinkedList<string> (GLib.str_equal);
         *     list.addLast ("a");
         *     list.addLast ("b");
         *     assert (list.peekLast () == "b");
         * }}}
         *
         * @param element the element to add.
         */
        public void addLast (owned T element) {
            _queue.push_tail ((owned) element);
        }

        /**
         * Removes and returns the first element.
         * Returns null if the list is empty.
         *
         * Example:
         * {{{
         *     var list = new LinkedList<string> (GLib.str_equal);
         *     list.addLast ("a");
         *     list.addLast ("b");
         *     assert (list.removeFirst () == "a");
         *     assert (list.size () == 1);
         * }}}
         *
         * @return the first element, or null if empty.
         */
        public T ? removeFirst () {
            if (_queue.is_empty ()) {
                return null;
            }
            return _queue.pop_head ();
        }

        /**
         * Removes and returns the last element.
         * Returns null if the list is empty.
         *
         * Example:
         * {{{
         *     var list = new LinkedList<string> (GLib.str_equal);
         *     list.addLast ("a");
         *     list.addLast ("b");
         *     assert (list.removeLast () == "b");
         *     assert (list.size () == 1);
         * }}}
         *
         * @return the last element, or null if empty.
         */
        public T ? removeLast () {
            if (_queue.is_empty ()) {
                return null;
            }
            return _queue.pop_tail ();
        }

        /**
         * Returns the first element without removing it.
         * Returns null if the list is empty.
         *
         * Example:
         * {{{
         *     var list = new LinkedList<string> (GLib.str_equal);
         *     list.addLast ("a");
         *     assert (list.peekFirst () == "a");
         *     assert (list.size () == 1);
         * }}}
         *
         * @return the first element, or null if empty.
         */
        public T ? peekFirst () {
            if (_queue.is_empty ()) {
                return null;
            }
            return _queue.peek_head ();
        }

        /**
         * Returns the last element without removing it.
         * Returns null if the list is empty.
         *
         * Example:
         * {{{
         *     var list = new LinkedList<string> (GLib.str_equal);
         *     list.addLast ("a");
         *     list.addLast ("b");
         *     assert (list.peekLast () == "b");
         *     assert (list.size () == 2);
         * }}}
         *
         * @return the last element, or null if empty.
         */
        public T ? peekLast () {
            if (_queue.is_empty ()) {
                return null;
            }
            return _queue.peek_tail ();
        }

        /**
         * Returns the number of elements in the list.
         *
         * Example:
         * {{{
         *     var list = new LinkedList<string> (GLib.str_equal);
         *     list.addLast ("a");
         *     list.addLast ("b");
         *     assert (list.size () == 2);
         * }}}
         *
         * @return the number of elements.
         */
        public uint size () {
            return _queue.get_length ();
        }

        /**
         * Returns whether the list is empty.
         *
         * Example:
         * {{{
         *     var list = new LinkedList<string> (GLib.str_equal);
         *     assert (list.isEmpty ());
         *     list.addLast ("a");
         *     assert (!list.isEmpty ());
         * }}}
         *
         * @return true if the list has no elements.
         */
        public bool isEmpty () {
            return _queue.is_empty ();
        }

        /**
         * Removes all elements from the list.
         *
         * Example:
         * {{{
         *     var list = new LinkedList<string> (GLib.str_equal);
         *     list.addLast ("a");
         *     list.addLast ("b");
         *     list.clear ();
         *     assert (list.isEmpty ());
         * }}}
         */
        public void clear () {
            _queue.clear ();
        }

        /**
         * Returns whether the list contains the specified element.
         * Uses the equality function provided in the constructor, or
         * pointer equality if none was provided.
         *
         * Example:
         * {{{
         *     var list = new LinkedList<string> (GLib.str_equal);
         *     list.addLast ("apple");
         *     assert (list.contains ("apple"));
         *     assert (!list.contains ("banana"));
         * }}}
         *
         * @param element the element to search for.
         * @return true if the element is found.
         */
        public bool contains (T element) {
            return indexOf (element) >= 0;
        }

        /**
         * Returns the index of the first occurrence of the specified
         * element. Returns -1 if the element is not found. Uses the
         * equality function provided in the constructor, or pointer
         * equality if none was provided.
         *
         * Example:
         * {{{
         *     var list = new LinkedList<string> (GLib.str_equal);
         *     list.addLast ("a");
         *     list.addLast ("b");
         *     assert (list.indexOf ("b") == 1);
         *     assert (list.indexOf ("z") == -1);
         * }}}
         *
         * @param element the element to search for.
         * @return the index of the element, or -1 if not found.
         */
        public int indexOf (T element) {
            unowned GLib.List<T> ? link = _queue.head;
            int i = 0;
            while (link != null) {
                if (_equal_func != null) {
                    if (_equal_func (link.data, element)) {
                        return i;
                    }
                } else {
                    if (link.data == element) {
                        return i;
                    }
                }
                link = link.next;
                i++;
            }
            return -1;
        }

        /**
         * Returns the element at the specified index.
         * Returns null if the index is out of bounds.
         *
         * This is an O(n) operation as it must traverse the list.
         *
         * Example:
         * {{{
         *     var list = new LinkedList<string> (GLib.str_equal);
         *     list.addLast ("a");
         *     list.addLast ("b");
         *     list.addLast ("c");
         *     assert (list.get (1) == "b");
         *     assert (list.get (99) == null);
         * }}}
         *
         * @param index the zero-based index.
         * @return the element at the index, or null if out of bounds.
         */
        public new T ? get (int index) {
            if (index < 0 || index >= (int) _queue.get_length ()) {
                return null;
            }
            return _queue.peek_nth (index);
        }

        /**
         * Applies the given function to each element in the list,
         * from first to last.
         *
         * Example:
         * {{{
         *     var list = new LinkedList<string> (GLib.str_equal);
         *     list.addLast ("a");
         *     list.addLast ("b");
         *     list.forEach ((s) => {
         *         print ("%s\n", s);
         *     });
         * }}}
         *
         * @param func the function to apply to each element.
         */
        public void forEach (owned ConsumerFunc<T> func) {
            unowned GLib.List<T> ? link = _queue.head;
            while (link != null) {
                func (link.data);
                link = link.next;
            }
        }

        /**
         * Returns the elements as a native array.
         *
         * Example:
         * {{{
         *     var list = new LinkedList<string> (GLib.str_equal);
         *     list.addLast ("a");
         *     list.addLast ("b");
         *     string[] arr = list.toArray ();
         *     assert (arr.length == 2);
         *     assert (arr[0] == "a");
         * }}}
         *
         * @return a new array containing all elements in order.
         */
        public T[] toArray () {
            T[] result = new T[_queue.get_length ()];
            unowned GLib.List<T> ? link = _queue.head;
            int i = 0;
            while (link != null) {
                result[i] = link.data;
                link = link.next;
                i++;
            }
            return result;
        }
    }
}
