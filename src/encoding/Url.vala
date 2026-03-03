using Vala.Collections;

namespace Vala.Encoding {
    /**
     * Error domain for URL codec operations.
     */
    public errordomain UrlError {
        PARSE
    }

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
         * @param s encoded URL component.
         * @return Result.ok(decoded string), or
         *         Result.error(UrlError.PARSE) on malformed percent-encoding.
         */
        public static Result<string, GLib.Error> decode (string s) {
            string ? decoded = GLib.Uri.unescape_string (s, null);
            if (decoded == null) {
                return Result.error<string, GLib.Error> (
                    new UrlError.PARSE ("failed to decode percent-encoded input: %s".printf (s))
                );
            }
            return Result.ok<string, GLib.Error> (decoded);
        }
    }
}
