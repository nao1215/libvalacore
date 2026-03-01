namespace Vala.Distributed {
    /**
     * Recoverable Snowflake generator errors.
     */
    public errordomain SnowflakeError {
        INVALID_ARGUMENT,
        CLOCK_BEFORE_EPOCH,
        TIMESTAMP_OVERFLOW
    }

    /**
     * Parsed Snowflake ID components.
     */
    public class SnowflakeParts : GLib.Object {
        private int64 _timestamp_millis;
        private int _node_id;
        private int _sequence;

        public SnowflakeParts (int64 timestamp_millis, int node_id, int sequence) {
            _timestamp_millis = timestamp_millis;
            _node_id = node_id;
            _sequence = sequence;
        }

        /**
         * Returns ID timestamp in milliseconds.
         *
         * @return timestamp in milliseconds.
         */
        public int64 timestampMillis () {
            return _timestamp_millis;
        }

        /**
         * Returns node ID component.
         *
         * @return node ID.
         */
        public int nodeId () {
            return _node_id;
        }

        /**
         * Returns sequence component.
         *
         * @return sequence number.
         */
        public int sequence () {
            return _sequence;
        }
    }

    /**
     * 64-bit Snowflake ID generator.
     *
     * ID format:
     * - 41 bits: timestamp (milliseconds since custom epoch)
     * - 10 bits: node ID
     * - 12 bits: sequence within same millisecond
     */
    public class Snowflake : GLib.Object {
        private const int NODE_BITS = 10;
        private const int SEQUENCE_BITS = 12;
        private const int64 MAX_NODE_ID = (1L << NODE_BITS) - 1L;
        private const int64 SEQUENCE_MASK = (1L << SEQUENCE_BITS) - 1L;
        private const int64 NODE_MASK = (1L << NODE_BITS) - 1L;
        private const int64 TIMESTAMP_MASK = (1L << 41) - 1L;
        private const int64 DEFAULT_EPOCH_MILLIS = 1577836800000L; // 2020-01-01T00:00:00Z

        private GLib.Mutex _mutex;
        private int _node_id;
        private int64 _epoch_millis;
        private int64 _last_timestamp_millis;
        private int64 _sequence;

        /**
         * Creates a generator with node ID.
         *
         * @param nodeId node ID in [0, 1023].
         * @throws SnowflakeError.INVALID_ARGUMENT when nodeId is out of range.
         */
        public Snowflake (int nodeId) throws SnowflakeError {
            if (nodeId < 0 || nodeId > MAX_NODE_ID) {
                throw new SnowflakeError.INVALID_ARGUMENT (
                          "nodeId must be in range [0, %s]".printf (MAX_NODE_ID.to_string ())
                );
            }

            _node_id = nodeId;
            _epoch_millis = DEFAULT_EPOCH_MILLIS;
            _last_timestamp_millis = -1L;
            _sequence = 0L;
        }

        /**
         * Sets custom epoch.
         *
         * @param epoch custom epoch.
         * @return this generator for chaining.
         */
        public Snowflake withEpoch (Vala.Time.DateTime epoch) {
            _epoch_millis = epoch.toUnixTimestamp () * 1000L;
            return this;
        }

        /**
         * Generates next Snowflake ID.
         *
         * @return next unique ID.
         * @throws SnowflakeError.CLOCK_BEFORE_EPOCH when current clock is before configured epoch.
         * @throws SnowflakeError.TIMESTAMP_OVERFLOW when 41-bit timestamp capacity is exceeded.
         */
        public int64 nextId () throws SnowflakeError {
            _mutex.lock ();

            int64 now = currentTimeMillis ();
            if (now < _last_timestamp_millis) {
                now = _last_timestamp_millis;
            }

            if (now == _last_timestamp_millis) {
                _sequence = (_sequence + 1L) & SEQUENCE_MASK;
                if (_sequence == 0L) {
                    now = waitUntilNextMillis (_last_timestamp_millis);
                }
            } else {
                _sequence = 0L;
            }

            int64 elapsed = now - _epoch_millis;
            if (elapsed < 0L) {
                _mutex.unlock ();
                throw new SnowflakeError.CLOCK_BEFORE_EPOCH ("current time is before configured epoch");
            }
            if (elapsed > TIMESTAMP_MASK) {
                _mutex.unlock ();
                throw new SnowflakeError.TIMESTAMP_OVERFLOW ("snowflake timestamp overflow");
            }

            _last_timestamp_millis = now;

            int64 id = (elapsed << (NODE_BITS + SEQUENCE_BITS)) |
                       (((int64) _node_id & NODE_MASK) << SEQUENCE_BITS) |
                       _sequence;
            _mutex.unlock ();
            return id;
        }

        /**
         * Generates next Snowflake ID as string.
         *
         * @return next unique ID string.
         * @throws SnowflakeError when nextId fails.
         */
        public string nextString () throws SnowflakeError {
            return nextId ().to_string ();
        }

        /**
         * Parses Snowflake ID into components.
         *
         * @param id snowflake ID.
         * @return parsed components.
         */
        public SnowflakeParts parse (int64 id) {
            return new SnowflakeParts (
                timestampMillis (id),
                nodeIdOf (id),
                sequenceOf (id)
            );
        }

        /**
         * Extracts timestamp component in milliseconds.
         *
         * @param id snowflake ID.
         * @return timestamp in milliseconds.
         */
        public int64 timestampMillis (int64 id) {
            int64 elapsed = (id >> (NODE_BITS + SEQUENCE_BITS)) & TIMESTAMP_MASK;
            return elapsed + _epoch_millis;
        }

        /**
         * Extracts node ID component.
         *
         * @param id snowflake ID.
         * @return node ID.
         */
        public int nodeIdOf (int64 id) {
            return (int) ((id >> SEQUENCE_BITS) & NODE_MASK);
        }

        /**
         * Extracts sequence component.
         *
         * @param id snowflake ID.
         * @return sequence number.
         */
        public int sequenceOf (int64 id) {
            return (int) (id & SEQUENCE_MASK);
        }

        private static int64 currentTimeMillis () {
            return GLib.get_real_time () / 1000L;
        }

        private static int64 waitUntilNextMillis (int64 lastTimestampMillis) {
            int64 now = currentTimeMillis ();
            while (now <= lastTimestampMillis) {
                Posix.usleep (100);
                now = currentTimeMillis ();
            }
            return now;
        }
    }
}
