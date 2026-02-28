namespace Vala.Collections {
    /**
     * An immutable pair of two values.
     *
     * Pair is a Value Object: once created, its contents cannot change.
     * Inspired by Kotlin's Pair.
     *
     * Example:
     * {{{
     *     var pair = new Pair<string,string> ("key", "value");
     *     assert (pair.first () == "key");
     *     assert (pair.second () == "value");
     * }}}
     */
    public class Pair<A, B>: GLib.Object {
        private A _first;
        private B _second;

        /**
         * Creates a Pair with the given values.
         *
         * Example:
         * {{{
         *     var pair = new Pair<string,string> ("hello", "world");
         *     assert (pair.first () == "hello");
         *     assert (pair.second () == "world");
         * }}}
         *
         * @param first the first value.
         * @param second the second value.
         */
        public Pair (owned A first, owned B second) {
            _first = (owned) first;
            _second = (owned) second;
        }

        /**
         * Returns the first value.
         *
         * Example:
         * {{{
         *     var pair = new Pair<string,string> ("hello", "world");
         *     assert (pair.first () == "hello");
         * }}}
         *
         * @return the first value.
         */
        public A first () {
            return _first;
        }

        /**
         * Returns the second value.
         *
         * Example:
         * {{{
         *     var pair = new Pair<string,string> ("hello", "world");
         *     assert (pair.second () == "world");
         * }}}
         *
         * @return the second value.
         */
        public B second () {
            return _second;
        }

        /**
         * Returns whether this Pair is equal to another Pair.
         * Both the first and second values must be equal.
         *
         * Requires equality functions for both types because Vala
         * generics use pointer comparison by default.
         *
         * Example:
         * {{{
         *     var a = new Pair<string,string> ("x", "y");
         *     var b = new Pair<string,string> ("x", "y");
         *     assert (a.equals (b, GLib.str_equal, GLib.str_equal));
         * }}}
         *
         * @param other the other Pair to compare.
         * @param equal_a the equality function for the first type.
         * @param equal_b the equality function for the second type.
         * @return true if both values are equal.
         */
        public bool equals (Pair<A, B> other,
                            GLib.EqualFunc<A> equal_a,
                            GLib.EqualFunc<B> equal_b) {
            return equal_a (_first, other._first)
                   && equal_b (_second, other._second);
        }

        /**
         * Returns a string representation of the Pair.
         *
         * The format is ''(first, second)''. If the values are strings,
         * they are included directly. Otherwise, a type description is
         * used.
         *
         * Example:
         * {{{
         *     var pair = new Pair<string,string> ("a", "b");
         *     assert (pair.toString () == "(a, b)");
         * }}}
         *
         * @return the string representation.
         */
        public string toString () {
            string a_str = _value_to_string<A> (_first);
            string b_str = _value_to_string<B> (_second);
            return "(%s, %s)".printf (a_str, b_str);
        }
    }

    internal string _value_to_string<T> (T value) {
        if (value == null) {
            return "null";
        }
        if (typeof (T) == typeof (string)) {
            return (string) value;
        }
        if (typeof (T) == typeof (int)) {
            return "%d".printf ((int) value);
        }
        if (typeof (T) == typeof (bool)) {
            return ((bool) value).to_string ();
        }
        return typeof (T).name ();
    }
}
