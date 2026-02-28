namespace Vala.Encoding {
    /**
     * Static utility methods for Base64 encoding and decoding.
     *
     * Example:
     * {{{
     *     uint8[] data = { 0x48, 0x65, 0x6C, 0x6C, 0x6F };
     *     string encoded = Base64.encode (data);
     *     assert (encoded == "SGVsbG8=");
     * }}}
     */
    public class Base64 : GLib.Object {
        /**
         * Encodes bytes to Base64.
         *
         * @param data bytes to encode.
         * @return Base64 encoded string.
         */
        public static string encode (uint8[] data) {
            return GLib.Base64.encode (data);
        }

        /**
         * Decodes Base64 text into bytes.
         *
         * @param encoded Base64 encoded text.
         * @return decoded bytes.
         */
        public static uint8[] decode (string encoded) {
            if (encoded == "") {
                uint8[] empty = {};
                return empty;
            }
            return GLib.Base64.decode (encoded);
        }

        /**
         * Encodes a UTF-8 string to Base64.
         *
         * @param s string to encode.
         * @return Base64 encoded string.
         */
        public static string encodeString (string s) {
            return encode (s.data);
        }

        /**
         * Decodes Base64 text and returns it as a UTF-8 string.
         *
         * @param s Base64 encoded text.
         * @return decoded string.
         */
        public static string decodeString (string s) {
            uint8[] decoded = decode (s);
            var builder = new GLib.StringBuilder ();
            foreach (uint8 b in decoded) {
                builder.append_c ((char) b);
            }
            return builder.str;
        }
    }
}
