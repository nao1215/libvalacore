using Vala.Time;

namespace Vala.Collections {
    /**
     * Recoverable LRU cache operation errors.
     */
    public errordomain LruCacheError {
        INVALID_ARGUMENT
    }

    /**
     * Loader function for cache misses.
     */
    public delegate V ? CacheLoaderFunc<K, V> (K key);

    private class LruNode<K, V>: GLib.Object {
        public K key;
        public V value;
        public int64 touched_at_millis;
        public LruNode<K, V> ? prev = null;
        public LruNode<K, V> ? next = null;

        public LruNode (owned K key, owned V value, int64 touched_at_millis) {
            this.key = (owned) key;
            this.value = (owned) value;
            this.touched_at_millis = touched_at_millis;
        }
    }

    /**
     * LRU cache with optional TTL and cache-miss loader.
     */
    public class LruCache<K, V>: GLib.Object {
        private int _max_entries;
        private int64 _ttl_millis = 0;
        private CacheLoaderFunc<K, V> ? _loader = null;

        private int _hits = 0;
        private int _misses = 0;

        private GLib.HashTable<K, LruNode<K, V> > _entries;
        private LruNode<K, V> ? _head = null;
        private LruNode<K, V> ? _tail = null;

        /**
         * Creates an LRU cache.
         *
         * @param max_entries maximum number of entries.
         * @param hash_func hash function for key.
         * @param equal_func equality function for key.
         * @throws LruCacheError.INVALID_ARGUMENT when max_entries is not positive.
         */
        public LruCache (int max_entries,
                         GLib.HashFunc<K> hash_func,
                         GLib.EqualFunc<K> equal_func) throws LruCacheError {
            if (max_entries <= 0) {
                throw new LruCacheError.INVALID_ARGUMENT ("max_entries must be greater than 0");
            }

            _max_entries = max_entries;
            _entries = new GLib.HashTable<K, LruNode<K, V> > (hash_func, equal_func);
        }

        /**
         * Sets entry TTL.
         *
         * @param ttl entry TTL duration.
         * @return this cache instance.
         * @throws LruCacheError.INVALID_ARGUMENT when ttl is negative.
         */
        public LruCache<K, V> withTtl (Duration ttl) throws LruCacheError {
            if (ttl.toMillis () < 0) {
                throw new LruCacheError.INVALID_ARGUMENT ("ttl must be non-negative");
            }
            _ttl_millis = ttl.toMillis ();
            return this;
        }

        /**
         * Sets cache-miss loader.
         *
         * @param loader loader callback.
         * @return this cache instance.
         */
        public LruCache<K, V> withLoader (owned CacheLoaderFunc<K, V> loader) {
            _loader = (owned) loader;
            return this;
        }

        /**
         * Returns value for key.
         *
         * Moves hit entry to MRU position. Expired entries are removed.
         *
         * @param key cache key.
         * @return cached or loaded value, or null.
         */
        public new V ? get (K key) {
            LruNode<K, V> ? node = _entries.lookup (key);
            if (node != null) {
                if (isExpired (node)) {
                    removeNode (node);
                    _entries.remove (key);
                } else {
                    node.touched_at_millis = now_millis ();
                    moveToFront (node);
                    _hits++;
                    return node.value;
                }
            }

            _misses++;
            if (_loader == null) {
                return null;
            }

            V ? loaded = _loader (key);
            if (loaded == null) {
                return null;
            }
            put (key, loaded);
            return loaded;
        }

        /**
         * Inserts or replaces cache entry.
         *
         * @param key cache key.
         * @param value cache value.
         */
        public void put (K key, V value) {
            LruNode<K, V> ? node = _entries.lookup (key);
            if (node != null) {
                node.value = value;
                node.touched_at_millis = now_millis ();
                moveToFront (node);
                return;
            }

            var created = new LruNode<K, V> (key, value, now_millis ());
            addToFront (created);
            _entries.replace (key, created);
            evictIfNeeded ();
        }

        /**
         * Returns whether key exists and is not expired.
         *
         * @param key cache key.
         * @return true if key exists.
         */
        public bool contains (K key) {
            LruNode<K, V> ? node = _entries.lookup (key);
            if (node == null) {
                return false;
            }
            if (isExpired (node)) {
                removeNode (node);
                _entries.remove (key);
                return false;
            }
            return true;
        }

        /**
         * Removes entry by key.
         *
         * @param key cache key.
         * @return true if key existed and was removed.
         */
        public bool remove (K key) {
            LruNode<K, V> ? node = _entries.lookup (key);
            if (node == null) {
                return false;
            }

            removeNode (node);
            return _entries.remove (key);
        }

        /**
         * Clears all entries.
         */
        public void clear () {
            _entries.remove_all ();
            _head = null;
            _tail = null;
        }

        /**
         * Returns number of current entries.
         *
         * @return entry count.
         */
        public uint size () {
            return _entries.size ();
        }

        /**
         * Returns cache statistics (hits, misses).
         *
         * @return pair where first=hits, second=misses.
         */
        public Pair<int, int> stats () {
            return new Pair<int, int> (_hits, _misses);
        }

        private bool isExpired (LruNode<K, V> node) {
            if (_ttl_millis <= 0) {
                return false;
            }
            return now_millis () - node.touched_at_millis > _ttl_millis;
        }

        private static int64 now_millis () {
            return GLib.get_monotonic_time () / 1000;
        }

        private void moveToFront (LruNode<K, V> node) {
            if (node == _head) {
                return;
            }
            removeNode (node);
            addToFront (node);
        }

        private void addToFront (LruNode<K, V> node) {
            node.prev = null;
            node.next = _head;
            if (_head != null) {
                _head.prev = node;
            }
            _head = node;
            if (_tail == null) {
                _tail = node;
            }
        }

        private void removeNode (LruNode<K, V> node) {
            if (node.prev != null) {
                node.prev.next = node.next;
            } else {
                _head = node.next;
            }

            if (node.next != null) {
                node.next.prev = node.prev;
            } else {
                _tail = node.prev;
            }

            node.prev = null;
            node.next = null;
        }

        private void evictIfNeeded () {
            while (_entries.size () > _max_entries) {
                if (_tail == null) {
                    return;
                }

                K tail_key = _tail.key;
                LruNode<K, V> victim = _tail;
                removeNode (victim);
                _entries.remove (tail_key);
            }
        }
    }
}
