namespace Vala.Lang {
    /**
     * Exception utility methods.
     *
     * This helper provides explicit formatting and fail-fast forwarding of
     * GLib.Error values. It is useful when you need consistent crash logs in
     * unrecoverable situations.
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
         * Throws the error as an unrecoverable process termination.
         *
         * @param e error to throw.
         */
        public static void sneakyThrow (GLib.Error e) {
            error ("%s", getStackTrace (e));
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
