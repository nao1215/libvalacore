namespace Vala.Lang {
    /**
     * Exception utility methods.
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
