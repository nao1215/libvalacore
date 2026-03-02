using Vala.Collections;

namespace Vala.Encoding {
    /**
     * Error domain for hex codec operations.
     */
    public errordomain HexError {
        INVALID_ARGUMENT,
        PARSE
    }

    /**
     * Static utility methods for hexadecimal encoding and decoding.
     *
     * Example:
     * {{{
     *     uint8[] data = { 0x48, 0x65, 0x6C, 0x6C, 0x6F };
     *     string encoded = Hex.encode (data);
     *     assert (encoded == "48656c6c6f");
     * }}}
     */
    public class Hex : GLib.Object {
        /**
         * Encodes bytes to a hexadecimal string.
         *
         * @param data bytes to encode.
         * @return lower-case hexadecimal string.
         */
        public static string encode (uint8[] data) {
            var builder = new GLib.StringBuilder ();
            foreach (uint8 b in data) {
                builder.append_printf ("%02x", b);
            }
            return builder.str;
        }

        /**
         * Decodes a hexadecimal string into bytes.
         *
         * Returns an empty array for invalid input (odd length or
         * non-hex characters).
         *
         * @param hex hexadecimal text.
         * @return Result.ok(decoded bytes), or
         *         Result.error(HexError.INVALID_ARGUMENT/PARSE) on invalid input.
         */
        public static Result<GLib.Bytes, GLib.Error> decode (string hex) {
            if (hex == "") {
                return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (new uint8[0]));
            }

            if (hex.length % 2 != 0) {
                return Result.error<GLib.Bytes, GLib.Error> (
                    new HexError.INVALID_ARGUMENT ("hex text length must be even: %d".printf (hex.length))
                );
            }

            uint8[] result = new uint8[hex.length / 2];
            int out_index = 0;
            for (int i = 0; i < hex.length; i += 2) {
                int high = _hex_value (hex.get_char (i));
                int low = _hex_value (hex.get_char (i + 1));
                if (high < 0 || low < 0) {
                    return Result.error<GLib.Bytes, GLib.Error> (
                        new HexError.PARSE ("invalid hex character at position %d".printf (i))
                    );
                }
                result[out_index] = (uint8) ((high << 4) | low);
                out_index++;
            }
            return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (result));
        }

        private static int _hex_value (unichar c) {
            if (c >= '0' && c <= '9') {
                return (int) c - (int) '0';
            }
            if (c >= 'a' && c <= 'f') {
                return 10 + ((int) c - (int) 'a');
            }
            if (c >= 'A' && c <= 'F') {
                return 10 + ((int) c - (int) 'A');
            }
            return -1;
        }
    }
}
