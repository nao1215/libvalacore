namespace Vala.Collections {
    /**
     * Recoverable ImmutableList argument errors.
     */
    public errordomain ImmutableListError {
        INDEX_OUT_OF_BOUNDS
    }

    /**
     * Immutable list value object.
     */
    public class ImmutableList<T>: GLib.Object {
        private GLib.GenericArray<T> _items;
        private GLib.EqualFunc<T> ? _equal_func;

        /**
         * Creates an immutable list from input array.
         *
         * @param items source items.
         */
        public ImmutableList (T[] items, GLib.EqualFunc<T> ? equal_func = null) {
            _items = new GLib.GenericArray<T> ();
            for (int i = 0; i < items.length; i++) {
                _items.add (items[i]);
            }
            _equal_func = equal_func;
        }

        /**
         * Creates an immutable list from an array.
         *
         * @param items source items.
         * @return immutable list.
         */
        public static ImmutableList<G> of<G> (G[] items, GLib.EqualFunc<G> ? equal_func = null) {
            return new ImmutableList<G> (items, equal_func);
        }

        /**
         * Returns element count.
         *
         * @return list size.
         */
        public int size () {
            return (int) _items.length;
        }

        /**
         * Returns whether list has no elements.
         *
         * @return true when list is empty.
         */
        public bool isEmpty () {
            return _items.length == 0;
        }

        /**
         * Returns element at index.
         *
         * @param index target index.
         * @return element at index.
         * @throws ImmutableListError.INDEX_OUT_OF_BOUNDS when index is outside [0, size).
         */
        public new T get (int index) throws ImmutableListError {
            if (index < 0 || index >= (int) _items.length) {
                throw new ImmutableListError.INDEX_OUT_OF_BOUNDS (
                          "index out of bounds: %d".printf (index)
                );
            }
            return _items[index];
        }

        /**
         * Returns whether list contains value.
         *
         * When no equal_func was provided at construction, this uses
         * reference equality (==). Provide a custom EqualFunc for
         * value-based comparison of object types.
         *
         * @param value value to search.
         * @return true when value exists.
         */
        public bool contains (T value) {
            for (int i = 0; i < (int) _items.length; i++) {
                T item = _items[i];
                bool eq = (_equal_func != null) ? _equal_func (item, value) : (item == value);
                if (eq) {
                    return true;
                }
            }
            return false;
        }

        /**
         * Returns a copy of internal array.
         *
         * @return copied array.
         */
        public T[] toArray () {
            T[] copied = new T[(int) _items.length];
            for (int i = 0; i < (int) _items.length; i++) {
                copied[i] = _items[i];
            }
            return copied;
        }
    }
}
