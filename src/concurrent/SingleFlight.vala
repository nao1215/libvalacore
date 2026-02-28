using Vala.Collections;

namespace Vala.Concurrent {
    /**
     * Function used by {@link do} and {@link doFuture}.
     *
     * @return computed value.
     */
    public delegate T SingleFlightFunc<T> ();

    internal class InFlightCall<T>: GLib.Object {
        private GLib.Mutex _mutex;
        private GLib.Cond _cond;
        private bool _done;
        private T _value;

        public InFlightCall () {
            _done = false;
        }

        public void complete (T value) {
            _mutex.lock ();
            if (_done) {
                _mutex.unlock ();
                return;
            }

            _value = value;
            _done = true;
            _cond.broadcast ();
            _mutex.unlock ();
        }

        public T waitResult () {
            _mutex.lock ();
            while (!_done) {
                _cond.wait (_mutex);
            }
            T value = _value;
            _mutex.unlock ();
            return value;
        }
    }

    internal class InFlightEntry : GLib.Object {
        public Type valueType { get; private set; }
        public GLib.Object call { get; private set; }

        public InFlightEntry (Type valueType, GLib.Object call) {
            this.valueType = valueType;
            this.call = call;
        }
    }

    /**
     * Suppresses duplicate concurrent work for the same key.
     *
     * SingleFlight ensures only one execution per key is running at a time.
     * Concurrent callers for the same key wait and receive the same result.
     *
     * Example:
     * {{{
     *     var group = new SingleFlight ();
     *     int? value = group.@do<int> ("user:42", () => {
     *         return 42;
     *     });
     *     assert (value == 42);
     * }}}
     */
    public class SingleFlight : GLib.Object {
        private GLib.Mutex _mutex;
        private HashMap<string, InFlightEntry> _inFlight;

        /**
         * Creates an empty SingleFlight group.
         */
        public SingleFlight () {
            _inFlight = new HashMap<string, InFlightEntry> (GLib.str_hash, GLib.str_equal);
        }

        /**
         * Executes the function once for a key and shares the result.
         *
         * If the same key is already in flight, this call waits for the
         * running execution and returns its result.
         *
         * @param key deduplication key.
         * @param fn function to run.
         * @return shared result.
         */
        public T @do<T> (string key, SingleFlightFunc<T> fn) {
            if (key.length == 0) {
                GLib.error ("key must not be empty");
            }

            _mutex.lock ();
            InFlightEntry ? existing = _inFlight.get (key);
            if (existing != null) {
                if (existing.valueType != typeof (T)) {
                    _mutex.unlock ();
                    GLib.error ("key `%s` is already in flight with different type", key);
                }

                InFlightCall<T> ? waiter = existing.call as InFlightCall<T>;
                _mutex.unlock ();

                if (waiter == null) {
                    GLib.error ("internal singleflight state is invalid");
                }

                return waiter.waitResult ();
            }

            var call = new InFlightCall<T> ();
            _inFlight.put (key, new InFlightEntry (typeof (T), call));
            _mutex.unlock ();

            T result = fn ();
            call.complete (result);

            _mutex.lock ();
            InFlightEntry ? current = _inFlight.get (key);
            if (current != null && current.call == call) {
                _inFlight.remove (key);
            }
            _mutex.unlock ();

            return result;
        }

        /**
         * Asynchronous version of {@link do}.
         *
         * @param key deduplication key.
         * @param fn function to run.
         * @return future of shared result.
         */
        public Future<T> doFuture<T> (string key, owned SingleFlightFunc<T> fn) {
            if (key.length == 0) {
                GLib.error ("key must not be empty");
            }

            var captured = (owned) fn;
            return Future<T>.run<T> (() => {
                return @do<T> (key, captured);
            });
        }

        /**
         * Forgets in-flight state for key.
         *
         * This does not cancel already running computation.
         *
         * @param key deduplication key.
         */
        public void forget (string key) {
            if (key.length == 0) {
                GLib.error ("key must not be empty");
            }

            _mutex.lock ();
            _inFlight.remove (key);
            _mutex.unlock ();
        }

        /**
         * Returns current number of in-flight keys.
         *
         * @return in-flight key count.
         */
        public int inFlightCount () {
            _mutex.lock ();
            int count = (int) _inFlight.size ();
            _mutex.unlock ();
            return count;
        }

        /**
         * Returns whether key is currently in flight.
         *
         * @param key deduplication key.
         * @return true when key is in flight.
         */
        public bool hasInFlight (string key) {
            if (key.length == 0) {
                GLib.error ("key must not be empty");
            }

            _mutex.lock ();
            bool has = _inFlight.containsKey (key);
            _mutex.unlock ();
            return has;
        }

        /**
         * Removes all in-flight keys from tracking.
         *
         * Running computations are not cancelled.
         */
        public void clear () {
            _mutex.lock ();
            _inFlight.clear ();
            _mutex.unlock ();
        }
    }
}
