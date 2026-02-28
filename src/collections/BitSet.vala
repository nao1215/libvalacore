namespace Vala.Collections {
    /**
     * A fixed-size or dynamically growing set of bits.
     *
     * BitSet supports individual bit manipulation and bitwise operations
     * (AND, OR, XOR). Inspired by Java's BitSet.
     *
     * Bits are indexed starting from 0. The BitSet automatically grows
     * to accommodate any bit index set.
     *
     * Example:
     * {{{
     *     var bits = new BitSet (64);
     *     bits.set (0);
     *     bits.set (3);
     *     bits.set (7);
     *     assert (bits.get (3));
     *     assert (!bits.get (4));
     *     assert (bits.cardinality () == 3);
     * }}}
     */
    public class BitSet : GLib.Object {
        private uint8[] _data;

        /**
         * Creates a BitSet with the specified initial capacity in bits.
         * All bits are initially zero. The BitSet will grow as needed.
         *
         * Example:
         * {{{
         *     var bits = new BitSet (128);
         *     assert (bits.isEmpty ());
         * }}}
         *
         * @param size the initial capacity in bits (default 64).
         */
        public BitSet (int size = 64) {
            int bytes = (size + 7) / 8;
            if (bytes < 1) {
                bytes = 1;
            }
            _data = new uint8[bytes];
            for (int i = 0; i < bytes; i++) {
                _data[i] = 0;
            }
        }

        /**
         * Sets the bit at the specified index to 1.
         *
         * If the index is beyond the current capacity, the BitSet
         * is automatically grown.
         *
         * Example:
         * {{{
         *     var bits = new BitSet (8);
         *     bits.set (5);
         *     assert (bits.get (5));
         * }}}
         *
         * @param index the zero-based bit index. Must be >= 0.
         */
        public new void set (int index) {
            if (index < 0) {
                return;
            }
            _ensure_capacity (index);
            _data[index / 8] |= (uint8) (1 << (index % 8));
        }

        /**
         * Sets the bit at the specified index to 0.
         *
         * If the index is beyond the current capacity, this is a no-op.
         *
         * Example:
         * {{{
         *     var bits = new BitSet (8);
         *     bits.set (5);
         *     bits.clear (5);
         *     assert (!bits.get (5));
         * }}}
         *
         * @param index the zero-based bit index.
         */
        public void clearBit (int index) {
            if (index < 0 || index / 8 >= _data.length) {
                return;
            }
            _data[index / 8] &= (uint8) ~(1 << (index % 8));
        }

        /**
         * Returns the value of the bit at the specified index.
         *
         * Returns false if the index is beyond the current capacity.
         *
         * Example:
         * {{{
         *     var bits = new BitSet (8);
         *     bits.set (3);
         *     assert (bits.get (3));
         *     assert (!bits.get (4));
         * }}}
         *
         * @param index the zero-based bit index.
         * @return true if the bit is 1, false if 0 or out of range.
         */
        public new bool get (int index) {
            if (index < 0 || index / 8 >= _data.length) {
                return false;
            }
            return (_data[index / 8] & (uint8) (1 << (index % 8))) != 0;
        }

        /**
         * Flips the bit at the specified index (0 becomes 1, 1 becomes 0).
         *
         * If the index is beyond the current capacity, the BitSet
         * is grown and the bit is set to 1.
         *
         * Example:
         * {{{
         *     var bits = new BitSet (8);
         *     bits.flip (3);
         *     assert (bits.get (3));
         *     bits.flip (3);
         *     assert (!bits.get (3));
         * }}}
         *
         * @param index the zero-based bit index. Must be >= 0.
         */
        public void flip (int index) {
            if (index < 0) {
                return;
            }
            _ensure_capacity (index);
            _data[index / 8] ^= (uint8) (1 << (index % 8));
        }

        /**
         * Performs a bitwise AND with another BitSet, modifying this
         * BitSet in place. Bits beyond the other's length are cleared.
         *
         * Example:
         * {{{
         *     var a = new BitSet (8);
         *     a.set (0);
         *     a.set (1);
         *     var b = new BitSet (8);
         *     b.set (1);
         *     b.set (2);
         *     a.and (b);
         *     assert (!a.get (0));
         *     assert (a.get (1));
         *     assert (!a.get (2));
         * }}}
         *
         * @param other the other BitSet.
         */
        public void and (BitSet other) {
            int min_len = int.min (_data.length, other._data.length);
            for (int i = 0; i < min_len; i++) {
                _data[i] &= other._data[i];
            }
            for (int i = min_len; i < _data.length; i++) {
                _data[i] = 0;
            }
        }

        /**
         * Performs a bitwise OR with another BitSet, modifying this
         * BitSet in place.
         *
         * Example:
         * {{{
         *     var a = new BitSet (8);
         *     a.set (0);
         *     var b = new BitSet (8);
         *     b.set (1);
         *     a.or (b);
         *     assert (a.get (0));
         *     assert (a.get (1));
         * }}}
         *
         * @param other the other BitSet.
         */
        public void or (BitSet other) {
            if (other._data.length > _data.length) {
                _grow (other._data.length);
            }
            for (int i = 0; i < other._data.length; i++) {
                _data[i] |= other._data[i];
            }
        }

        /**
         * Performs a bitwise XOR with another BitSet, modifying this
         * BitSet in place.
         *
         * Example:
         * {{{
         *     var a = new BitSet (8);
         *     a.set (0);
         *     a.set (1);
         *     var b = new BitSet (8);
         *     b.set (1);
         *     b.set (2);
         *     a.xor (b);
         *     assert (a.get (0));
         *     assert (!a.get (1));
         *     assert (a.get (2));
         * }}}
         *
         * @param other the other BitSet.
         */
        public void xor (BitSet other) {
            if (other._data.length > _data.length) {
                _grow (other._data.length);
            }
            for (int i = 0; i < other._data.length; i++) {
                _data[i] ^= other._data[i];
            }
        }

        /**
         * Returns the number of bits that are set to 1.
         *
         * Example:
         * {{{
         *     var bits = new BitSet (8);
         *     bits.set (0);
         *     bits.set (3);
         *     bits.set (7);
         *     assert (bits.cardinality () == 3);
         * }}}
         *
         * @return the number of set bits.
         */
        public int cardinality () {
            int count = 0;
            for (int i = 0; i < _data.length; i++) {
                uint8 b = _data[i];
                while (b != 0) {
                    count += (int) (b & 1);
                    b >>= 1;
                }
            }
            return count;
        }

        /**
         * Returns the index of the highest set bit plus one.
         * Returns 0 if no bits are set.
         *
         * Example:
         * {{{
         *     var bits = new BitSet (64);
         *     bits.set (10);
         *     assert (bits.length () == 11);
         * }}}
         *
         * @return the logical size of the BitSet.
         */
        public int length () {
            for (int i = _data.length - 1; i >= 0; i--) {
                if (_data[i] != 0) {
                    int bit = 7;
                    while (bit >= 0 && (_data[i] & (uint8) (1 << bit)) == 0) {
                        bit--;
                    }
                    return i * 8 + bit + 1;
                }
            }
            return 0;
        }

        /**
         * Returns whether all bits are 0.
         *
         * Example:
         * {{{
         *     var bits = new BitSet (8);
         *     assert (bits.isEmpty ());
         *     bits.set (0);
         *     assert (!bits.isEmpty ());
         * }}}
         *
         * @return true if no bits are set.
         */
        public bool isEmpty () {
            for (int i = 0; i < _data.length; i++) {
                if (_data[i] != 0) {
                    return false;
                }
            }
            return true;
        }

        /**
         * Returns a string representation of the BitSet.
         *
         * The format lists the indices of set bits in braces,
         * e.g. ''{0, 3, 7}''.
         *
         * Example:
         * {{{
         *     var bits = new BitSet (8);
         *     bits.set (0);
         *     bits.set (3);
         *     assert (bits.toString () == "{0, 3}");
         * }}}
         *
         * @return the string representation.
         */
        public string toString () {
            var sb = new GLib.StringBuilder ("{");
            bool first = true;
            int total_bits = _data.length * 8;
            for (int i = 0; i < total_bits; i++) {
                if (get (i)) {
                    if (!first) {
                        sb.append (", ");
                    }
                    sb.append ("%d".printf (i));
                    first = false;
                }
            }
            sb.append ("}");
            return sb.str;
        }

        /**
         * Sets all bits to 0.
         *
         * Example:
         * {{{
         *     var bits = new BitSet (8);
         *     bits.set (0);
         *     bits.set (3);
         *     bits.clearAll ();
         *     assert (bits.isEmpty ());
         * }}}
         */
        public void clearAll () {
            for (int i = 0; i < _data.length; i++) {
                _data[i] = 0;
            }
        }

        private void _ensure_capacity (int bit_index) {
            int needed = bit_index / 8 + 1;
            if (needed > _data.length) {
                _grow (needed);
            }
        }

        private void _grow (int new_byte_len) {
            var new_data = new uint8[new_byte_len];
            for (int i = 0; i < new_byte_len; i++) {
                if (i < _data.length) {
                    new_data[i] = _data[i];
                } else {
                    new_data[i] = 0;
                }
            }
            _data = new_data;
        }
    }
}
