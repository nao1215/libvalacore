namespace Vala.Collections {
    /**
     * HyperLogLog cardinality estimator.
     *
     * HyperLogLog estimates unique count with fixed memory usage.
     * It is suitable for large-scale log and metric aggregation.
     */
    public class HyperLogLog : GLib.Object {
        private const int MIN_PRECISION = 4;
        private const int MAX_PRECISION = 16;

        private int _precision;
        private uint8[] _registers;
        private double _actual_error_rate;

        /**
         * Creates HyperLogLog with target error rate.
         *
         * @param errorRate target relative error rate.
         */
        public HyperLogLog (double errorRate = 0.01) {
            if (errorRate <= 0.0 || errorRate >= 1.0) {
                GLib.error ("errorRate must be in range (0, 1)");
            }

            _precision = precisionForErrorRate (errorRate);
            _registers = new uint8[1 << _precision];
            _actual_error_rate = 1.04 / GLib.Math.sqrt ((double) _registers.length);
        }

        private HyperLogLog.withPrecision (int precision) {
            _precision = precision;
            _registers = new uint8[1 << _precision];
            _actual_error_rate = 1.04 / GLib.Math.sqrt ((double) _registers.length);
        }

        /**
         * Adds value to estimator.
         *
         * @param value input value.
         */
        public void add (string value) {
            addHashed (hash64FromHex (
                           GLib.Checksum.compute_for_string (GLib.ChecksumType.SHA256, value)
            ));
        }

        /**
         * Adds raw bytes to estimator.
         *
         * @param value input bytes.
         */
        public void addBytes (uint8[] value) {
            addHashed (hash64FromHex (
                           GLib.Checksum.compute_for_data (GLib.ChecksumType.SHA256, value)
            ));
        }

        /**
         * Adds multiple values.
         *
         * @param values input values.
         */
        public void addAll (ArrayList<string> values) {
            for (int i = 0; i < values.size (); i++) {
                string ? value = values.get (i);
                if (value == null) {
                    continue;
                }
                add (value);
            }
        }

        /**
         * Returns estimated unique count.
         *
         * @return estimated cardinality.
         */
        public int64 count () {
            int m = _registers.length;
            double alpha = alphaForRegisterCount (m);

            double harmonic = 0.0;
            int zeroCount = 0;
            for (int i = 0; i < m; i++) {
                uint8 register = _registers[i];
                if (register == 0) {
                    zeroCount++;
                }
                double exponent = -1.0 * (double) register;
                harmonic += GLib.Math.pow (2.0, exponent);
            }

            double raw = alpha * (double) m * (double) m / harmonic;

            // Small-range correction using linear counting.
            if (raw <= 2.5 * (double) m && zeroCount > 0) {
                raw = (double) m * GLib.Math.log ((double) m / (double) zeroCount);
            }

            // Large-range correction (64-bit variant).
            double two64 = 18446744073709551616.0;
            if (raw > two64 / 30.0) {
                raw = -two64 * GLib.Math.log (1.0 - (raw / two64));
            }

            if (raw < 0.0) {
                return 0;
            }
            return (int64) GLib.Math.round (raw);
        }

        /**
         * Merges another HyperLogLog into this instance.
         *
         * @param other other HyperLogLog.
         * @return true if merged, false when precisions mismatch.
         */
        public bool merge (HyperLogLog other) {
            if (other._precision != _precision) {
                return false;
            }

            for (int i = 0; i < _registers.length; i++) {
                if (other._registers[i] > _registers[i]) {
                    _registers[i] = other._registers[i];
                }
            }
            return true;
        }

        /**
         * Returns configured error rate of this instance.
         *
         * @return estimated error rate.
         */
        public double errorRate () {
            return _actual_error_rate;
        }

        /**
         * Returns internal register count.
         *
         * @return number of registers.
         */
        public int registerCount () {
            return _registers.length;
        }

        /**
         * Serializes estimator state.
         *
         * @return serialized bytes.
         */
        public uint8[] toBytes () {
            uint8[] out = new uint8[_registers.length + 1];
            out[0] = (uint8) _precision;
            for (int i = 0; i < _registers.length; i++) {
                out[i + 1] = _registers[i];
            }
            return out;
        }

        /**
         * Restores estimator from bytes.
         *
         * @param bytes serialized bytes.
         * @return restored HyperLogLog or null when bytes are invalid.
         */
        public static HyperLogLog ? fromBytes (uint8[] bytes) {
            if (bytes.length < 2) {
                return null;
            }

            int precision = (int) bytes[0];
            if (precision < MIN_PRECISION || precision > MAX_PRECISION) {
                return null;
            }
            int registerCount = 1 << precision;
            if (bytes.length != registerCount + 1) {
                return null;
            }

            var hll = new HyperLogLog.withPrecision (precision);
            for (int i = 0; i < registerCount; i++) {
                hll._registers[i] = bytes[i + 1];
            }
            return hll;
        }

        /**
         * Clears internal state.
         */
        public void clear () {
            for (int i = 0; i < _registers.length; i++) {
                _registers[i] = 0;
            }
        }

        private static int precisionForErrorRate (double errorRate) {
            double m = GLib.Math.pow (1.04 / errorRate, 2.0);
            int precision = (int) GLib.Math.ceil (GLib.Math.log2 (m));
            if (precision < MIN_PRECISION) {
                return MIN_PRECISION;
            }
            if (precision > MAX_PRECISION) {
                return MAX_PRECISION;
            }
            return precision;
        }

        private void addHashed (uint64 hash) {
            int index = (int) (hash >> (64 - _precision));
            int rank = rho (hash);
            if (rank > _registers[index]) {
                _registers[index] = (uint8) rank;
            }
        }

        private int rho (uint64 hash) {
            int maxRank = 64 - _precision + 1;
            int rank = 1;
            uint64 mask = 1UL << (63 - _precision);

            while (rank < maxRank && (hash & mask) == 0UL) {
                rank++;
                mask >>= 1;
            }
            return rank;
        }

        private static double alphaForRegisterCount (int m) {
            if (m == 16) {
                return 0.673;
            }
            if (m == 32) {
                return 0.697;
            }
            if (m == 64) {
                return 0.709;
            }
            return 0.7213 / (1.0 + (1.079 / (double) m));
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
