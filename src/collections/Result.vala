namespace Vala.Collections {
    /**
     * A container representing either a success value or an error.
     *
     * Result is used for operations that can fail, providing a type-safe
     * alternative to exceptions. Inspired by Rust's Result, OCaml's result,
     * and Go's error-return pattern.
     *
     * Example:
     * {{{
     *     var success = Result.ok<string,string> ("data");
     *     assert (success.isOk ());
     *     assert (success.unwrap () == "data");
     *
     *     var failure = Result.error<string,string> ("not found");
     *     assert (failure.isError ());
     *     assert (failure.unwrapOr ("fallback") == "fallback");
     * }}}
     */
    public class Result<T, E>: GLib.Object {
        private T ? _value;
        private E ? _error;
        private bool _ok;

        private Result (owned T ? value, owned E ? error, bool ok) {
            _value = (owned) value;
            _error = (owned) error;
            _ok = ok;
        }

        /**
         * Creates a successful Result containing the given value.
         *
         * Example:
         * {{{
         *     var r = Result.ok<string,string> ("hello");
         *     assert (r.isOk ());
         * }}}
         *
         * @param value the success value.
         * @return a successful Result.
         */
        public static Result<T, E> ok<T, E> (owned T value) {
            return new Result<T, E> ((owned) value, null, true);
        }

        /**
         * Creates a failed Result containing the given error.
         *
         * Example:
         * {{{
         *     var r = Result.error<string,string> ("not found");
         *     assert (r.isError ());
         * }}}
         *
         * @param err the error value.
         * @return a failed Result.
         */
        public static Result<T, E> error<T, E> (owned E err) {
            return new Result<T, E> (null, (owned) err, false);
        }

        /**
         * Returns whether this Result is a success.
         *
         * @return true if this is a success Result.
         */
        public bool isOk () {
            return _ok;
        }

        /**
         * Returns whether this Result is an error.
         *
         * @return true if this is an error Result.
         */
        public bool isError () {
            return !_ok;
        }

        /**
         * Returns the success value. Returns null if this is an error.
         *
         * Example:
         * {{{
         *     var r = Result.ok<string,string> ("data");
         *     assert (r.unwrap () == "data");
         * }}}
         *
         * @return the success value, or null if error.
         */
        public T ? unwrap () {
            if (!_ok) {
                return null;
            }
            return _value;
        }

        /**
         * Returns the success value if present, otherwise returns the
         * given default value.
         *
         * Example:
         * {{{
         *     var r = Result.error<string,string> ("err");
         *     assert (r.unwrapOr ("fallback") == "fallback");
         * }}}
         *
         * @param defaultValue the default to return on error.
         * @return the success value, or defaultValue on error.
         */
        public T unwrapOr (T defaultValue) {
            if (_ok) {
                return _value;
            }
            return defaultValue;
        }

        /**
         * Returns the error value. Returns null if this is a success.
         *
         * Example:
         * {{{
         *     var r = Result.error<string,string> ("not found");
         *     assert (r.unwrapError () == "not found");
         * }}}
         *
         * @return the error value, or null if success.
         */
        public E ? unwrapError () {
            if (_ok) {
                return null;
            }
            return _error;
        }

        /**
         * If this is a success, applies the function to the value and
         * returns a new Result. If this is an error, returns the error
         * unchanged.
         *
         * Example:
         * {{{
         *     var r = Result.ok<string,string> ("hello");
         *     var mapped = r.map<string> ((s) => { return s.up (); });
         *     assert (mapped.unwrap () == "HELLO");
         * }}}
         *
         * @param func the transformation function.
         * @return a new Result with the transformed value.
         */
        public Result<U, E> map<U> (owned MapFunc<T, U> func) {
            if (_ok) {
                return Result.ok<U, E> (func (_value));
            }
            return Result.error<U, E> (_error);
        }

        /**
         * If this is an error, applies the function to the error and
         * returns a new Result. If this is a success, returns the value
         * unchanged.
         *
         * Example:
         * {{{
         *     var r = Result.error<string,string> ("err");
         *     var mapped = r.mapError<string> ((e) => { return e.up (); });
         *     assert (mapped.unwrapError () == "ERR");
         * }}}
         *
         * @param func the error transformation function.
         * @return a new Result with the transformed error.
         */
        public Result<T, F> mapError<F> (owned MapFunc<E, F> func) {
            if (!_ok) {
                return Result.error<T, F> (func (_error));
            }
            return Result.ok<T, F> (_value);
        }
    }

    /**
     * A function that transforms a value of type T to type U.
     */
    public delegate U MapFunc<T, U> (T value);
}
