namespace Vala.Collections {
    /**
     * Probabilistic membership filter with no false negatives.
     */
    public class BloomFilter<T>: GLib.Object {
        private int _bit_size;
        private int _hash_count;
        private int64 _inserted_count;
        private double _target_false_positive_rate;
        private uint8[] _bits;

        /**
         * Creates BloomFilter from expected insertions and false-positive rate.
         *
         * @param expectedInsertions expected number of inserted items.
         * @param falsePositiveRate target false-positive rate in range (0, 1).
         */
        public BloomFilter (int expectedInsertions, double falsePositiveRate) {
            if (expectedInsertions <= 0) {
                GLib.error ("expectedInsertions must be positive");
            }
            if (falsePositiveRate <= 0.0 || falsePositiveRate >= 1.0) {
                GLib.error ("falsePositiveRate must be in range (0, 1)");
            }

            _target_false_positive_rate = falsePositiveRate;

            double ln2 = GLib.Math.log (2.0);
            double expected = (double) expectedInsertions;
            double numerator = -1.0 * expected * GLib.Math.log (falsePositiveRate);
            _bit_size = (int) GLib.Math.ceil (
                numerator / (ln2 * ln2)
            );
            _hash_count = (int) GLib.Math.round (((double) _bit_size / (double) expectedInsertions) * ln2);
            if (_hash_count < 1) {
                _hash_count = 1;
            }

            _inserted_count = 0;
            _bits = new uint8[(_bit_size + 7) / 8];
        }

        private BloomFilter.withParams (int bitSize,
                                        int hashCount,
                                        int64 insertedCount,
                                        double falsePositiveRate) {
            _bit_size = bitSize;
            _hash_count = hashCount;
            _inserted_count = insertedCount;
            _target_false_positive_rate = falsePositiveRate;
            _bits = new uint8[(_bit_size + 7) / 8];
        }

        /**
         * Adds one item to filter.
         *
         * @param item item to add.
         */
        public void add (T item) {
            string text = _value_to_string<T> (item);
            uint64 h1 = hash64FromHex (GLib.Checksum.compute_for_string (
                                           GLib.ChecksumType.SHA256,
                                           "1|" + text
            ));
            uint64 h2 = hash64FromHex (GLib.Checksum.compute_for_string (
                                           GLib.ChecksumType.SHA256,
                                           "2|" + text
            ));
            if (h2 == 0UL) {
                h2 = 0x9e3779b97f4a7c15UL;
            }

            for (int i = 0; i < _hash_count; i++) {
                uint64 combined = h1 + (uint64) i * h2;
                int index = (int) (combined % (uint64) _bit_size);
                setBit (index);
            }
            _inserted_count++;
        }

        /**
         * Adds multiple items.
         *
         * @param items input items.
         */
        public void addAll (ArrayList<T> items) {
            for (int i = 0; i < items.size (); i++) {
                T ? item = items.get (i);
                if (item != null) {
                    add (item);
                }
            }
        }

        /**
         * Returns whether item might be contained in filter.
         *
         * @param item item to check.
         * @return false means definitely not present.
         */
        public bool mightContain (T item) {
            string text = _value_to_string<T> (item);
            uint64 h1 = hash64FromHex (GLib.Checksum.compute_for_string (
                                           GLib.ChecksumType.SHA256,
                                           "1|" + text
            ));
            uint64 h2 = hash64FromHex (GLib.Checksum.compute_for_string (
                                           GLib.ChecksumType.SHA256,
                                           "2|" + text
            ));
            if (h2 == 0UL) {
                h2 = 0x9e3779b97f4a7c15UL;
            }

            for (int i = 0; i < _hash_count; i++) {
                uint64 combined = h1 + (uint64) i * h2;
                int index = (int) (combined % (uint64) _bit_size);
                if (!getBit (index)) {
                    return false;
                }
            }
            return true;
        }

        /**
         * Clears all bits.
         */
        public void clear () {
            for (int i = 0; i < _bits.length; i++) {
                _bits[i] = 0;
            }
            _inserted_count = 0;
        }

        /**
         * Returns total bit size.
         *
         * @return bit size.
         */
        public int bitSize () {
            return _bit_size;
        }

        /**
         * Returns number of hash functions.
         *
         * @return hash count.
         */
        public int hashCount () {
            return _hash_count;
        }

        /**
         * Returns estimated false-positive rate.
         *
         * @return estimated false-positive rate.
         */
        public double estimatedFalsePositiveRate () {
            if (_inserted_count <= 0) {
                return 0.0;
            }
            double exponent = (-1.0 * (double) _hash_count * (double) _inserted_count) /
                              (double) _bit_size;
            return GLib.Math.pow (1.0 - GLib.Math.exp (exponent), (double) _hash_count);
        }

        /**
         * Merges another filter into this filter.
         *
         * @param other filter with same parameters.
         * @return true if merged, false when parameters mismatch.
         */
        public bool merge (BloomFilter<T> other) {
            if (other._bit_size != _bit_size || other._hash_count != _hash_count) {
                return false;
            }

            for (int i = 0; i < _bits.length; i++) {
                _bits[i] |= other._bits[i];
            }
            _inserted_count = estimateInsertionsFromBits ();
            return true;
        }

        /**
         * Serializes filter to bytes.
         *
         * @return serialized bytes.
         */
        public uint8[] toBytes () {
            uint8[] bytesOut = new uint8[16 + _bits.length];

            writeInt32 (bytesOut, 0, _bit_size);
            writeInt32 (bytesOut, 4, _hash_count);
            writeInt64 (bytesOut, 8, _inserted_count);
            for (int i = 0; i < _bits.length; i++) {
                bytesOut[16 + i] = _bits[i];
            }

            return bytesOut;
        }

        /**
         * Restores filter from serialized bytes.
         *
         * @param bytes serialized bytes.
         * @return restored filter or null when invalid.
         */
        public BloomFilter<T> ? fromBytes (uint8[] bytes) {
            if (bytes.length < 17) {
                return null;
            }

            int bitSize = readInt32 (bytes, 0);
            int hashCount = readInt32 (bytes, 4);
            int64 insertedCount = readInt64 (bytes, 8);
            if (bitSize <= 0 || hashCount <= 0 || insertedCount < 0) {
                return null;
            }

            int byteSize = (bitSize + 7) / 8;
            if (bytes.length != 16 + byteSize) {
                return null;
            }

            var filter = new BloomFilter<T>.withParams (bitSize, hashCount, insertedCount, 0.0);

            for (int i = 0; i < byteSize; i++) {
                filter._bits[i] = bytes[16 + i];
            }
            return filter;
        }

        private void setBit (int index) {
            _bits[index / 8] |= (uint8) (1 << (index % 8));
        }

        private bool getBit (int index) {
            return (_bits[index / 8] & (uint8) (1 << (index % 8))) != 0;
        }

        private int64 estimateInsertionsFromBits () {
            int setBits = 0;
            for (int i = 0; i < _bits.length; i++) {
                uint8 b = _bits[i];
                while (b != 0) {
                    setBits += (int) (b & 1);
                    b >>= 1;
                }
            }

            if (setBits == 0) {
                return 0;
            }
            double ratio = 1.0 - ((double) setBits / (double) _bit_size);
            if (ratio <= 0.0) {
                return _inserted_count;
            }
            double estimate = (-1.0 * ((double) _bit_size / (double) _hash_count)) * GLib.Math.log (ratio);
            if (estimate < 0.0) {
                return 0;
            }
            return (int64) GLib.Math.round (estimate);
        }

        private static void writeInt32 (uint8[] bytesOut, int offset, int value) {
            bytesOut[offset] = (uint8) (value & 0xFF);
            bytesOut[offset + 1] = (uint8) ((value >> 8) & 0xFF);
            bytesOut[offset + 2] = (uint8) ((value >> 16) & 0xFF);
            bytesOut[offset + 3] = (uint8) ((value >> 24) & 0xFF);
        }

        private static void writeInt64 (uint8[] bytesOut, int offset, int64 value) {
            for (int i = 0; i < 8; i++) {
                bytesOut[offset + i] = (uint8) ((value >> (8 * i)) & 0xFF);
            }
        }

        private static int readInt32 (uint8[] data, int offset) {
            return (int) data[offset] |
                   ((int) data[offset + 1] << 8) |
                   ((int) data[offset + 2] << 16) |
                   ((int) data[offset + 3] << 24);
        }

        private static int64 readInt64 (uint8[] data, int offset) {
            int64 value = 0;
            for (int i = 0; i < 8; i++) {
                value |= ((int64) data[offset + i]) << (8 * i);
            }
            return value;
        }

        private static uint64 hash64FromHex (string hex) {
            uint64 out = 0UL;
            int limit = int.min (16, hex.length);
            for (int i = 0; i < limit; i++) {
                unichar c = hex.get_char (i);
                out = (out << 4) | nibbleFromHex (c);
            }
            return out;
        }

        private static uint64 nibbleFromHex (unichar c) {
            if (c >= '0' && c <= '9') {
                return (uint64) (c - '0');
            }
            if (c >= 'a' && c <= 'f') {
                return (uint64) (c - 'a' + 10);
            }
            if (c >= 'A' && c <= 'F') {
                return (uint64) (c - 'A' + 10);
            }
            return 0UL;
        }
    }
}
