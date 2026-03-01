using Vala.Collections;

namespace Vala.Collections {
    /**
     * Static utility methods for ArrayList operations.
     *
     * Lists provides high-level operations like partition, chunk, zip,
     * flatten, and groupBy that would otherwise require 5-15 lines of
     * manual loop code.
     *
     * Example:
     * {{{
     *     var list = new ArrayList<string> (GLib.str_equal);
     *     list.add ("a");
     *     list.add ("b");
     *     list.add ("c");
     *     list.add ("d");
     *     var chunks = Lists.chunkString (list, 2);
     *     // chunks: [["a","b"], ["c","d"]]
     * }}}
     */
    public class Lists : GLib.Object {
        /**
         * Splits a list into matching and non-matching lists.
         *
         * @param list source list.
         * @param fn predicate function.
         * @return Pair of (matching, rest) lists.
         */
        public static Pair<ArrayList<T>, ArrayList<T> > partition<T> (ArrayList<T> list,
                                                                      owned PredicateFunc<T> fn) {
            var matching = new ArrayList<T> ();
            var rest = new ArrayList<T> ();
            for (int i = 0; i < (int) list.size (); i++) {
                T item = list.get (i);
                if (fn (item)) {
                    matching.add (item);
                } else {
                    rest.add (item);
                }
            }
            return new Pair<ArrayList<T>, ArrayList<T> > (matching, rest);
        }

        /**
         * Splits a list into fixed-size chunks.
         *
         * @param list source list.
         * @param size chunk size (must be > 0).
         * @return list of chunked lists.
         */
        public static ArrayList<ArrayList<T> > chunk<T> (ArrayList<T> list, int size) {
            if (size <= 0) {
                error ("chunk size must be positive, got %d", size);
            }
            var result = new ArrayList<ArrayList<T> > ();
            var current = new ArrayList<T> ();
            for (int i = 0; i < (int) list.size (); i++) {
                current.add (list.get (i));
                if ((int) current.size () == size) {
                    result.add (current);
                    current = new ArrayList<T> ();
                }
            }
            if (current.size () > 0) {
                result.add (current);
            }
            return result;
        }

        /**
         * Combines two lists into list of pairs.
         * Result size is minimum of both input sizes.
         *
         * @param a first list.
         * @param b second list.
         * @return zipped pairs.
         */
        public static ArrayList<Pair<A, B> > zip<A, B> (ArrayList<A> a, ArrayList<B> b) {
            var result = new ArrayList<Pair<A, B> > ();
            int len = int.min ((int) a.size (), (int) b.size ());
            for (int i = 0; i < len; i++) {
                result.add (new Pair<A, B> (a.get (i), b.get (i)));
            }
            return result;
        }

        /**
         * Creates (index, element) pairs for a list.
         *
         * @param list source list.
         * @return index-element pairs.
         */
        public static ArrayList<Pair<int, T> > zipWithIndex<T> (ArrayList<T> list) {
            var result = new ArrayList<Pair<int, T> > ();
            for (int i = 0; i < (int) list.size (); i++) {
                result.add (new Pair<int, T> (i, list.get (i)));
            }
            return result;
        }

        /**
         * Flattens nested lists into one list.
         *
         * @param nested nested list.
         * @return flattened list.
         */
        public static ArrayList<T> flatten<T> (ArrayList<ArrayList<T> > nested) {
            var result = new ArrayList<T> ();
            for (int i = 0; i < (int) nested.size (); i++) {
                var inner = nested.get (i);
                for (int j = 0; j < (int) inner.size (); j++) {
                    result.add (inner.get (j));
                }
            }
            return result;
        }

        /**
         * Groups list elements by computed keys.
         *
         * @param list source list.
         * @param keyFn key extraction function.
         * @param hash_func hash function for key type K.
         * @param equal_func equality function for key type K.
         * @return map of key to grouped elements.
         */
        public static HashMap<K, ArrayList<T> > groupBy<T, K> (ArrayList<T> list,
                                                               owned MapFunc<T, K> keyFn,
                                                               GLib.HashFunc<K> hash_func,
                                                               GLib.EqualFunc<K> equal_func) {
            var result = new HashMap<K, ArrayList<T> > (hash_func, equal_func);
            for (int i = 0; i < (int) list.size (); i++) {
                T item = list.get (i);
                K key = keyFn (item);
                ArrayList<T> ? group = result.get (key);
                if (group == null) {
                    group = new ArrayList<T> ();
                    result.put (key, group);
                }
                group.add (item);
            }
            return result;
        }

        /**
         * Removes duplicate elements while preserving order.
         *
         * @param list source list.
         * @param hash_func hash function for element type T.
         * @param equal_func equality function for element type T.
         * @return list with duplicates removed.
         */
        public static ArrayList<T> distinct<T> (ArrayList<T> list,
                                                GLib.HashFunc<T> hash_func,
                                                GLib.EqualFunc<T> equal_func) {
            var seen = new HashSet<T> (hash_func, equal_func);
            var result = new ArrayList<T> ();
            for (int i = 0; i < (int) list.size (); i++) {
                T item = list.get (i);
                if (!seen.contains (item)) {
                    seen.add (item);
                    result.add (item);
                }
            }
            return result;
        }

        /**
         * Rotates elements by distance and returns new list.
         * Positive values rotate right, negative rotate left.
         *
         * @param list source list.
         * @param distance rotation amount.
         * @return rotated list.
         */
        public static ArrayList<T> rotate<T> (ArrayList<T> list, int distance) {
            var result = new ArrayList<T> ();
            int len = (int) list.size ();
            if (len == 0) {
                return result;
            }
            int shift = distance % len;
            if (shift < 0) {
                shift += len;
            }
            for (int i = 0; i < len; i++) {
                int src = (i - shift + len) % len;
                result.add (list.get (src));
            }
            return result;
        }

        /**
         * Returns a shuffled copy of the list.
         *
         * @param list source list.
         * @return shuffled list.
         */
        public static ArrayList<T> shuffle<T> (ArrayList<T> list) {
            var result = new ArrayList<T> ();
            for (int i = 0; i < (int) list.size (); i++) {
                result.add (list.get (i));
            }
            for (int i = (int) result.size () - 1; i > 0; i--) {
                int j = GLib.Random.int_range (0, i + 1);
                T tmp = result.get (i);
                result.set (i, result.get (j));
                result.set (j, tmp);
            }
            return result;
        }

        /**
         * Returns sliding windows over a list.
         *
         * @param list source list.
         * @param windowSize window size (must be > 0).
         * @return list of windows.
         */
        public static ArrayList<ArrayList<T> > sliding<T> (ArrayList<T> list, int windowSize) {
            if (windowSize <= 0) {
                error ("windowSize must be positive, got %d", windowSize);
            }
            var result = new ArrayList<ArrayList<T> > ();
            for (int i = 0; i <= (int) list.size () - windowSize; i++) {
                var window = new ArrayList<T> ();
                for (int j = 0; j < windowSize; j++) {
                    window.add (list.get (i + j));
                }
                result.add (window);
            }
            return result;
        }

        /**
         * Interleaves two lists by alternating elements.
         *
         * @param a first list.
         * @param b second list.
         * @return interleaved list.
         */
        public static ArrayList<T> interleave<T> (ArrayList<T> a, ArrayList<T> b) {
            var result = new ArrayList<T> ();
            int max = int.max ((int) a.size (), (int) b.size ());
            for (int i = 0; i < max; i++) {
                if (i < (int) a.size ()) {
                    result.add (a.get (i));
                }
                if (i < (int) b.size ()) {
                    result.add (b.get (i));
                }
            }
            return result;
        }

        /**
         * Counts element frequencies in a list.
         *
         * @param list source list.
         * @param hash_func hash function for element type T.
         * @param equal_func equality function for element type T.
         * @return map of element to occurrence count.
         */
        public static HashMap<T, int> frequency<T> (ArrayList<T> list,
                                                    GLib.HashFunc<T> hash_func,
                                                    GLib.EqualFunc<T> equal_func) {
            var result = new HashMap<T, int> (hash_func, equal_func);
            for (int i = 0; i < (int) list.size (); i++) {
                T key = list.get (i);
                if (result.containsKey (key)) {
                    int ? count = result.get (key);
                    result.put (key, (count != null ? count : 0) + 1);
                } else {
                    result.put (key, 1);
                }
            }
            return result;
        }

        /**
         * Sorts list by computed key using key comparator.
         *
         * @param list source list.
         * @param keyFn key extraction function.
         * @param cmp comparator for key type K.
         * @return new sorted list.
         */
        public static ArrayList<T> sortBy<T, K> (ArrayList<T> list,
                                                 owned MapFunc<T, K> keyFn,
                                                 owned ComparatorFunc<K> cmp) {
            var result = new ArrayList<T> ();
            for (int i = 0; i < (int) list.size (); i++) {
                result.add (list.get (i));
            }
            result.sort ((a, b) => {
                return cmp (keyFn (a), keyFn (b));
            });
            return result;
        }

        /**
         * Splits a string list into two lists based on a predicate.
         * The first list contains elements matching the predicate,
         * the second contains the rest.
         *
         * Example:
         * {{{
         *     var pair = Lists.partitionString (list, (s) => {
         *         return s.has_prefix ("a");
         *     });
         *     // pair.first = items starting with "a"
         *     // pair.second = all others
         * }}}
         *
         * @param list the source list.
         * @param fn the predicate.
         * @return a Pair of (matching, non-matching) lists.
         */
        public static Pair<ArrayList<string>, ArrayList<string> > partitionString (ArrayList<string> list,
                                                                                   owned PredicateFunc<string> fn) {
            var matching = new ArrayList<string> (GLib.str_equal);
            var rest = new ArrayList<string> (GLib.str_equal);
            for (int i = 0; i < (int) list.size (); i++) {
                if (fn (list.get (i))) {
                    matching.add (list.get (i));
                } else {
                    rest.add (list.get (i));
                }
            }
            return new Pair<ArrayList<string>, ArrayList<string> > (matching, rest);
        }

        /**
         * Splits a string list into sub-lists of the given size.
         * The last chunk may be smaller.
         *
         * Example:
         * {{{
         *     var chunks = Lists.chunkString (list, 3);
         * }}}
         *
         * @param list the source list.
         * @param size the chunk size (must be > 0).
         * @return an ArrayList of chunk lists.
         */
        public static ArrayList<ArrayList<string> > chunkString (ArrayList<string> list, int size) {
            if (size <= 0) {
                error ("chunk size must be positive, got %d", size);
            }
            var result = new ArrayList<ArrayList<string> > ();
            var current = new ArrayList<string> (GLib.str_equal);
            for (int i = 0; i < (int) list.size (); i++) {
                current.add (list.get (i));
                if ((int) current.size () == size) {
                    result.add (current);
                    current = new ArrayList<string> (GLib.str_equal);
                }
            }
            if (current.size () > 0) {
                result.add (current);
            }
            return result;
        }

        /**
         * Combines two string lists into a list of Pairs.
         * The result length is the minimum of both list sizes.
         *
         * Example:
         * {{{
         *     var pairs = Lists.zipString (keys, values);
         * }}}
         *
         * @param a the first list.
         * @param b the second list.
         * @return an ArrayList of Pairs.
         */
        public static ArrayList<Pair<string, string> > zipString (ArrayList<string> a, ArrayList<string> b) {
            var result = new ArrayList<Pair<string, string> > ();
            int len = int.min ((int) a.size (), (int) b.size ());
            for (int i = 0; i < len; i++) {
                result.add (new Pair<string, string> (a.get (i), b.get (i)));
            }
            return result;
        }

        /**
         * Creates a list of Pairs with each element and its index.
         *
         * Example:
         * {{{
         *     var indexed = Lists.zipWithIndexString (list);
         *     // indexed[0] = Pair(0, "a")
         * }}}
         *
         * @param list the source list.
         * @return an ArrayList of (index, element) Pairs.
         */
        public static ArrayList<Pair<int, string> > zipWithIndexString (ArrayList<string> list) {
            var result = new ArrayList<Pair<int, string> > ();
            for (int i = 0; i < (int) list.size (); i++) {
                result.add (new Pair<int, string> (i, list.get (i)));
            }
            return result;
        }

        /**
         * Flattens a nested list of string lists into a single list.
         *
         * Example:
         * {{{
         *     var flat = Lists.flattenString (nested);
         * }}}
         *
         * @param nested the nested list.
         * @return a flat ArrayList.
         */
        public static ArrayList<string> flattenString (ArrayList<ArrayList<string> > nested) {
            var result = new ArrayList<string> (GLib.str_equal);
            for (int i = 0; i < (int) nested.size (); i++) {
                var inner = nested.get (i);
                for (int j = 0; j < (int) inner.size (); j++) {
                    result.add (inner.get (j));
                }
            }
            return result;
        }

        /**
         * Groups elements by a key extracted from each element.
         *
         * Example:
         * {{{
         *     var groups = Lists.groupByString (words, (w) => {
         *         return w.substring (0, 1);
         *     });
         *     // groups["a"] = ["apple", "avocado"]
         * }}}
         *
         * @param list the source list.
         * @param keyFn the key extraction function.
         * @return a HashMap of key to grouped list.
         */
        public static HashMap<string, ArrayList<string> > groupByString (ArrayList<string> list,
                                                                         owned MapFunc<string, string> keyFn) {
            var result = new HashMap<string, ArrayList<string> > (GLib.str_hash, GLib.str_equal);
            for (int i = 0; i < (int) list.size (); i++) {
                string key = keyFn (list.get (i));
                if (!result.containsKey (key)) {
                    result.put (key, new ArrayList<string> (GLib.str_equal));
                }
                result.get (key).add (list.get (i));
            }
            return result;
        }

        /**
         * Removes duplicates from a string list, preserving order.
         *
         * @param list the source list.
         * @return a new list with duplicates removed.
         */
        public static ArrayList<string> distinctString (ArrayList<string> list) {
            var seen = new HashSet<string> (GLib.str_hash, GLib.str_equal);
            var result = new ArrayList<string> (GLib.str_equal);
            for (int i = 0; i < (int) list.size (); i++) {
                if (!seen.contains (list.get (i))) {
                    seen.add (list.get (i));
                    result.add (list.get (i));
                }
            }
            return result;
        }

        /**
         * Returns a reversed copy of the string list.
         *
         * @param list the source list.
         * @return a new reversed list.
         */
        public static ArrayList<string> reverseString (ArrayList<string> list) {
            var result = new ArrayList<string> (GLib.str_equal);
            for (int i = (int) list.size () - 1; i >= 0; i--) {
                result.add (list.get (i));
            }
            return result;
        }

        /**
         * Returns sliding windows of the given size over the list.
         *
         * Example:
         * {{{
         *     // list = ["a", "b", "c", "d"]
         *     var windows = Lists.slidingString (list, 2);
         *     // [["a","b"], ["b","c"], ["c","d"]]
         * }}}
         *
         * @param list the source list.
         * @param windowSize the window size (must be > 0).
         * @return an ArrayList of window lists.
         */
        public static ArrayList<ArrayList<string> > slidingString (ArrayList<string> list, int windowSize) {
            if (windowSize <= 0) {
                error ("windowSize must be positive, got %d", windowSize);
            }
            var result = new ArrayList<ArrayList<string> > ();
            for (int i = 0; i <= (int) list.size () - windowSize; i++) {
                var window = new ArrayList<string> (GLib.str_equal);
                for (int j = 0; j < windowSize; j++) {
                    window.add (list.get (i + j));
                }
                result.add (window);
            }
            return result;
        }

        /**
         * Interleaves two string lists by alternating elements.
         *
         * Example:
         * {{{
         *     // a = ["1","3"], b = ["2","4"]
         *     var result = Lists.interleaveString (a, b);
         *     // ["1","2","3","4"]
         * }}}
         *
         * @param a the first list.
         * @param b the second list.
         * @return a new interleaved list.
         */
        public static ArrayList<string> interleaveString (ArrayList<string> a, ArrayList<string> b) {
            var result = new ArrayList<string> (GLib.str_equal);
            int max = int.max ((int) a.size (), (int) b.size ());
            for (int i = 0; i < max; i++) {
                if (i < (int) a.size ()) {
                    result.add (a.get (i));
                }
                if (i < (int) b.size ()) {
                    result.add (b.get (i));
                }
            }
            return result;
        }

        /**
         * Counts the frequency of each string in the list.
         *
         * @param list the source list.
         * @return a HashMap of element to count.
         */
        public static HashMap<string, int> frequencyString (ArrayList<string> list) {
            var result = new HashMap<string, int> (GLib.str_hash, GLib.str_equal);
            for (int i = 0; i < (int) list.size (); i++) {
                string key = list.get (i);
                if (result.containsKey (key)) {
                    result.put (key, result.get (key) + 1);
                } else {
                    result.put (key, 1);
                }
            }
            return result;
        }
    }
}
