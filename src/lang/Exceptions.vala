namespace Vala.Lang {
    /**
     * Exception utility methods.
     *
     * This helper provides explicit formatting and forwarding of GLib.Error
     * values.
     *
     * Example:
     * {{{
     *     try {
     *         might_fail ();
     *     } catch (GLib.Error e) {
     *         string trace = Exceptions.getStackTrace (e);
     *         print ("%s\n", trace);
     *     }
     * }}}
     */
    public class Exceptions : GLib.Object {
        /**
         * Rethrows the provided error.
         *
         * @param e error to rethrow.
         * @throws GLib.Error always throws the provided error.
         */
        public static void sneakyThrow (GLib.Error e) throws GLib.Error {
            throw e;
        }

        /**
         * Returns a printable stack-like error description.
         *
         * @param e error to describe.
         * @return formatted error details.
         */
        public static string getStackTrace (GLib.Error e) {
            return "Error(domain=%u, code=%d): %s".printf ((uint) e.domain, e.code, e.message);
        }
    }
}
