using Vala.Collections;
using Vala.Time;

namespace Vala.Concurrent {
    /**
     * Function used by {@link recover} to turn a failure into a value.
     *
     * @param message failure reason from the source future.
     * @return recovered value.
     */
    public delegate T RecoverFunc<T> (string message);

    /**
     * Represents the eventual result of an asynchronous computation.
     *
     * Future supports success/failure state tracking, blocking wait,
     * timeout wait, transformation, and failure recovery.
     *
     * Example:
     * {{{
     *     var future = Future<int>.run (() => {
     *         return 40 + 2;
     *     });
     *
     *     int answer = future.orElse (0);
     *     assert (answer == 42);
     * }}}
     */
    public class Future<T>: GLib.Object {
        private GLib.Mutex _mutex;
        private GLib.Cond _cond;

        private bool _done;
        private bool _success;
        private bool _cancelled;
        private string ? _error_message;
        private T ? _value;

        private Future () {
            _done = false;
            _success = false;
            _cancelled = false;
            _error_message = null;
            _value = null;
        }

        /**
         * Starts asynchronous execution on a background thread.
         *
         * @param task computation to execute.
         * @return pending future.
         */
        public static Future<T> run<T> (owned TaskFunc<T> task) {
            var future = new Future<T> ();
            var captured = (owned) task;

            new GLib.Thread<void *> ("future-run", () => {
                T value = captured ();
                future.completeSuccessInternal ((owned) value);
                return null;
            });

            return future;
        }

        /**
         * Creates an already successful future.
         *
         * @param value successful value.
         * @return completed future.
         */
        public static Future<T> completed<T> (owned T value) {
            var future = new Future<T> ();
            future.completeSuccessInternal ((owned) value);
            return future;
        }

        /**
         * Creates an already failed future.
         *
         * @param message failure reason.
         * @return failed future.
         */
        public static Future<T> failed<T> (string message) {
            var future = new Future<T> ();
            future.completeFailureInternal (message);
            return future;
        }

        /**
         * Waits until completion and returns success value.
         *
         * Returns null when this future is failed or cancelled.
         *
         * @return success value or null.
         */
        public T ? @await () {
            _mutex.lock ();
            while (!_done) {
                _cond.wait (_mutex);
            }
            T ? value = _success ? _value : null;
            _mutex.unlock ();
            return value;
        }

        /**
         * Waits for completion up to timeout.
         *
         * Returns null when timed out, failed, or cancelled.
         *
         * @param timeout wait timeout.
         * @return success value, or null.
         */
        public T ? awaitTimeout (Duration timeout) {
            int64 timeout_millis = timeout.toMillis ();
            if (timeout_millis < 0) {
                GLib.error ("timeout must be non-negative");
            }

            int64 deadline = GLib.get_monotonic_time () + timeout_millis * 1000;

            _mutex.lock ();
            while (!_done) {
                if (!_cond.wait_until (_mutex, deadline)) {
                    _mutex.unlock ();
                    return null;
                }
            }
            T ? value = _success ? _value : null;
            _mutex.unlock ();
            return value;
        }

        /**
         * Returns true when this future has completed.
         *
         * @return completion state.
         */
        public bool isDone () {
            _mutex.lock ();
            bool done = _done;
            _mutex.unlock ();
            return done;
        }

        /**
         * Returns true when this future completed successfully.
         *
         * @return success state.
         */
        public bool isSuccess () {
            _mutex.lock ();
            bool success = _done && _success;
            _mutex.unlock ();
            return success;
        }

        /**
         * Returns true when this future failed.
         *
         * Cancelled future is not considered failed.
         *
         * @return failure state.
         */
        public bool isFailed () {
            _mutex.lock ();
            bool failed = _done && !_success && !_cancelled;
            _mutex.unlock ();
            return failed;
        }

        /**
         * Returns failure reason.
         *
         * Returns null for successful future.
         *
         * @return error message or null.
         */
        public string ? error () {
            _mutex.lock ();
            string ? message = (!_done || _success) ? null : _error_message;
            _mutex.unlock ();
            return message;
        }

        /**
         * Transforms the successful value.
         *
         * When source future fails or is cancelled, the returned future
         * keeps that failure state.
         *
         * @param fn transform function.
         * @return transformed future.
         */
        public Future<U> map<U> (owned MapFunc<T, U> fn) {
            var mapped = new Future<U> ();
            var source = this;
            var captured = (owned) fn;

            new GLib.Thread<void *> ("future-map", () => {
                source.@await ();

                if (source.isSuccess ()) {
                    mapped.completeSuccessInternal (captured (source.valueUnsafe ()));
                } else if (source.isCancelled ()) {
                    mapped.completeCancelledInternal ();
                } else {
                    mapped.completeFailureInternal (source.error () ?? "future failed");
                }
                return null;
            });

            return mapped;
        }

        /**
         * Chains another asynchronous computation.
         *
         * @param fn transform function that returns another future.
         * @return chained future.
         */
        public Future<U> flatMap<U> (owned MapFunc<T, Future<U> > fn) {
            var chained = new Future<U> ();
            var source = this;
            var captured = (owned) fn;

            new GLib.Thread<void *> ("future-flatmap", () => {
                source.@await ();

                if (!source.isSuccess ()) {
                    if (source.isCancelled ()) {
                        chained.completeCancelledInternal ();
                    } else {
                        chained.completeFailureInternal (source.error () ?? "future failed");
                    }
                    return null;
                }

                Future<U> ? next = captured (source.valueUnsafe ());
                if (next == null) {
                    chained.completeFailureInternal ("flatMap returned null future");
                    return null;
                }

                next.@await ();
                if (next.isSuccess ()) {
                    chained.completeSuccessInternal (next.valueUnsafe ());
                } else if (next.isCancelled ()) {
                    chained.completeCancelledInternal ();
                } else {
                    chained.completeFailureInternal (next.error () ?? "future failed");
                }
                return null;
            });

            return chained;
        }

        /**
         * Recovers from failure by producing a fallback value.
         *
         * @param fn function that receives failure message.
         * @return recovered future.
         */
        public Future<T> recover (owned RecoverFunc<T> fn) {
            var recovered = new Future<T> ();
            var source = this;
            var captured = (owned) fn;

            new GLib.Thread<void *> ("future-recover", () => {
                source.@await ();

                if (source.isSuccess ()) {
                    recovered.completeSuccessInternal (source.valueUnsafe ());
                    return null;
                }

                if (source.isCancelled ()) {
                    recovered.completeCancelledInternal ();
                    return null;
                }

                string message = source.error () ?? "future failed";
                recovered.completeSuccessInternal (captured (message));
                return null;
            });

            return recovered;
        }

        /**
         * Registers callback invoked when this future completes.
         *
         * Callback receives success value or null when failed/cancelled.
         *
         * @param fn completion callback.
         * @return this future.
         */
        public Future<T> onComplete (owned ConsumerFunc<T ?> fn) {
            var source = this;
            var captured = (owned) fn;

            new GLib.Thread<void *> ("future-on-complete", () => {
                captured (source.@await ());
                return null;
            });

            return this;
        }

        /**
         * Applies timeout to this future and returns timed future.
         *
         * @param timeout timeout duration.
         * @return future that fails with timeout when deadline expires.
         */
        public Future<T> timeout (Duration timeout) {
            int64 timeout_millis = timeout.toMillis ();
            if (timeout_millis < 0) {
                GLib.error ("timeout must be non-negative");
            }

            var wrapped = new Future<T> ();
            var source = this;

            new GLib.Thread<void *> ("future-timeout", () => {
                bool done = source.waitDoneInternal (timeout_millis);
                if (!done) {
                    wrapped.completeFailureInternal ("timeout");
                    return null;
                }

                if (source.isSuccess ()) {
                    wrapped.completeSuccessInternal (source.valueUnsafe ());
                } else if (source.isCancelled ()) {
                    wrapped.completeCancelledInternal ();
                } else {
                    wrapped.completeFailureInternal (source.error () ?? "future failed");
                }
                return null;
            });

            return wrapped;
        }

        /**
         * Returns success value or fallback when failed/cancelled.
         *
         * @param fallback value returned for failed/cancelled state.
         * @return success value or fallback.
         */
        public T orElse (T fallback) {
            T ? value = @await ();
            if (isSuccess () && value != null) {
                return value;
            }
            return fallback;
        }

        /**
         * Requests cancellation.
         *
         * Cancellation does not forcibly stop already running task but
         * marks this future as cancelled if it is still pending.
         *
         * @return true when cancellation state was applied.
         */
        public bool cancel () {
            _mutex.lock ();
            if (_done) {
                _mutex.unlock ();
                return false;
            }

            _done = true;
            _success = false;
            _cancelled = true;
            _error_message = "cancelled";
            _cond.broadcast ();
            _mutex.unlock ();
            return true;
        }

        /**
         * Returns whether this future is cancelled.
         *
         * @return true when cancelled.
         */
        public bool isCancelled () {
            _mutex.lock ();
            bool cancelled = _done && _cancelled;
            _mutex.unlock ();
            return cancelled;
        }

        /**
         * Waits all futures and returns list of success values.
         *
         * If any future fails/cancels, returned future fails.
         *
         * @param futures input futures.
         * @return future of value list.
         */
        public static Future<ArrayList<T> > all<T> (ArrayList<Future<T> > futures) {
            var combined = new Future<ArrayList<T> > ();
            var source = futures;

            new GLib.Thread<void *> ("future-all", () => {
                var values = new ArrayList<T> ();

                for (int i = 0; i < source.size (); i++) {
                    Future<T> ? future = source.get (i);
                    if (future == null) {
                        combined.completeFailureInternal ("future list contains null");
                        return null;
                    }

                    future.@await ();
                    if (!future.isSuccess ()) {
                        if (future.isCancelled ()) {
                            combined.completeCancelledInternal ();
                        } else {
                            combined.completeFailureInternal (future.error () ?? "future failed");
                        }
                        return null;
                    }

                    values.add (future.valueUnsafe ());
                }

                combined.completeSuccessInternal (values);
                return null;
            });

            return combined;
        }

        /**
         * Returns first completed future result.
         *
         * @param futures input futures.
         * @return future completed by the earliest source completion.
         */
        public static Future<T> any<T> (ArrayList<Future<T> > futures) {
            var raced = new Future<T> ();

            if (futures.isEmpty ()) {
                raced.completeFailureInternal ("futures must not be empty");
                return raced;
            }

            for (int i = 0; i < futures.size (); i++) {
                Future<T> ? source = futures.get (i);
                if (source == null) {
                    continue;
                }

                new GLib.Thread<void *> ("future-any", () => {
                    source.@await ();
                    if (source.isSuccess ()) {
                        raced.completeSuccessInternal (source.valueUnsafe ());
                    } else if (source.isCancelled ()) {
                        raced.completeCancelledInternal ();
                    } else {
                        raced.completeFailureInternal (source.error () ?? "future failed");
                    }
                    return null;
                });
            }

            return raced;
        }

        /**
         * Starts task after delay.
         *
         * @param delay delay duration.
         * @param task delayed task.
         * @return future for delayed task result.
         */
        public static Future<T> delayed<T> (Duration delay, owned TaskFunc<T> task) {
            int64 delay_millis = delay.toMillis ();
            if (delay_millis < 0) {
                GLib.error ("delay must be non-negative");
            }

            return Future<T>.run (() => {
                Thread.usleep ((ulong) (delay_millis * 1000));
                return task ();
            });
        }

        /**
         * Waits until all source futures complete and returns them.
         *
         * @param futures input futures.
         * @return future with settled futures list.
         */
        public static Future<ArrayList<Future<T> > > allSettled<T> (ArrayList<Future<T> > futures) {
            var settled = new Future<ArrayList<Future<T> > > ();
            var source = futures;

            new GLib.Thread<void *> ("future-all-settled", () => {
                for (int i = 0; i < source.size (); i++) {
                    Future<T> ? future = source.get (i);
                    if (future != null) {
                        future.@await ();
                    }
                }
                settled.completeSuccessInternal (source);
                return null;
            });

            return settled;
        }

        /**
         * Alias of {@link any}. Returns first completed result.
         *
         * @param futures input futures.
         * @return first completed result future.
         */
        public static Future<T> race<T> (ArrayList<Future<T> > futures) {
            return any<T> (futures);
        }

        private void completeSuccessInternal (owned T ? value) {
            _mutex.lock ();
            if (_done) {
                _mutex.unlock ();
                return;
            }

            _value = (owned) value;
            _success = true;
            _cancelled = false;
            _done = true;
            _error_message = null;
            _cond.broadcast ();
            _mutex.unlock ();
        }

        private void completeFailureInternal (string message) {
            _mutex.lock ();
            if (_done) {
                _mutex.unlock ();
                return;
            }

            _value = null;
            _success = false;
            _cancelled = false;
            _done = true;
            _error_message = message;
            _cond.broadcast ();
            _mutex.unlock ();
        }

        private void completeCancelledInternal () {
            _mutex.lock ();
            if (_done) {
                _mutex.unlock ();
                return;
            }

            _value = null;
            _success = false;
            _cancelled = true;
            _done = true;
            _error_message = "cancelled";
            _cond.broadcast ();
            _mutex.unlock ();
        }

        private bool waitDoneInternal (int64 timeout_millis) {
            int64 deadline = GLib.get_monotonic_time () + timeout_millis * 1000;

            _mutex.lock ();
            while (!_done) {
                if (!_cond.wait_until (_mutex, deadline)) {
                    _mutex.unlock ();
                    return false;
                }
            }
            _mutex.unlock ();
            return true;
        }

        private T valueUnsafe () {
            _mutex.lock ();
            T value = _value;
            _mutex.unlock ();
            return value;
        }
    }
}
