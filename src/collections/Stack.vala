namespace Vala.Collections {
    /**
     * A LIFO (Last-In-First-Out) stack backed by a GLib.Queue.
     *
     * Inspired by Java's Stack and Go's slice-based stack pattern.
     *
     * Example:
     * {{{
     *     var stack = new Stack<string> ();
     *     stack.push ("a");
     *     stack.push ("b");
     *     assert (stack.peek () == "b");
     *     assert (stack.pop () == "b");
     *     assert (stack.pop () == "a");
     * }}}
     */
    public class Stack<T>: GLib.Object {
        private GLib.Queue<T> _queue;

        /**
         * Creates an empty Stack.
         *
         * Example:
         * {{{
         *     var stack = new Stack<string> ();
         *     assert (stack.isEmpty ());
         * }}}
         */
        public Stack () {
            _queue = new GLib.Queue<T> ();
        }

        /**
         * Pushes an element onto the top of the stack.
         *
         * Example:
         * {{{
         *     var stack = new Stack<string> ();
         *     stack.push ("hello");
         *     assert (stack.size () == 1);
         * }}}
         *
         * @param element the element to push.
         */
        public void push (owned T element) {
            _queue.push_tail ((owned) element);
        }

        /**
         * Removes and returns the element at the top of the stack.
         * Returns null if the stack is empty.
         *
         * Example:
         * {{{
         *     var stack = new Stack<string> ();
         *     stack.push ("a");
         *     assert (stack.pop () == "a");
         * }}}
         *
         * @return the top element, or null if empty.
         */
        public T ? pop () {
            if (_queue.is_empty ()) {
                return null;
            }
            return _queue.pop_tail ();
        }

        /**
         * Returns the element at the top of the stack without removing it.
         * Returns null if the stack is empty.
         *
         * Example:
         * {{{
         *     var stack = new Stack<string> ();
         *     stack.push ("a");
         *     assert (stack.peek () == "a");
         *     assert (stack.size () == 1);
         * }}}
         *
         * @return the top element, or null if empty.
         */
        public T ? peek () {
            if (_queue.is_empty ()) {
                return null;
            }
            return _queue.peek_tail ();
        }

        /**
         * Returns the number of elements in the stack.
         *
         * @return the stack size.
         */
        public uint size () {
            return _queue.get_length ();
        }

        /**
         * Returns whether the stack is empty.
         *
         * @return true if the stack has no elements.
         */
        public bool isEmpty () {
            return _queue.is_empty ();
        }

        /**
         * Removes all elements from the stack.
         */
        public void clear () {
            _queue.clear ();
        }
    }
}
