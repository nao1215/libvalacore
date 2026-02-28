namespace Vala.Crypto {
    /**
     * Immutable UUID value object.
     */
    public class Uuid : GLib.Object {
        private string _value;

        private Uuid (string normalized) {
            _value = normalized;
        }

        /**
         * Generates a random UUID v4.
         *
         * @return random UUID instance.
         */
        public static Uuid v4 () {
            return new Uuid (GLib.Uuid.string_random ());
        }

        /**
         * Parses a UUID string.
         *
         * Returns null when the input is not a valid UUID.
         *
         * @param s UUID string.
         * @return parsed UUID or null.
         */
        public static Uuid? parse (string s) {
            if (s.length == 0) {
                return null;
            }

            string normalized = s.down ();
            if (!GLib.Uuid.string_is_valid (normalized)) {
                return null;
            }

            return new Uuid (normalized);
        }

        /**
         * Returns the canonical UUID string.
         *
         * @return UUID string.
         */
        public string toString () {
            return _value;
        }
    }
}
