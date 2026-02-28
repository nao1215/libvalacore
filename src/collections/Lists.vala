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
        public static Pair<ArrayList<string>, ArrayList<string> > partitionString (ArrayList<string> list, owned PredicateFunc<string> fn) {
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
        public static HashMap<string, ArrayList<string> > groupByString (ArrayList<string> list, owned MapFunc<string, string> keyFn) {
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
            var result = new ArrayList<string> (GLib.str_equal);
            for (int i = 0; i < (int) list.size (); i++) {
                if (!result.contains (list.get (i))) {
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
