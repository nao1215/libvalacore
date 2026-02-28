namespace Vala.Crypto {
    /**
     * Static utility methods for cryptographic hashes.
     *
     * This class provides one-shot digest helpers that return lowercase
     * hexadecimal strings. Prefer SHA-256/SHA-512 for security-sensitive use
     * cases; MD5/SHA-1 are kept for compatibility and non-security checksums.
     *
     * Example:
     * {{{
     *     string digest = Hash.sha256 ("payload");
     *     print ("%s\n", digest);
     * }}}
     */
    public class Hash : GLib.Object {
        /**
         * Returns an MD5 hash in hexadecimal string form.
         *
         * @param s input string.
         * @return MD5 hash.
         */
        public static string md5 (string s) {
            return GLib.Checksum.compute_for_string (GLib.ChecksumType.MD5, s);
        }

        /**
         * Returns an MD5 hash for bytes in hexadecimal string form.
         *
         * @param data input bytes.
         * @return MD5 hash.
         */
        public static string md5Bytes (uint8[] data) {
            return GLib.Checksum.compute_for_data (GLib.ChecksumType.MD5, data);
        }

        /**
         * Returns a SHA-1 hash in hexadecimal string form.
         *
         * @param s input string.
         * @return SHA-1 hash.
         */
        public static string sha1 (string s) {
            return GLib.Checksum.compute_for_string (GLib.ChecksumType.SHA1, s);
        }

        /**
         * Returns a SHA-256 hash in hexadecimal string form.
         *
         * @param s input string.
         * @return SHA-256 hash.
         */
        public static string sha256 (string s) {
            return GLib.Checksum.compute_for_string (GLib.ChecksumType.SHA256, s);
        }

        /**
         * Returns a SHA-256 hash for bytes in hexadecimal string form.
         *
         * @param data input bytes.
         * @return SHA-256 hash.
         */
        public static string sha256Bytes (uint8[] data) {
            return GLib.Checksum.compute_for_data (GLib.ChecksumType.SHA256, data);
        }

        /**
         * Returns a SHA-512 hash in hexadecimal string form.
         *
         * @param s input string.
         * @return SHA-512 hash.
         */
        public static string sha512 (string s) {
            return GLib.Checksum.compute_for_string (GLib.ChecksumType.SHA512, s);
        }
    }
}
