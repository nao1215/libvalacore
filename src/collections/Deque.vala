namespace Vala.Collections {
    /**
     * A double-ended queue (deque) that supports efficient insertion
     * and removal at both ends.
     *
     * Deque provides O(1) addFirst/addLast and removeFirst/removeLast.
     * Inspired by Java's ArrayDeque.
     *
     * For element comparison in contains(), pass an equality function
     * to the constructor. For string elements, use GLib.str_equal.
     *
     * Example:
     * {{{
     *     var deque = new Deque<string> (GLib.str_equal);
     *     deque.addLast ("a");
     *     deque.addLast ("b");
     *     deque.addFirst ("z");
     *     assert (deque.peekFirst () == "z");
     *     assert (deque.peekLast () == "b");
     *     assert (deque.size () == 3);
     * }}}
     */
    public class Deque<T>: GLib.Object {
        private GLib.Queue<T> _queue;
        private GLib.EqualFunc<T> ? _equal_func;

        /**
         * Creates an empty Deque.
         *
         * The optional equal_func is used by contains() for element
         * comparison. For string elements, pass GLib.str_equal.
         * If null, pointer equality is used.
         *
         * Example:
         * {{{
         *     var deque = new Deque<string> (GLib.str_equal);
         *     assert (deque.isEmpty ());
         * }}}
         *
         * @param equal_func the equality function for element comparison,
         *        or null for pointer equality.
         */
        public Deque (GLib.EqualFunc<T> ? equal_func = null) {
            _queue = new GLib.Queue<T> ();
            _equal_func = equal_func;
        }

        /**
         * Adds an element to the front of the deque.
         *
         * Example:
         * {{{
         *     var deque = new Deque<string> (GLib.str_equal);
         *     deque.addFirst ("a");
         *     deque.addFirst ("b");
         *     assert (deque.peekFirst () == "b");
         * }}}
         *
         * @param element the element to add.
         */
        public void addFirst (owned T element) {
            _queue.push_head ((owned) element);
        }

        /**
         * Adds an element to the end of the deque.
         *
         * Example:
         * {{{
         *     var deque = new Deque<string> (GLib.str_equal);
         *     deque.addLast ("a");
         *     deque.addLast ("b");
         *     assert (deque.peekLast () == "b");
         * }}}
         *
         * @param element the element to add.
         */
        public void addLast (owned T element) {
            _queue.push_tail ((owned) element);
        }

        /**
         * Removes and returns the first element.
         * Returns null if the deque is empty.
         *
         * Example:
         * {{{
         *     var deque = new Deque<string> (GLib.str_equal);
         *     deque.addLast ("a");
         *     deque.addLast ("b");
         *     assert (deque.removeFirst () == "a");
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
         * Returns null if the deque is empty.
         *
         * Example:
         * {{{
         *     var deque = new Deque<string> (GLib.str_equal);
         *     deque.addLast ("a");
         *     deque.addLast ("b");
         *     assert (deque.removeLast () == "b");
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
         * Returns null if the deque is empty.
         *
         * Example:
         * {{{
         *     var deque = new Deque<string> (GLib.str_equal);
         *     deque.addLast ("a");
         *     assert (deque.peekFirst () == "a");
         *     assert (deque.size () == 1);
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
         * Returns null if the deque is empty.
         *
         * Example:
         * {{{
         *     var deque = new Deque<string> (GLib.str_equal);
         *     deque.addLast ("a");
         *     deque.addLast ("b");
         *     assert (deque.peekLast () == "b");
         *     assert (deque.size () == 2);
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
         * Returns the number of elements in the deque.
         *
         * Example:
         * {{{
         *     var deque = new Deque<string> (GLib.str_equal);
         *     deque.addLast ("a");
         *     deque.addLast ("b");
         *     assert (deque.size () == 2);
         * }}}
         *
         * @return the number of elements.
         */
        public uint size () {
            return _queue.get_length ();
        }

        /**
         * Returns whether the deque is empty.
         *
         * Example:
         * {{{
         *     var deque = new Deque<string> (GLib.str_equal);
         *     assert (deque.isEmpty ());
         *     deque.addLast ("a");
         *     assert (!deque.isEmpty ());
         * }}}
         *
         * @return true if the deque has no elements.
         */
        public bool isEmpty () {
            return _queue.is_empty ();
        }

        /**
         * Returns whether the deque contains the specified element.
         * Uses the equality function provided in the constructor, or
         * pointer equality if none was provided.
         *
         * Example:
         * {{{
         *     var deque = new Deque<string> (GLib.str_equal);
         *     deque.addLast ("apple");
         *     assert (deque.contains ("apple"));
         *     assert (!deque.contains ("banana"));
         * }}}
         *
         * @param element the element to search for.
         * @return true if the element is found.
         */
        public bool contains (T element) {
            unowned GLib.List<T> ? link = _queue.head;
            while (link != null) {
                if (_equal_func != null) {
                    if (_equal_func (link.data, element)) {
                        return true;
                    }
                } else {
                    if (link.data == element) {
                        return true;
                    }
                }
                link = link.next;
            }
            return false;
        }

        /**
         * Removes all elements from the deque.
         *
         * Example:
         * {{{
         *     var deque = new Deque<string> (GLib.str_equal);
         *     deque.addLast ("a");
         *     deque.addLast ("b");
         *     deque.clear ();
         *     assert (deque.isEmpty ());
         * }}}
         */
        public void clear () {
            _queue.clear ();
        }

        /**
         * Returns the elements as a native array, from first to last.
         *
         * Example:
         * {{{
         *     var deque = new Deque<string> (GLib.str_equal);
         *     deque.addLast ("a");
         *     deque.addLast ("b");
         *     string[] arr = deque.toArray ();
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

        /**
         * Applies the given function to each element in the deque,
         * from first to last.
         *
         * Example:
         * {{{
         *     var deque = new Deque<string> (GLib.str_equal);
         *     deque.addLast ("a");
         *     deque.addLast ("b");
         *     deque.forEach ((s) => {
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
    }
}
