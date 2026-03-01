using Vala.Collections;

namespace Vala.Concurrent {
    /**
     * Function used by {@link do} and {@link doFuture}.
     *
     * @return computed value.
     */
    public delegate T SingleFlightFunc<T> ();

    /**
     * Recoverable SingleFlight operation errors.
     */
    public errordomain SingleFlightError {
        INVALID_ARGUMENT,
        TYPE_MISMATCH,
        INTERNAL_STATE
    }

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
         * @throws SingleFlightError.INVALID_ARGUMENT when key is empty.
         * @throws SingleFlightError.TYPE_MISMATCH when the key is in flight with another value type.
         * @throws SingleFlightError.INTERNAL_STATE when internal entry state is corrupted.
         */
        public T @do<T> (string key, SingleFlightFunc<T> fn) throws SingleFlightError {
            if (key.length == 0) {
                throw new SingleFlightError.INVALID_ARGUMENT ("key must not be empty");
            }

            _mutex.lock ();
            InFlightEntry ? existing = _inFlight.get (key);
            if (existing != null) {
                if (existing.valueType != typeof (T)) {
                    _mutex.unlock ();
                    throw new SingleFlightError.TYPE_MISMATCH (
                              "key `%s` is already in flight with different type".printf (key)
                    );
                }

                InFlightCall<T> ? waiter = existing.call as InFlightCall<T>;
                _mutex.unlock ();

                if (waiter == null) {
                    throw new SingleFlightError.INTERNAL_STATE (
                              "internal singleflight state is invalid"
                    );
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
         *
         * Returns a failed future when key is empty.
         */
        public Future<T> doFuture<T> (string key, owned SingleFlightFunc<T> fn) {
            if (key.length == 0) {
                return Future<T>.failed<T> ("key must not be empty");
            }

            var captured = (owned) fn;
            var future = Future<T>.pending<T> ();

            var group = this;
            ThreadPool.go (() => {
                try {
                    T result = group.@do<T> (key, captured);
                    future.completeSuccess ((owned) result);
                } catch (SingleFlightError e) {
                    future.completeFailure (e.message);
                }
            });
            return future;
        }

        /**
         * Forgets in-flight state for key.
         *
         * This does not cancel already running computation.
         *
         * @param key deduplication key.
         *
         * Empty key is ignored.
         */
        public void forget (string key) {
            if (key.length == 0) {
                return;
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
         *
         * Returns false for empty key.
         */
        public bool hasInFlight (string key) {
            if (key.length == 0) {
                return false;
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
