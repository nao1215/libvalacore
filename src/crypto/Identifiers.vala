namespace Vala.Crypto {
    /**
     * Supported identifier types.
     */
    public enum IdentifierType {
        UUID_V4,
        UUID_V7,
        ULID,
        KSUID
    }

    /**
     * Immutable identifier value object.
     */
    public class Identifier : GLib.Object {
        private string _value;
        private IdentifierType _type;

        internal Identifier (string value, IdentifierType type) {
            _value = value;
            _type = type;
        }

        /**
         * Returns identifier string value.
         *
         * @return identifier value.
         */
        public string value () {
            return _value;
        }

        /**
         * Returns identifier type.
         *
         * @return identifier type.
         */
        public IdentifierType type () {
            return _type;
        }

        /**
         * Returns extracted timestamp in milliseconds when supported.
         *
         * @return extracted timestamp, or null.
         */
        public int64 ? timestampMillis () {
            return Identifiers.timestampMillis (_value);
        }

        /**
         * Converts identifier to bytes.
         *
         * @return binary representation, or null.
         */
        public uint8[] ? toBytes () {
            return Identifiers.toBytes (_value);
        }
    }

    /**
     * Utility class for UUID/ULID/KSUID generation and conversion.
     */
    public class Identifiers : GLib.Object {
        private const string BASE32_ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
        private const string BASE62_ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
        private const int64 KSUID_EPOCH_SECONDS = 1400000000;

        private static GLib.Mutex _monotonic_mutex;
        private static bool _has_monotonic_state = false;
        private static int64 _last_ulid_millis = -1;
        private static uint8[] ? _last_ulid_entropy = null;
        private static uint16 _last_ulid_counter = 0;

        /**
         * Generates random UUID v4 string.
         *
         * @return UUID v4 string.
         */
        public static string uuidV4 () {
            return GLib.Uuid.string_random ();
        }

        /**
         * Generates time-ordered UUID v7 string.
         *
         * @return UUID v7 string.
         */
        public static string uuidV7 () {
            uint8[] bytes = randomBytes (16);
            writeTimestampMillis48 (bytes, currentTimeMillis ());
            bytes[6] = (uint8) ((bytes[6] & 0x0f) | 0x70);
            bytes[8] = (uint8) ((bytes[8] & 0x3f) | 0x80);
            return uuidFromBytes (bytes);
        }

        /**
         * Generates ULID string.
         *
         * @return ULID string.
         */
        public static string ulid () {
            uint8[] bytes = randomBytes (16);
            writeTimestampMillis48 (bytes, currentTimeMillis ());
            return encodeUlidBytes (bytes);
        }

        /**
         * Generates monotonic ULID string.
         *
         * @return monotonic ULID string.
         */
        public static string ulidMonotonic () {
            _monotonic_mutex.lock ();
            int64 now = currentTimeMillis ();

            if (!_has_monotonic_state || now > _last_ulid_millis) {
                _last_ulid_millis = now;
                _last_ulid_counter = 0;
                _last_ulid_entropy = randomBytes (8);
                _has_monotonic_state = true;
            } else {
                now = _last_ulid_millis;
                if (_last_ulid_counter == uint16.MAX) {
                    _last_ulid_millis++;
                    now = _last_ulid_millis;
                    _last_ulid_counter = 0;
                    _last_ulid_entropy = randomBytes (8);
                } else {
                    _last_ulid_counter++;
                }
            }

            uint8[] bytes = new uint8[16];
            writeTimestampMillis48 (bytes, now);

            uint8[] entropy = _last_ulid_entropy;
            for (int i = 0; i < 8; i++) {
                bytes[6 + i] = entropy[i];
            }
            bytes[14] = (uint8) ((_last_ulid_counter >> 8) & 0xff);
            bytes[15] = (uint8) (_last_ulid_counter & 0xff);

            string candidate = encodeUlidBytes (bytes);
            _monotonic_mutex.unlock ();
            return candidate;
        }

        /**
         * Generates KSUID string.
         *
         * @return KSUID string.
         */
        public static string ksuid () {
            int64 unixSeconds = GLib.get_real_time () / 1000000;
            int64 relative = unixSeconds - KSUID_EPOCH_SECONDS;
            if (relative < 0) {
                relative = 0;
            }

            uint8[] bytes = new uint8[20];
            bytes[0] = (uint8) ((relative >> 24) & 0xff);
            bytes[1] = (uint8) ((relative >> 16) & 0xff);
            bytes[2] = (uint8) ((relative >> 8) & 0xff);
            bytes[3] = (uint8) (relative & 0xff);

            uint8[] randomPayload = randomBytes (16);
            for (int i = 0; i < 16; i++) {
                bytes[4 + i] = randomPayload[i];
            }
            return encodeKsuidBytes (bytes);
        }

        /**
         * Returns whether string is valid UUID.
         *
         * @param s input string.
         * @return true if valid UUID.
         */
        public static bool isUuid (string s) {
            if (s.length == 0) {
                return false;
            }
            return GLib.Uuid.string_is_valid (s.down ());
        }

        /**
         * Returns whether string is valid ULID.
         *
         * @param s input string.
         * @return true if valid ULID.
         */
        public static bool isUlid (string s) {
            if (s.length != 26) {
                return false;
            }
            string upper = s.up ();
            for (int i = 0; i < upper.length; i++) {
                if (base32Index (upper[i]) < 0) {
                    return false;
                }
            }
            return base32Index (upper[0]) <= 7;
        }

        /**
         * Returns whether string is valid KSUID.
         *
         * @param s input string.
         * @return true if valid KSUID.
         */
        public static bool isKsuid (string s) {
            if (s.length != 27) {
                return false;
            }
            for (int i = 0; i < s.length; i++) {
                if (base62Index (s[i]) < 0) {
                    return false;
                }
            }
            return true;
        }

        /**
         * Parses UUID into identifier value object.
         *
         * @param s UUID string.
         * @return identifier or null.
         */
        public static Identifier ? parseUuid (string s) {
            if (!isUuid (s)) {
                return null;
            }
            string normalized = s.down ();
            IdentifierType type = normalized.substring (14, 1) == "7" ?
                                  IdentifierType.UUID_V7 :
                                  IdentifierType.UUID_V4;
            return new Identifier (normalized, type);
        }

        /**
         * Parses ULID into identifier value object.
         *
         * @param s ULID string.
         * @return identifier or null.
         */
        public static Identifier ? parseUlid (string s) {
            if (!isUlid (s)) {
                return null;
            }
            return new Identifier (s.up (), IdentifierType.ULID);
        }

        /**
         * Parses KSUID into identifier value object.
         *
         * @param s KSUID string.
         * @return identifier or null.
         */
        public static Identifier ? parseKsuid (string s) {
            if (!isKsuid (s)) {
                return null;
            }
            return new Identifier (s, IdentifierType.KSUID);
        }

        /**
         * Converts identifier string to bytes.
         *
         * @param id identifier string.
         * @return bytes, or null for invalid input.
         */
        public static uint8[] ? toBytes (string id) {
            if (isUuid (id)) {
                return uuidToBytes (id.down ());
            }
            if (isUlid (id)) {
                return decodeUlidToBytes (id.up ());
            }
            if (isKsuid (id)) {
                return decodeKsuidToBytes (id);
            }
            return null;
        }

        /**
         * Converts bytes to identifier string of given type.
         *
         * Supported type values: uuid, uuid_v4, uuid_v7, ulid, ksuid.
         *
         * @param bytes input bytes.
         * @param type target type string.
         * @return encoded identifier string, or null.
         */
        public static string ? fromBytes (uint8[] bytes, string type) {
            string t = type.down ();
            if (t == "uuid" || t == "uuid_v4" || t == "uuidv4") {
                if (bytes.length != 16) {
                    return null;
                }
                uint8[] copy = cloneBytes (bytes);
                copy[6] = (uint8) ((copy[6] & 0x0f) | 0x40);
                copy[8] = (uint8) ((copy[8] & 0x3f) | 0x80);
                return uuidFromBytes (copy);
            }
            if (t == "uuid_v7" || t == "uuidv7") {
                if (bytes.length != 16) {
                    return null;
                }
                uint8[] copy = cloneBytes (bytes);
                copy[6] = (uint8) ((copy[6] & 0x0f) | 0x70);
                copy[8] = (uint8) ((copy[8] & 0x3f) | 0x80);
                return uuidFromBytes (copy);
            }
            if (t == "ulid") {
                if (bytes.length != 16) {
                    return null;
                }
                return encodeUlidBytes (bytes);
            }
            if (t == "ksuid") {
                if (bytes.length != 20) {
                    return null;
                }
                return encodeKsuidBytes (bytes);
            }
            return null;
        }

        /**
         * Extracts timestamp milliseconds from identifier.
         *
         * UUID v7, ULID and KSUID are supported.
         *
         * @param id identifier string.
         * @return timestamp milliseconds, or null.
         */
        public static int64 ? timestampMillis (string id) {
            if (isUuid (id)) {
                string normalized = id.down ();
                if (normalized.substring (14, 1) != "7") {
                    return null;
                }
                uint8[] ? bytes = uuidToBytes (normalized);
                if (bytes == null) {
                    return null;
                }
                return readTimestampMillis48 (bytes);
            }

            if (isUlid (id)) {
                uint8[] ? bytes = decodeUlidToBytes (id.up ());
                if (bytes == null) {
                    return null;
                }
                return readTimestampMillis48 (bytes);
            }

            if (isKsuid (id)) {
                uint8[] ? bytes = decodeKsuidToBytes (id);
                if (bytes == null || bytes.length != 20) {
                    return null;
                }
                int64 relative = ((int64) bytes[0] << 24) |
                                 ((int64) bytes[1] << 16) |
                                 ((int64) bytes[2] << 8) |
                                 (int64) bytes[3];
                return (relative + KSUID_EPOCH_SECONDS) * 1000;
            }

            return null;
        }

        /**
         * Compares identifiers by embedded timestamp.
         *
         * If timestamps are equal or unavailable, lexical order is used.
         *
         * @param a first identifier.
         * @param b second identifier.
         * @return -1, 0, or 1.
         */
        public static int compareByTime (string a, string b) {
            int64 ? ta = timestampMillis (a);
            int64 ? tb = timestampMillis (b);

            if (ta != null && tb != null && ta != tb) {
                return ta < tb ? -1 : 1;
            }
            return strcmp (a, b);
        }

        private static int64 currentTimeMillis () {
            return GLib.get_real_time () / 1000;
        }

        private static uint8[] randomBytes (int length) {
            uint8[] bytes = new uint8[length];
            for (int i = 0; i < length; i++) {
                bytes[i] = (uint8) GLib.Random.int_range (0, 256);
            }
            return bytes;
        }

        private static void writeTimestampMillis48 (uint8[] bytes, int64 millis) {
            bytes[0] = (uint8) ((millis >> 40) & 0xff);
            bytes[1] = (uint8) ((millis >> 32) & 0xff);
            bytes[2] = (uint8) ((millis >> 24) & 0xff);
            bytes[3] = (uint8) ((millis >> 16) & 0xff);
            bytes[4] = (uint8) ((millis >> 8) & 0xff);
            bytes[5] = (uint8) (millis & 0xff);
        }

        private static int64 readTimestampMillis48 (uint8[] bytes) {
            return ((int64) bytes[0] << 40) |
                   ((int64) bytes[1] << 32) |
                   ((int64) bytes[2] << 24) |
                   ((int64) bytes[3] << 16) |
                   ((int64) bytes[4] << 8) |
                   (int64) bytes[5];
        }

        private static string uuidFromBytes (uint8[] bytes) {
            var builder = new GLib.StringBuilder ();
            for (int i = 0; i < 16; i++) {
                builder.append_printf ("%02x", bytes[i]);
                if (i == 3 || i == 5 || i == 7 || i == 9) {
                    builder.append_c ('-');
                }
            }
            return builder.str;
        }

        private static uint8[] ? uuidToBytes (string uuid) {
            string compact = uuid.replace ("-", "");
            if (compact.length != 32) {
                return null;
            }

            uint8[] bytes = new uint8[16];
            for (int i = 0; i < 16; i++) {
                int hi = hexValue (compact[i * 2]);
                int lo = hexValue (compact[i * 2 + 1]);
                if (hi < 0 || lo < 0) {
                    return null;
                }
                bytes[i] = (uint8) ((hi << 4) | lo);
            }
            return bytes;
        }

        private static int hexValue (char c) {
            if (c >= '0' && c <= '9') {
                return c - '0';
            }
            if (c >= 'a' && c <= 'f') {
                return 10 + (c - 'a');
            }
            if (c >= 'A' && c <= 'F') {
                return 10 + (c - 'A');
            }
            return -1;
        }

        private static string encodeUlidBytes (uint8[] bytes) {
            uint8[] number = cloneBytes (bytes);
            var digits = new GLib.StringBuilder ();

            while (!allZero (number)) {
                int remainder = 0;
                for (int i = 0; i < number.length; i++) {
                    int acc = remainder * 256 + number[i];
                    number[i] = (uint8) (acc / 32);
                    remainder = acc % 32;
                }
                digits.append_c (BASE32_ALPHABET[remainder]);
            }

            if (digits.len == 0) {
                digits.append_c ('0');
            }

            string encoded = reverseString (digits.str);
            while (encoded.length < 26) {
                encoded = "0" + encoded;
            }
            return encoded;
        }

        private static uint8[] ? decodeUlidToBytes (string ulidValue) {
            if (!isUlid (ulidValue)) {
                return null;
            }

            uint8[] bytes = new uint8[16];
            for (int i = 0; i < ulidValue.length; i++) {
                int value = base32Index (ulidValue[i]);
                if (value < 0) {
                    return null;
                }

                int carry = value;
                for (int j = bytes.length - 1; j >= 0; j--) {
                    int acc = bytes[j] * 32 + carry;
                    bytes[j] = (uint8) (acc & 0xff);
                    carry = acc >> 8;
                }

                if (carry != 0) {
                    return null;
                }
            }
            return bytes;
        }

        private static string encodeKsuidBytes (uint8[] bytes) {
            uint8[] number = cloneBytes (bytes);
            var digits = new GLib.StringBuilder ();

            while (!allZero (number)) {
                int remainder = 0;
                for (int i = 0; i < number.length; i++) {
                    int acc = remainder * 256 + number[i];
                    number[i] = (uint8) (acc / 62);
                    remainder = acc % 62;
                }
                digits.append_c (BASE62_ALPHABET[remainder]);
            }

            if (digits.len == 0) {
                digits.append_c ('0');
            }

            string encoded = reverseString (digits.str);
            while (encoded.length < 27) {
                encoded = "0" + encoded;
            }
            return encoded;
        }

        private static uint8[] ? decodeKsuidToBytes (string ksuidValue) {
            if (!isKsuid (ksuidValue)) {
                return null;
            }

            uint8[] bytes = new uint8[20];
            for (int i = 0; i < ksuidValue.length; i++) {
                int val = base62Index (ksuidValue[i]);
                if (val < 0) {
                    return null;
                }

                int carry = val;
                for (int j = bytes.length - 1; j >= 0; j--) {
                    int acc = bytes[j] * 62 + carry;
                    bytes[j] = (uint8) (acc & 0xff);
                    carry = acc >> 8;
                }

                if (carry != 0) {
                    return null;
                }
            }
            return bytes;
        }

        private static uint8[] cloneBytes (uint8[] bytes) {
            uint8[] copy = new uint8[bytes.length];
            for (int i = 0; i < bytes.length; i++) {
                copy[i] = bytes[i];
            }
            return copy;
        }

        private static bool allZero (uint8[] bytes) {
            for (int i = 0; i < bytes.length; i++) {
                if (bytes[i] != 0) {
                    return false;
                }
            }
            return true;
        }

        private static string reverseString (string s) {
            var builder = new GLib.StringBuilder ();
            for (int i = s.length - 1; i >= 0; i--) {
                builder.append_c (s[i]);
            }
            return builder.str;
        }

        private static int base32Index (char c) {
            for (int i = 0; i < BASE32_ALPHABET.length; i++) {
                if (BASE32_ALPHABET[i] == c) {
                    return i;
                }
            }
            return -1;
        }

        private static int base62Index (char c) {
            for (int i = 0; i < BASE62_ALPHABET.length; i++) {
                if (BASE62_ALPHABET[i] == c) {
                    return i;
                }
            }
            return -1;
        }
    }
}
