namespace Vala.Collections {
    /**
     * An immutable triple of three values.
     *
     * Triple is a Value Object: once created, its contents cannot change.
     * Inspired by Kotlin's Triple.
     *
     * Example:
     * {{{
     *     var triple = new Triple<string,string,string> ("r", "g", "b");
     *     assert (triple.first () == "r");
     *     assert (triple.second () == "g");
     *     assert (triple.third () == "b");
     * }}}
     */
    public class Triple<A, B, C>: GLib.Object {
        private A _first;
        private B _second;
        private C _third;

        /**
         * Creates a Triple with the given values.
         *
         * Example:
         * {{{
         *     var triple = new Triple<string,string,string> ("a", "b", "c");
         *     assert (triple.first () == "a");
         * }}}
         *
         * @param first the first value.
         * @param second the second value.
         * @param third the third value.
         */
        public Triple (owned A first, owned B second, owned C third) {
            _first = (owned) first;
            _second = (owned) second;
            _third = (owned) third;
        }

        /**
         * Returns the first value.
         *
         * Example:
         * {{{
         *     var t = new Triple<string,string,string> ("a", "b", "c");
         *     assert (t.first () == "a");
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
         *     var t = new Triple<string,string,string> ("a", "b", "c");
         *     assert (t.second () == "b");
         * }}}
         *
         * @return the second value.
         */
        public B second () {
            return _second;
        }

        /**
         * Returns the third value.
         *
         * Example:
         * {{{
         *     var t = new Triple<string,string,string> ("a", "b", "c");
         *     assert (t.third () == "c");
         * }}}
         *
         * @return the third value.
         */
        public C third () {
            return _third;
        }

        /**
         * Returns whether this Triple is equal to another Triple.
         * All three values must be equal.
         *
         * Requires equality functions for all types because Vala
         * generics use pointer comparison by default.
         *
         * Example:
         * {{{
         *     var a = new Triple<string,string,string> ("x", "y", "z");
         *     var b = new Triple<string,string,string> ("x", "y", "z");
         *     assert (a.equals (b, GLib.str_equal, GLib.str_equal, GLib.str_equal));
         * }}}
         *
         * @param other the other Triple to compare.
         * @param equal_a the equality function for the first type.
         * @param equal_b the equality function for the second type.
         * @param equal_c the equality function for the third type.
         * @return true if all three values are equal.
         */
        public bool equals (Triple<A, B, C> other,
                            GLib.EqualFunc<A> equal_a,
                            GLib.EqualFunc<B> equal_b,
                            GLib.EqualFunc<C> equal_c) {
            return equal_a (_first, other._first)
                   && equal_b (_second, other._second)
                   && equal_c (_third, other._third);
        }

        /**
         * Returns a string representation of the Triple.
         *
         * The format is ''(first, second, third)''.
         *
         * Example:
         * {{{
         *     var t = new Triple<string,string,string> ("a", "b", "c");
         *     assert (t.toString () == "(a, b, c)");
         * }}}
         *
         * @return the string representation.
         */
        public string toString () {
            string a_str = _value_to_string<A> (_first);
            string b_str = _value_to_string<B> (_second);
            string c_str = _value_to_string<C> (_third);
            return "(%s, %s, %s)".printf (a_str, b_str, c_str);
        }
    }
}
