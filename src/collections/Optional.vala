namespace Vala.Collections {
    /**
     * A container object that may or may not contain a value.
     *
     * Optional is a type-safe alternative to null. Instead of returning
     * null, methods can return Optional to explicitly indicate that a
     * value may be absent. Inspired by Java's Optional, OCaml's option,
     * and Rust's Option.
     *
     * Example:
     * {{{
     *     var opt = Optional.of<string> ("hello");
     *     assert (opt.isPresent ());
     *     assert (opt.get () == "hello");
     *
     *     var empty = Optional.empty<string> ();
     *     assert (empty.isEmpty ());
     *     assert (empty.orElse ("default") == "default");
     * }}}
     */
    public class Optional<T>: GLib.Object {
        private T ? _value;
        private bool _present;

        private Optional (owned T ? value, bool present) {
            _value = (owned) value;
            _present = present;
        }

        /**
         * Creates an Optional containing the given value.
         *
         * Example:
         * {{{
         *     var opt = Optional.of<string> ("hello");
         *     assert (opt.get () == "hello");
         * }}}
         *
         * @param value the value to wrap.
         * @return an Optional containing the value.
         */
        public static Optional<T> of<T>(owned T value) {
            return new Optional<T>((owned) value, true);
        }

        /**
         * Creates an empty Optional with no value.
         *
         * Example:
         * {{{
         *     var empty = Optional.empty<string> ();
         *     assert (empty.isEmpty ());
         * }}}
         *
         * @return an empty Optional.
         */
        public static Optional<T> empty<T> () {
            return new Optional<T>(null, false);
        }

        /**
         * Creates an Optional from a nullable value. If the value is
         * null, returns an empty Optional; otherwise wraps the value.
         *
         * Example:
         * {{{
         *     string? name = "Alice";
         *     var opt = Optional.ofNullable<string> (name);
         *     assert (opt.isPresent ());
         * }}}
         *
         * @param value the possibly-null value.
         * @return an Optional containing the value, or empty if null.
         */
        public static Optional<T> ofNullable<T>(owned T ? value) {
            if (value == null) {
                return empty<T> ();
            }
            return new Optional<T>((owned) value, true);
        }

        /**
         * Returns whether a value is present.
         *
         * @return true if a value is present.
         */
        public bool isPresent () {
            return _present;
        }

        /**
         * Returns whether this Optional is empty.
         *
         * @return true if no value is present.
         */
        public bool isEmpty () {
            return !_present;
        }

        /**
         * Returns the contained value. Returns null if no value is
         * present.
         *
         * Example:
         * {{{
         *     var opt = Optional.of<string> ("hello");
         *     assert (opt.get () == "hello");
         * }}}
         *
         * @return the value, or null if empty.
         */
        public T ? get () {
            if (!_present) {
                return null;
            }
            return _value;
        }

        /**
         * Returns the value if present, otherwise returns the given
         * default value.
         *
         * Example:
         * {{{
         *     var empty = Optional.empty<string> ();
         *     assert (empty.orElse ("default") == "default");
         * }}}
         *
         * @param other the default value.
         * @return the value if present, otherwise other.
         */
        public T orElse (T other) {
            if (_present) {
                return _value;
            }
            return other;
        }

        /**
         * Returns the value if present, otherwise invokes the supplier
         * function and returns its result.
         *
         * Example:
         * {{{
         *     var empty = Optional.empty<string> ();
         *     var val = empty.orElseGet (() => { return "computed"; });
         * }}}
         *
         * @param supplier a function that produces a default value.
         * @return the value if present, otherwise the supplier result.
         */
        public T orElseGet (owned SupplierFunc<T> supplier) {
            if (_present) {
                return _value;
            }
            return supplier ();
        }

        /**
         * If a value is present, invokes the given function with the
         * value.
         *
         * Example:
         * {{{
         *     Optional.of<string> ("hello").ifPresent ((v) => {
         *         print ("%s\n", v);
         *     });
         * }}}
         *
         * @param func the function to invoke.
         */
        public void ifPresent (owned ConsumerFunc<T> func) {
            if (_present) {
                func (_value);
            }
        }

        /**
         * If a value is present and matches the predicate, returns this
         * Optional; otherwise returns an empty Optional.
         *
         * Example:
         * {{{
         *     var opt = Optional.of<string> ("hello");
         *     var filtered = opt.filter ((s) => { return s == "hello"; });
         *     assert (filtered.isPresent ());
         * }}}
         *
         * @param predicate the condition to test.
         * @return this Optional if matching, otherwise empty.
         */
        public Optional<T> filter (owned PredicateFunc<T> predicate) {
            if (!_present) {
                return empty<T> ();
            }
            if (predicate (_value)) {
                return this;
            }
            return empty<T> ();
        }
    }

    /**
     * A function that takes no arguments and returns a value.
     */
    public delegate T SupplierFunc<T> ();

    /**
     * A function that takes a value and returns nothing.
     */
    public delegate void ConsumerFunc<T>(T value);

    /**
     * A function that takes a value and returns a boolean.
     */
    public delegate bool PredicateFunc<T>(T value);
}
