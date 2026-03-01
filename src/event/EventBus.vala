using Vala.Collections;

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

            ArrayList<EventSubscription> snapshot = copySubscriptions (topic);
            if (snapshot.size () == 0) {
                return;
            }

            var once_ids = new ArrayList<int> ();
            for (int i = 0; i < snapshot.size (); i++) {
                EventSubscription ? sub = snapshot.get (i);
                if (sub == null) {
                    continue;
                }

                if (_async_mode) {
                    new GLib.Thread<void *> ("event-bus-handler", () => {
                        sub.handler (eventData);
                        return null;
                    });
                } else {
                    sub.handler (eventData);
                }

                if (sub.once) {
                    once_ids.add (sub.id);
                }
            }

            if (once_ids.size () > 0) {
                removeSubscriptionsById (topic, once_ids);
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

        private ArrayList<EventSubscription> copySubscriptions (string topic) {
            var copy = new ArrayList<EventSubscription> ();

            _mutex.lock ();
            ArrayList<EventSubscription> ? list = _topics.get (topic);
            if (list != null) {
                for (int i = 0; i < list.size (); i++) {
                    EventSubscription ? sub = list.get (i);
                    if (sub != null) {
                        copy.add (sub);
                    }
                }
            }
            _mutex.unlock ();
            return copy;
        }

        private void removeSubscriptionsById (string topic, ArrayList<int> ids) {
            _mutex.lock ();
            ArrayList<EventSubscription> ? list = _topics.get (topic);
            if (list == null) {
                _mutex.unlock ();
                return;
            }

            for (int i = (int) list.size () - 1; i >= 0; i--) {
                EventSubscription ? sub = list.get (i);
                if (sub == null) {
                    continue;
                }
                if (containsId (ids, sub.id)) {
                    list.removeAt (i);
                }
            }

            if (list.size () == 0) {
                _topics.remove (topic);
            }
            _mutex.unlock ();
        }

        private static bool containsId (ArrayList<int> ids, int id) {
            for (int i = 0; i < ids.size (); i++) {
                int ? v = ids.get (i);
                if (v != null && v == id) {
                    return true;
                }
            }
            return false;
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
