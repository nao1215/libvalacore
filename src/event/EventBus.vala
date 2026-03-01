using Vala.Collections;
using Vala.Concurrent;

namespace Vala.Event {
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
         * @return this bus.
         */
        public EventBus subscribe (string topic, owned EventHandler handler) {
            return addSubscription (topic, false, (owned) handler);
        }

        /**
         * Subscribes topic with one-shot handler.
         *
         * @param topic topic name.
         * @param handler event handler.
         * @return this bus.
         */
        public EventBus subscribeOnce (string topic, owned EventHandler handler) {
            return addSubscription (topic, true, (owned) handler);
        }

        /**
         * Publishes event to topic.
         *
         * @param topic topic name.
         * @param eventData event payload.
         */
        public void publish (string topic, GLib.Variant eventData) {
            ensureTopic (topic);

            ArrayList<EventSubscription> snapshot = takeSubscriptionsForPublish (topic);
            if (snapshot.size () == 0) {
                return;
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
        }

        /**
         * Unsubscribes all handlers from topic.
         *
         * @param topic topic name.
         */
        public void unsubscribe (string topic) {
            ensureTopic (topic);
            _mutex.lock ();
            _topics.remove (topic);
            _mutex.unlock ();
        }

        /**
         * Returns whether topic has at least one subscriber.
         *
         * @param topic topic name.
         * @return true if topic has subscribers.
         */
        public bool hasSubscribers (string topic) {
            ensureTopic (topic);

            _mutex.lock ();
            ArrayList<EventSubscription> ? list = _topics.get (topic);
            bool has = list != null && list.size () > 0;
            _mutex.unlock ();
            return has;
        }

        /**
         * Clears all subscriptions.
         */
        public void clear () {
            _mutex.lock ();
            _topics.clear ();
            _mutex.unlock ();
        }

        private EventBus addSubscription (string topic,
                                          bool once,
                                          owned EventHandler handler) {
            ensureTopic (topic);

            _mutex.lock ();
            ArrayList<EventSubscription> list = getOrCreateTopicList (topic);
            int id = _next_id;
            _next_id++;
            list.add (new EventSubscription (id, once, (owned) handler));
            _mutex.unlock ();
            return this;
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

        private static void ensureTopic (string topic) {
            if (topic.length == 0) {
                GLib.error ("topic must not be empty");
            }
        }
    }
}
