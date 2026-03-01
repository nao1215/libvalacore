using Vala.Collections;
using Vala.Concurrent;
using Vala.Time;

namespace Vala.Lang {
    /**
     * Cancellation and timeout context propagated across call boundaries.
     *
     * Context is inspired by Go's context package and is intended to pass
     * cancellation signal, deadline, and request-scoped values.
     */
    public class Context : GLib.Object {
        private Context ? _parent;
        private ChannelInt _done;
        private HashMap<string, string> _local_values;

        private GLib.Mutex _mutex;
        private bool _cancelled;
        private string ? _error_message;
        private int64 _deadline_mono_usec;

        private Context (Context ? parent, int64 deadline_mono_usec = -1) {
            _parent = parent;
            _deadline_mono_usec = deadline_mono_usec;
            _done = ChannelInt.buffered (1);
            _local_values = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            _cancelled = false;
            _error_message = null;

            inheritParentCancellation ();
            startDeadlineWatcherIfNeeded ();
        }

        /**
         * Returns root context that is never cancelled by parent.
         *
         * @return background context.
         */
        public static Context background () {
            return new Context (null, -1);
        }

        /**
         * Creates child context that can be cancelled explicitly.
         *
         * @param parent parent context.
         * @return cancellable child context.
         */
        public static Context withCancel (Context parent) {
            ensureParent (parent);
            return new Context (parent, parent._deadline_mono_usec);
        }

        /**
         * Creates child context cancelled on timeout.
         *
         * @param parent parent context.
         * @param timeout timeout duration.
         * @return timeout child context.
         */
        public static Context withTimeout (Context parent, Duration timeout) {
            ensureParent (parent);

            int64 timeout_millis = timeout.toMillis ();
            if (timeout_millis < 0) {
                GLib.error ("timeout must be non-negative");
            }

            int64 deadline = GLib.get_monotonic_time () + timeout_millis * 1000;
            if (parent._deadline_mono_usec >= 0 && parent._deadline_mono_usec < deadline) {
                deadline = parent._deadline_mono_usec;
            }

            return new Context (parent, deadline);
        }

        /**
         * Creates child context with absolute deadline.
         *
         * @param parent parent context.
         * @param deadline absolute deadline.
         * @return deadline child context.
         */
        public static Context withDeadline (Context parent, Vala.Time.DateTime deadline) {
            ensureParent (parent);

            int64 now_unix = Vala.Time.DateTime.now ().toUnixTimestamp ();
            int64 deadline_unix = deadline.toUnixTimestamp ();
            int64 diff_seconds = deadline_unix - now_unix;
            int64 timeout_millis = diff_seconds * 1000;

            if (timeout_millis <= 0) {
                var expired = new Context (parent, GLib.get_monotonic_time ());
                expired.cancelWithReason ("timeout");
                return expired;
            }

            return withTimeout (parent, Duration.ofSeconds (diff_seconds));
        }

        /**
         * Cancels this context.
         */
        public void cancel () {
            cancelWithReason ("cancelled");
        }

        /**
         * Returns whether this context is cancelled.
         *
         * @return true when cancelled.
         */
        public bool isCancelled () {
            _mutex.lock ();
            bool cancelled = _cancelled;
            _mutex.unlock ();
            return cancelled;
        }

        /**
         * Returns cancellation reason.
         *
         * @return reason string or null.
         */
        public string ? error () {
            _mutex.lock ();
            string ? reason = _error_message;
            _mutex.unlock ();
            return reason;
        }

        /**
         * Returns remaining time until deadline.
         *
         * Returns null when this context has no deadline.
         *
         * @return remaining duration or null.
         */
        public Duration ? remaining () {
            _mutex.lock ();
            int64 deadline = _deadline_mono_usec;
            _mutex.unlock ();

            if (deadline < 0) {
                return null;
            }

            int64 now = GLib.get_monotonic_time ();
            int64 remaining_millis = (deadline - now) / 1000;
            if (remaining_millis <= 0) {
                return Duration.ofSeconds (0);
            }

            int64 remaining_seconds = remaining_millis / 1000;
            if ((remaining_millis % 1000) != 0) {
                remaining_seconds++;
            }
            return Duration.ofSeconds (remaining_seconds);
        }

        /**
         * Returns done notification channel.
         *
         * The channel emits one value and closes when context is cancelled.
         *
         * @return done channel.
         */
        public ChannelInt done () {
            return _done;
        }

        /**
         * Returns value for key from this context chain.
         *
         * @param key lookup key.
         * @return value or null.
         */
        public string ? value (string key) {
            if (key.length == 0) {
                GLib.error ("key must not be empty");
            }

            string ? v = _local_values.get (key);
            if (v != null) {
                return v;
            }

            if (_parent == null) {
                return null;
            }
            return _parent.value (key);
        }

        /**
         * Creates child context with additional key/value.
         *
         * @param key key string.
         * @param value value string.
         * @return child context containing key/value.
         */
        public Context withValue (string key, string value) {
            if (key.length == 0) {
                GLib.error ("key must not be empty");
            }

            var child = new Context (this, _deadline_mono_usec);
            child._local_values.put (key, value);
            return child;
        }

        private static void ensureParent (Context ? parent) {
            if (parent == null) {
                GLib.error ("parent context must not be null");
            }
        }

        private void inheritParentCancellation () {
            if (_parent == null) {
                return;
            }

            if (_parent.isCancelled ()) {
                cancelWithReason (_parent.error () ?? "cancelled");
                return;
            }

            new GLib.Thread<void *> ("context-parent-watch", () => {
                _parent.done ().receive ();
                if (_parent.isCancelled ()) {
                    cancelWithReason (_parent.error () ?? "cancelled");
                }
                return null;
            });
        }

        private void startDeadlineWatcherIfNeeded () {
            if (_deadline_mono_usec < 0) {
                return;
            }

            int64 delay_usec = _deadline_mono_usec - GLib.get_monotonic_time ();
            if (delay_usec <= 0) {
                cancelWithReason ("timeout");
                return;
            }

            new GLib.Thread<void *> ("context-timeout-watch", () => {
                Thread.usleep ((ulong) delay_usec);
                cancelWithReason ("timeout");
                return null;
            });
        }

        private void cancelWithReason (string reason) {
            _mutex.lock ();
            if (_cancelled) {
                _mutex.unlock ();
                return;
            }

            _cancelled = true;
            _error_message = reason;
            _mutex.unlock ();

            _done.trySend (1);
            _done.close ();
        }
    }
}
