using Vala.Collections;
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
         * Converts the provided error into a failed Result.
         *
         * @param e error to propagate.
         * @return Result.error carrying the provided error.
         */
        public static Result<bool ?, GLib.Error> sneakyThrow (GLib.Error e) {
            return Result.error<bool ?, GLib.Error> (e);
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
