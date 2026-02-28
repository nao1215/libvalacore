using Vala.Collections;

namespace Vala.Collections {
    /**
     * A fluent pipeline for transforming and aggregating collection data.
     *
     * Stream provides a chainable API for filter, map, sort, distinct,
     * limit/skip, and terminal operations like reduce, count, and
     * findFirst. Most intermediate operations return a new Stream,
     * except peek which returns the same instance for chaining.
     * Terminal operations produce a final result.
     *
     * Example:
     * {{{
     *     var list = new ArrayList<string> (GLib.str_equal);
     *     list.add ("banana");
     *     list.add ("apple");
     *     list.add ("cherry");
     *
     *     var result = Stream.fromList<string> (list)
     *         .filter ((s) => { return s.length > 5; })
     *         .sorted ((a, b) => { return strcmp (a, b); })
     *         .toList ();
     *     // result: ["banana", "cherry"]
     * }}}
     */
    public class Stream<T>: GLib.Object {
        private ArrayList<T> _data;

        /**
         * Creates a Stream wrapping the given ArrayList.
         * The list is shallow-copied so the source is not modified.
         *
         * @param data the source list.
         */
        private Stream (ArrayList<T> data) {
            _data = new ArrayList<T> ();
            for (int i = 0; i < data.size (); i++) {
                _data.add (data.get (i));
            }
        }

        /**
         * Creates a Stream from an ArrayList.
         *
         * Example:
         * {{{
         *     var list = new ArrayList<string> (GLib.str_equal);
         *     list.add ("a");
         *     var s = Stream.fromList<string> (list);
         * }}}
         *
         * @param list the source ArrayList.
         * @return a new Stream over the list elements.
         */
        public static Stream<T> fromList<T> (ArrayList<T> list) {
            return new Stream<T> (list);
        }

        /**
         * Creates an empty Stream.
         *
         * Example:
         * {{{
         *     var s = Stream.empty<string> ();
         *     assert (s.count () == 0);
         * }}}
         *
         * @return an empty Stream.
         */
        public static Stream<T> empty<T> () {
            return new Stream<T> (new ArrayList<T> ());
        }

        // -- Intermediate operations --

        /**
         * Returns a Stream containing only elements that match the predicate.
         *
         * Example:
         * {{{
         *     var result = stream.filter ((x) => { return x > 0; });
         * }}}
         *
         * @param fn the predicate function.
         * @return a new filtered Stream.
         */
        public Stream<T> filter (owned PredicateFunc<T> fn) {
            var result = new ArrayList<T> ();
            for (int i = 0; i < _data.size (); i++) {
                if (fn (_data.get (i))) {
                    result.add (_data.get (i));
                }
            }
            return new Stream<T> (result);
        }

        /**
         * Returns a Stream with each element transformed by the function.
         *
         * Example:
         * {{{
         *     var upper = stream.map<string> ((s) => { return s.up (); });
         * }}}
         *
         * @param fn the transformation function.
         * @return a new Stream with transformed elements.
         */
        public Stream<U> map<U> (owned MapFunc<T, U> fn) {
            var result = new ArrayList<U> ();
            for (int i = 0; i < _data.size (); i++) {
                result.add (fn (_data.get (i)));
            }
            return new Stream<U> (result);
        }

        /**
         * Returns a Stream sorted using the given comparator.
         *
         * Example:
         * {{{
         *     var sorted = stream.sorted ((a, b) => { return strcmp (a, b); });
         * }}}
         *
         * @param cmp the comparator function.
         * @return a new sorted Stream.
         */
        public Stream<T> sorted (owned ComparatorFunc<T> cmp) {
            var copy = new ArrayList<T> ();
            for (int i = 0; i < _data.size (); i++) {
                copy.add (_data.get (i));
            }
            copy.sort ((owned) cmp);
            return new Stream<T> (copy);
        }

        /**
         * Returns a Stream with duplicate elements removed.
         * Uses the provided equality function for comparison.
         *
         * Example:
         * {{{
         *     var unique = stream.distinct (GLib.str_equal);
         * }}}
         *
         * @param equal the equality function.
         * @return a new Stream with duplicates removed.
         */
        public Stream<T> distinct (GLib.EqualFunc<T> equal) {
            var result = new ArrayList<T> ();
            for (int i = 0; i < _data.size (); i++) {
                bool found = false;
                for (int j = 0; j < result.size (); j++) {
                    if (equal (result.get (j), _data.get (i))) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    result.add (_data.get (i));
                }
            }
            return new Stream<T> (result);
        }

        /**
         * Returns a Stream limited to the first n elements.
         *
         * Example:
         * {{{
         *     var first3 = stream.limit (3);
         * }}}
         *
         * @param n maximum number of elements.
         * @return a new limited Stream.
         */
        public Stream<T> limit (int n) {
            var result = new ArrayList<T> ();
            int count = int.min (n, (int) _data.size ());
            for (int i = 0; i < count; i++) {
                result.add (_data.get (i));
            }
            return new Stream<T> (result);
        }

        /**
         * Returns a Stream with the first n elements skipped.
         *
         * Example:
         * {{{
         *     var rest = stream.skip (2);
         * }}}
         *
         * @param n number of elements to skip.
         * @return a new Stream without the first n elements.
         */
        public Stream<T> skip (int n) {
            var result = new ArrayList<T> ();
            int start = int.max (0, n);
            for (int i = start; i < _data.size (); i++) {
                result.add (_data.get (i));
            }
            return new Stream<T> (result);
        }

        /**
         * Returns a Stream of elements taken while the predicate is true.
         * Stops at the first element that does not match.
         *
         * Example:
         * {{{
         *     var taken = stream.takeWhile ((x) => { return x < 5; });
         * }}}
         *
         * @param fn the predicate.
         * @return a new Stream of leading matching elements.
         */
        public Stream<T> takeWhile (owned PredicateFunc<T> fn) {
            var result = new ArrayList<T> ();
            for (int i = 0; i < _data.size (); i++) {
                if (!fn (_data.get (i))) {
                    break;
                }
                result.add (_data.get (i));
            }
            return new Stream<T> (result);
        }

        /**
         * Returns a Stream skipping elements while the predicate is true,
         * then includes all remaining elements.
         *
         * Example:
         * {{{
         *     var dropped = stream.dropWhile ((x) => { return x < 3; });
         * }}}
         *
         * @param fn the predicate.
         * @return a new Stream without the leading matching elements.
         */
        public Stream<T> dropWhile (owned PredicateFunc<T> fn) {
            var result = new ArrayList<T> ();
            bool dropping = true;
            for (int i = 0; i < _data.size (); i++) {
                if (dropping && fn (_data.get (i))) {
                    continue;
                }
                dropping = false;
                result.add (_data.get (i));
            }
            return new Stream<T> (result);
        }

        /**
         * Executes an action on each element and returns the same Stream.
         * Useful for debugging pipeline contents.
         *
         * Example:
         * {{{
         *     stream.peek ((x) => { print ("%s\n", x); }).toList ();
         * }}}
         *
         * @param fn the action to execute on each element.
         * @return the same Stream (for chaining).
         */
        public Stream<T> peek (owned ConsumerFunc<T> fn) {
            for (int i = 0; i < _data.size (); i++) {
                fn (_data.get (i));
            }
            return this;
        }

        // -- Terminal operations --

        /**
         * Collects the stream elements into an ArrayList.
         *
         * @return a new ArrayList with all stream elements.
         */
        public ArrayList<T> toList () {
            var result = new ArrayList<T> ();
            for (int i = 0; i < _data.size (); i++) {
                result.add (_data.get (i));
            }
            return result;
        }

        /**
         * Returns the number of elements in this stream.
         *
         * @return the element count.
         */
        public int count () {
            return (int) _data.size ();
        }

        /**
         * Returns the first element, or null if the stream is empty.
         *
         * @return the first element or null.
         */
        public T ? findFirst () {
            if (_data.size () == 0) {
                return null;
            }
            return _data.get (0);
        }

        /**
         * Returns the last element, or null if the stream is empty.
         *
         * @return the last element or null.
         */
        public T ? findLast () {
            if (_data.size () == 0) {
                return null;
            }
            return _data.get ((int) _data.size () - 1);
        }

        /**
         * Returns whether any element matches the predicate.
         *
         * @param fn the predicate.
         * @return true if at least one element matches.
         */
        public bool anyMatch (owned PredicateFunc<T> fn) {
            for (int i = 0; i < _data.size (); i++) {
                if (fn (_data.get (i))) {
                    return true;
                }
            }
            return false;
        }

        /**
         * Returns whether all elements match the predicate.
         * Returns true for an empty stream.
         *
         * @param fn the predicate.
         * @return true if all elements match.
         */
        public bool allMatch (owned PredicateFunc<T> fn) {
            for (int i = 0; i < _data.size (); i++) {
                if (!fn (_data.get (i))) {
                    return false;
                }
            }
            return true;
        }

        /**
         * Returns whether no elements match the predicate.
         * Returns true for an empty stream.
         *
         * @param fn the predicate.
         * @return true if no elements match.
         */
        public bool noneMatch (owned PredicateFunc<T> fn) {
            for (int i = 0; i < _data.size (); i++) {
                if (fn (_data.get (i))) {
                    return false;
                }
            }
            return true;
        }

        /**
         * Folds the stream into a single value by applying the accumulator
         * function to each element, starting from the initial value.
         *
         * Example:
         * {{{
         *     int sum = stream.reduce<int> (0, (acc, x) => { return acc + x; });
         * }}}
         *
         * @param initial the initial accumulator value.
         * @param fn the accumulator function.
         * @return the accumulated result.
         */
        public U reduce<U> (U initial, owned ReduceFunc<T, U> fn) {
            U result = initial;
            for (int i = 0; i < _data.size (); i++) {
                result = fn (result, _data.get (i));
            }
            return result;
        }

        /**
         * Executes an action for each element.
         *
         * @param fn the action to execute.
         */
        public void forEach (owned ConsumerFunc<T> fn) {
            for (int i = 0; i < _data.size (); i++) {
                fn (_data.get (i));
            }
        }

        /**
         * Returns the minimum element using the given comparator,
         * or null if the stream is empty.
         *
         * @param cmp the comparator.
         * @return the minimum element or null.
         */
        public T ? min (owned ComparatorFunc<T> cmp) {
            if (_data.size () == 0) {
                return null;
            }
            T best = _data.get (0);
            for (int i = 1; i < _data.size (); i++) {
                if (cmp (_data.get (i), best) < 0) {
                    best = _data.get (i);
                }
            }
            return best;
        }

        /**
         * Returns the maximum element using the given comparator,
         * or null if the stream is empty.
         *
         * @param cmp the comparator.
         * @return the maximum element or null.
         */
        public T ? max (owned ComparatorFunc<T> cmp) {
            if (_data.size () == 0) {
                return null;
            }
            T best = _data.get (0);
            for (int i = 1; i < _data.size (); i++) {
                if (cmp (_data.get (i), best) > 0) {
                    best = _data.get (i);
                }
            }
            return best;
        }
    }
}
