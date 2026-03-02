using Vala.Collections;
using Vala.Concurrent;

namespace Vala.Event {
    /**
     * Recoverable EventBus argument errors.
     */
    public errordomain EventBusError {
        INVALID_ARGUMENT
    }

    /**
     * Event handler receiving a Variant payload.
     */
    public delegate void EventHandler (GLib.Variant eventData);

    internal class EventSubscription : GLib.Object {
        public int id;
        public bool once;
        public EventHandler handler;

        public EventSubscription (int id, bool once, owned EventHandler handler) {
            this.id = id;
            this.once = once;
            this.handler = (owned) handler;
        }
    }

    /**
     * In-process publish/subscribe event bus.
     */
    public class EventBus : GLib.Object {
        private HashMap<string, ArrayList<EventSubscription> > _topics;
        private GLib.Mutex _mutex;
        private int _next_id;
        private bool _async_mode;
        private WorkerPool _pool;

        /**
         * Creates event bus.
         */
        public EventBus () {
            _topics = new HashMap<string, ArrayList<EventSubscription> > (
                GLib.str_hash,
                GLib.str_equal
            );
            _next_id = 1;
            _async_mode = false;
            _pool = WorkerPool.withDefault ();
        }

        ~EventBus () {
            _pool.shutdown ();
        }

        /**
         * Enables asynchronous dispatch mode.
         *
         * @return this bus.
         */
        public EventBus withAsync () {
            _async_mode = true;
            return this;
        }

        /**
         * Subscribes topic with handler.
         *
         * @param topic topic name.
         * @param handler event handler.
         * @return Result.ok(this bus), or
         *         Result.error(EventBusError.INVALID_ARGUMENT) when topic is empty.
         */
        public Result<EventBus, GLib.Error> subscribe (string topic,
                                                       owned EventHandler handler) {
            return addSubscription (topic, false, (owned) handler);
        }

        /**
         * Subscribes topic with one-shot handler.
         *
         * @param topic topic name.
         * @param handler event handler.
         * @return Result.ok(this bus), or
         *         Result.error(EventBusError.INVALID_ARGUMENT) when topic is empty.
         */
        public Result<EventBus, GLib.Error> subscribeOnce (string topic,
                                                           owned EventHandler handler) {
            return addSubscription (topic, true, (owned) handler);
        }

        /**
         * Publishes event to topic.
         *
         * @param topic topic name.
         * @param eventData event payload.
         * @return Result.ok(true) when at least one subscriber receives the event,
         *         Result.ok(false) when no subscribers exist, or
         *         Result.error(EventBusError.INVALID_ARGUMENT) when topic is empty.
         */
        public Result<bool ?, GLib.Error> publish (string topic,
                                                   GLib.Variant eventData) {
            if (topic.length == 0) {
                return Result.error<bool ?, GLib.Error> (
                    new EventBusError.INVALID_ARGUMENT ("topic must not be empty")
                );
            }

            ArrayList<EventSubscription> snapshot = takeSubscriptionsForPublish (topic);
            if (snapshot.size () == 0) {
                return Result.ok<bool ?, GLib.Error> (false);
            }

            for (int i = 0; i < snapshot.size (); i++) {
                EventSubscription ? sub = snapshot.get (i);
                if (sub == null) {
                    continue;
                }

                if (_async_mode) {
                    _pool.execute (() => {
                        sub.handler (eventData);
                    });
                } else {
                    sub.handler (eventData);
                }
            }
            return Result.ok<bool ?, GLib.Error> (true);
        }

        /**
         * Unsubscribes all handlers from topic.
         *
         * @param topic topic name.
         * @return Result.ok(true/false) where value indicates whether any
         *         subscriptions were removed, or
         *         Result.error(EventBusError.INVALID_ARGUMENT) when topic is empty.
         */
        public Result<bool ?, GLib.Error> unsubscribe (string topic) {
            if (topic.length == 0) {
                return Result.error<bool ?, GLib.Error> (
                    new EventBusError.INVALID_ARGUMENT ("topic must not be empty")
                );
            }
            _mutex.lock ();
            bool removed = _topics.remove (topic);
            _mutex.unlock ();
            return Result.ok<bool ?, GLib.Error> (removed);
        }

        /**
         * Returns whether topic has at least one subscriber.
         *
         * @param topic topic name.
         * @return Result.ok(true/false) for subscriber existence, or
         *         Result.error(EventBusError.INVALID_ARGUMENT) when topic is empty.
         */
        public Result<bool ?, GLib.Error> hasSubscribers (string topic) {
            if (topic.length == 0) {
                return Result.error<bool ?, GLib.Error> (
                    new EventBusError.INVALID_ARGUMENT ("topic must not be empty")
                );
            }

            _mutex.lock ();
            ArrayList<EventSubscription> ? list = _topics.get (topic);
            bool has = list != null && list.size () > 0;
            _mutex.unlock ();
            return Result.ok<bool ?, GLib.Error> (has);
        }

        /**
         * Clears all subscriptions.
         */
        public void clear () {
            _mutex.lock ();
            _topics.clear ();
            _mutex.unlock ();
        }

        private Result<EventBus, GLib.Error> addSubscription (string topic,
                                                              bool once,
                                                              owned EventHandler handler) {
            if (topic.length == 0) {
                return Result.error<EventBus, GLib.Error> (
                    new EventBusError.INVALID_ARGUMENT ("topic must not be empty")
                );
            }

            _mutex.lock ();
            ArrayList<EventSubscription> list = getOrCreateTopicList (topic);
            int id = _next_id;
            _next_id++;
            list.add (new EventSubscription (id, once, (owned) handler));
            _mutex.unlock ();
            return Result.ok<EventBus, GLib.Error> (this);
        }

        private ArrayList<EventSubscription> takeSubscriptionsForPublish (string topic) {
            var snapshot = new ArrayList<EventSubscription> ();

            _mutex.lock ();
            ArrayList<EventSubscription> ? list = _topics.get (topic);
            if (list != null) {
                var kept = new ArrayList<EventSubscription> ();
                for (int i = 0; i < list.size (); i++) {
                    EventSubscription ? sub = list.get (i);
                    if (sub != null) {
                        snapshot.add (sub);
                        if (!sub.once) {
                            kept.add (sub);
                        }
                    }
                }

                if (kept.size () == 0) {
                    _topics.remove (topic);
                } else {
                    _topics.put (topic, kept);
                }
            }
            _mutex.unlock ();
            return snapshot;
        }

        private ArrayList<EventSubscription> getOrCreateTopicList (string topic) {
            ArrayList<EventSubscription> ? list = _topics.get (topic);
            if (list == null) {
                list = new ArrayList<EventSubscription> ();
                _topics.put (topic, list);
            }
            return list;
        }
    }
}
