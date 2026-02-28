namespace Vala.Collections {
    /**
     * A priority queue backed by a binary min-heap.
     *
     * Elements are ordered according to a comparison function provided
     * at construction time. The element with the smallest value
     * (as determined by the comparator) is always at the head.
     *
     * Inspired by Java's PriorityQueue and Go's container/heap.
     *
     * Example:
     * {{{
     *     var pq = new PriorityQueue<string> ((a, b) => {
     *         return strcmp (a, b);
     *     });
     *     pq.add ("banana");
     *     pq.add ("apple");
     *     pq.add ("cherry");
     *     assert (pq.peek () == "apple");
     *     assert (pq.poll () == "apple");
     *     assert (pq.poll () == "banana");
     * }}}
     */
    public class PriorityQueue<T>: GLib.Object {
        private GLib.GenericArray<T> _heap;
        private ComparatorFunc<T> _comparator;
        private GLib.EqualFunc<T> ? _equal_func;

        /**
         * Creates an empty PriorityQueue with the given comparison
         * function.
         *
         * The comparator determines priority: the element for which
         * comparator returns the smallest value is dequeued first.
         *
         * The optional equal_func is used by contains() and remove()
         * for element comparison. For string elements, pass
         * GLib.str_equal. If null, pointer equality is used.
         *
         * Example:
         * {{{
         *     var pq = new PriorityQueue<string> ((a, b) => {
         *         return strcmp (a, b);
         *     }, GLib.str_equal);
         *     assert (pq.isEmpty ());
         * }}}
         *
         * @param comparator the comparison function for ordering.
         * @param equal_func the equality function for element comparison,
         *        or null for pointer equality.
         */
        public PriorityQueue (owned ComparatorFunc<T> comparator,
                              GLib.EqualFunc<T> ? equal_func = null) {
            _heap = new GLib.GenericArray<T> ();
            _comparator = (owned) comparator;
            _equal_func = equal_func;
        }

        /**
         * Adds an element to the priority queue.
         *
         * Example:
         * {{{
         *     var pq = new PriorityQueue<string> ((a, b) => {
         *         return strcmp (a, b);
         *     });
         *     pq.add ("hello");
         *     assert (pq.size () == 1);
         * }}}
         *
         * @param element the element to add.
         */
        public void add (owned T element) {
            _heap.add ((owned) element);
            _sift_up ((int) _heap.length - 1);
        }

        /**
         * Removes and returns the highest-priority (smallest) element.
         * Returns null if the queue is empty.
         *
         * Example:
         * {{{
         *     var pq = new PriorityQueue<string> ((a, b) => {
         *         return strcmp (a, b);
         *     });
         *     pq.add ("b");
         *     pq.add ("a");
         *     assert (pq.poll () == "a");
         * }}}
         *
         * @return the smallest element, or null if empty.
         */
        public T ? poll () {
            if (_heap.length == 0) {
                return null;
            }
            T result = _heap[0];
            int last = (int) _heap.length - 1;
            if (last > 0) {
                _heap[0] = _heap[last];
                _heap.remove_index (last);
                _sift_down (0);
            } else {
                _heap.remove_index (0);
            }
            return result;
        }

        /**
         * Returns the highest-priority (smallest) element without
         * removing it. Returns null if the queue is empty.
         *
         * Example:
         * {{{
         *     var pq = new PriorityQueue<string> ((a, b) => {
         *         return strcmp (a, b);
         *     });
         *     pq.add ("b");
         *     pq.add ("a");
         *     assert (pq.peek () == "a");
         *     assert (pq.size () == 2);
         * }}}
         *
         * @return the smallest element, or null if empty.
         */
        public T ? peek () {
            if (_heap.length == 0) {
                return null;
            }
            return _heap[0];
        }

        /**
         * Removes the first occurrence of the specified element.
         * Returns true if the element was found and removed.
         *
         * Uses the equality function provided in the constructor,
         * or pointer equality if none was provided.
         *
         * Example:
         * {{{
         *     var pq = new PriorityQueue<string> ((a, b) => {
         *         return strcmp (a, b);
         *     }, GLib.str_equal);
         *     pq.add ("a");
         *     pq.add ("b");
         *     assert (pq.remove ("b"));
         *     assert (pq.size () == 1);
         * }}}
         *
         * @param element the element to remove.
         * @return true if the element was removed.
         */
        public bool remove (T element) {
            int index = _index_of (element);
            if (index < 0) {
                return false;
            }
            int last = (int) _heap.length - 1;
            if (index == last) {
                _heap.remove_index (last);
            } else {
                _heap[index] = _heap[last];
                _heap.remove_index (last);
                _sift_down (index);
                _sift_up (index);
            }
            return true;
        }

        /**
         * Returns whether the queue contains the specified element.
         *
         * Uses the equality function provided in the constructor,
         * or pointer equality if none was provided.
         *
         * Example:
         * {{{
         *     var pq = new PriorityQueue<string> ((a, b) => {
         *         return strcmp (a, b);
         *     }, GLib.str_equal);
         *     pq.add ("apple");
         *     assert (pq.contains ("apple"));
         *     assert (!pq.contains ("banana"));
         * }}}
         *
         * @param element the element to search for.
         * @return true if the element is found.
         */
        public bool contains (T element) {
            return _index_of (element) >= 0;
        }

        /**
         * Returns the number of elements in the queue.
         *
         * @return the number of elements.
         */
        public uint size () {
            return _heap.length;
        }

        /**
         * Returns whether the queue is empty.
         *
         * @return true if the queue has no elements.
         */
        public bool isEmpty () {
            return _heap.length == 0;
        }

        /**
         * Removes all elements from the queue.
         */
        public void clear () {
            _heap = new GLib.GenericArray<T> ();
        }

        /**
         * Returns the elements as a native array.
         * The order is not guaranteed to be sorted.
         *
         * Example:
         * {{{
         *     var pq = new PriorityQueue<string> ((a, b) => {
         *         return strcmp (a, b);
         *     });
         *     pq.add ("b");
         *     pq.add ("a");
         *     string[] arr = pq.toArray ();
         *     assert (arr.length == 2);
         * }}}
         *
         * @return a new array containing all elements.
         */
        public T[] toArray () {
            T[] result = new T[_heap.length];
            for (int i = 0; i < (int) _heap.length; i++) {
                result[i] = _heap[i];
            }
            return result;
        }

        private void _sift_up (int index) {
            while (index > 0) {
                int parent = (index - 1) / 2;
                if (_comparator (_heap[index], _heap[parent]) < 0) {
                    _swap (index, parent);
                    index = parent;
                } else {
                    break;
                }
            }
        }

        private void _sift_down (int index) {
            int len = (int) _heap.length;
            while (true) {
                int smallest = index;
                int left = 2 * index + 1;
                int right = 2 * index + 2;
                if (left < len && _comparator (_heap[left], _heap[smallest]) < 0) {
                    smallest = left;
                }
                if (right < len && _comparator (_heap[right], _heap[smallest]) < 0) {
                    smallest = right;
                }
                if (smallest == index) {
                    break;
                }
                _swap (index, smallest);
                index = smallest;
            }
        }

        private void _swap (int i, int j) {
            T tmp = _heap[i];
            _heap[i] = _heap[j];
            _heap[j] = tmp;
        }

        private int _index_of (T element) {
            for (int i = 0; i < (int) _heap.length; i++) {
                if (_equal_func != null) {
                    if (_equal_func (_heap[i], element)) {
                        return i;
                    }
                } else {
                    if (_heap[i] == element) {
                        return i;
                    }
                }
            }
            return -1;
        }
    }
}
