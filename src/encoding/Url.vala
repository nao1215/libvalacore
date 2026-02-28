namespace Vala.Encoding {
    /**
     * Static utility methods for URL percent-encoding.
     *
     * Example:
     * {{{
     *     string encoded = Url.encode ("a b+c");
     *     assert (encoded == "a%20b%2Bc");
     * }}}
     */
    public class Url : GLib.Object {
        /**
         * Encodes text using URL percent-encoding.
         *
         * @param s text to encode.
         * @return encoded URL component.
         */
        public static string encode (string s) {
            return GLib.Uri.escape_string (s, null, true);
        }

        /**
         * Decodes URL percent-encoded text.
         *
         * Returns an empty string when the input cannot be decoded.
         *
         * @param s encoded URL component.
         * @return decoded string.
         */
        public static string decode (string s) {
            string ? decoded = GLib.Uri.unescape_string (s, null);
            if (decoded == null) {
                return "";
            }
            return decoded;
        }
    }
}
