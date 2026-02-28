namespace Vala.Crypto {
    /**
     * Static utility methods for HMAC.
     */
    public class Hmac : GLib.Object {
        /**
         * Returns an HMAC-SHA256 hash in hexadecimal string form.
         *
         * @param key HMAC key.
         * @param message message to hash.
         * @return HMAC-SHA256 hash.
         */
        public static string sha256 (string key, string message) {
            return GLib.Hmac.compute_for_string (
                GLib.ChecksumType.SHA256,
                key.data,
                message
            );
        }

        /**
         * Returns an HMAC-SHA512 hash in hexadecimal string form.
         *
         * @param key HMAC key.
         * @param message message to hash.
         * @return HMAC-SHA512 hash.
         */
        public static string sha512 (string key, string message) {
            return GLib.Hmac.compute_for_string (
                GLib.ChecksumType.SHA512,
                key.data,
                message
            );
        }

        /**
         * Compares two hashes in a timing-safe manner.
         *
         * @param expected expected hash.
         * @param actual actual hash.
         * @return true if equal.
         */
        public static bool verify (string expected, string actual) {
            if (expected.length != actual.length) {
                return false;
            }

            uint8 diff = 0;
            uint8[] expected_bytes = expected.data;
            uint8[] actual_bytes = actual.data;
            for (int i = 0; i < expected.length; i++) {
                diff |= (uint8) (expected_bytes[i] ^ actual_bytes[i]);
            }
            return diff == 0;
        }
    }
}
