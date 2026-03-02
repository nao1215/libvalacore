using Vala.Collections;

namespace Vala.Encoding {
    /**
     * Error domain for Base64 codec operations.
     */
    public errordomain Base64Error {
        INVALID_ARGUMENT,
        PARSE
    }

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
         * @return Result.ok(decoded bytes), or
         *         Result.error(Base64Error.INVALID_ARGUMENT/PARSE) on invalid input.
         */
        public static Result<GLib.Bytes, GLib.Error> decode (string encoded) {
            if (encoded == "") {
                return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (new uint8[0]));
            }

            Result<bool ?, GLib.Error> validated = validateBase64Input (encoded);
            if (validated.isError ()) {
                return Result.error<GLib.Bytes, GLib.Error> (validated.unwrapError ());
            }

            uint8[] decoded = GLib.Base64.decode (encoded);
            return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (decoded));
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
         * @return Result.ok(decoded string), or
         *         Result.error(Base64Error.INVALID_ARGUMENT/PARSE) on invalid input.
         */
        public static Result<string, GLib.Error> decodeString (string s) {
            Result<GLib.Bytes, GLib.Error> decodedResult = decode (s);
            if (decodedResult.isError ()) {
                return Result.error<string, GLib.Error> (decodedResult.unwrapError ());
            }

            uint8[] decoded = decodedResult.unwrap ().get_data ();
            var builder = new GLib.StringBuilder ();
            foreach (uint8 b in decoded) {
                builder.append_c ((char) b);
            }
            return Result.ok<string, GLib.Error> (builder.str);
        }

        private static Result<bool ?, GLib.Error> validateBase64Input (string encoded) {
            if (encoded.length % 4 != 0) {
                return Result.error<bool ?, GLib.Error> (
                    new Base64Error.INVALID_ARGUMENT (
                        "base64 text length must be a multiple of 4: %d".printf (encoded.length)
                    )
                );
            }

            bool seen_padding = false;
            int padding_count = 0;

            for (int i = 0; i < encoded.length; i++) {
                unichar c = encoded.get_char (i);
                if (c == '=') {
                    if (i < encoded.length - 2) {
                        return Result.error<bool ?, GLib.Error> (
                            new Base64Error.PARSE (
                                "padding '=' is only allowed in the last two characters: position=%d".printf (i)
                            )
                        );
                    }
                    seen_padding = true;
                    padding_count++;
                    continue;
                }

                if (seen_padding) {
                    return Result.error<bool ?, GLib.Error> (
                        new Base64Error.PARSE (
                            "base64 text has non-padding character after '=' at position %d".printf (i)
                        )
                    );
                }

                if (!isBase64Char (c)) {
                    return Result.error<bool ?, GLib.Error> (
                        new Base64Error.PARSE (
                            "invalid base64 character at position %d".printf (i)
                        )
                    );
                }
            }

            if (padding_count > 2) {
                return Result.error<bool ?, GLib.Error> (
                    new Base64Error.PARSE ("base64 text can contain at most two '=' padding characters")
                );
            }
            return Result.ok<bool ?, GLib.Error> (true);
        }

        private static bool isBase64Char (unichar c) {
            return (c >= 'A' && c <= 'Z') ||
                   (c >= 'a' && c <= 'z') ||
                   (c >= '0' && c <= '9') ||
                   c == '+' ||
                   c == '/';
        }
    }
}
