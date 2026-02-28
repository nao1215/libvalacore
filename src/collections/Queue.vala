namespace Vala.Collections {
    /**
     * A FIFO (First-In-First-Out) queue backed by a GLib.Queue.
     *
     * Inspired by Java's Queue and Go's channel pattern.
     *
     * Example:
     * {{{
     *     var queue = new Queue<string> ();
     *     queue.enqueue ("a");
     *     queue.enqueue ("b");
     *     assert (queue.peek () == "a");
     *     assert (queue.dequeue () == "a");
     *     assert (queue.dequeue () == "b");
     * }}}
     */
    public class Queue<T>: GLib.Object {
        private GLib.Queue<T> _queue;

        /**
         * Creates an empty Queue.
         *
         * Example:
         * {{{
         *     var queue = new Queue<string> ();
         *     assert (queue.isEmpty ());
         * }}}
         */
        public Queue () {
            _queue = new GLib.Queue<T> ();
        }

        /**
         * Adds an element to the end of the queue.
         *
         * Example:
         * {{{
         *     var queue = new Queue<string> ();
         *     queue.enqueue ("hello");
         *     assert (queue.size () == 1);
         * }}}
         *
         * @param element the element to add.
         */
        public void enqueue (owned T element) {
            _queue.push_tail ((owned) element);
        }

        /**
         * Removes and returns the element at the front of the queue.
         * Returns null if the queue is empty.
         *
         * Example:
         * {{{
         *     var queue = new Queue<string> ();
         *     queue.enqueue ("a");
         *     assert (queue.dequeue () == "a");
         * }}}
         *
         * @return the front element, or null if empty.
         */
        public T ? dequeue () {
            if (_queue.is_empty ()) {
                return null;
            }
            return _queue.pop_head ();
        }

        /**
         * Returns the element at the front of the queue without removing it.
         * Returns null if the queue is empty.
         *
         * Example:
         * {{{
         *     var queue = new Queue<string> ();
         *     queue.enqueue ("a");
         *     assert (queue.peek () == "a");
         *     assert (queue.size () == 1);
         * }}}
         *
         * @return the front element, or null if empty.
         */
        public T ? peek () {
            if (_queue.is_empty ()) {
                return null;
            }
            return _queue.peek_head ();
        }

        /**
         * Returns the number of elements in the queue.
         *
         * @return the queue size.
         */
        public uint size () {
            return _queue.get_length ();
        }

        /**
         * Returns whether the queue is empty.
         *
         * @return true if the queue has no elements.
         */
        public bool isEmpty () {
            return _queue.is_empty ();
        }

        /**
         * Removes all elements from the queue.
         */
        public void clear () {
            _queue.clear ();
        }
    }
}
