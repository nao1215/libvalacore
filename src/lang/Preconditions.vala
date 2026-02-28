namespace Vala.Lang {
    /**
     * Utility methods for precondition checks.
     *
     * Methods in this class fail-fast when a condition is violated. Use these
     * checks for programmer errors (invalid arguments or illegal state), not
     * for recoverable runtime conditions.
     *
     * Example:
     * {{{
     *     Preconditions.checkArgument (port > 0, "port must be positive");
     *     Preconditions.checkState (is_initialized, "not initialized");
     * }}}
     */
    public class Preconditions : GLib.Object {
        private static void validate (bool cond, string message, string defaultMessage) {
            if (cond) {
                return;
            }
            if (message.length == 0) {
                error ("%s", defaultMessage);
            }
            error ("%s", message);
        }

        /**
         * Checks argument preconditions.
         *
         * Example:
         * {{{
         *     Preconditions.checkArgument (name.length > 0, "name must not be empty");
         * }}}
         *
         * @param cond condition that must be true.
         * @param message error message when condition is false.
         */
        public static void checkArgument (bool cond, string message) {
            validate (cond, message, "Invalid argument");
        }

        /**
         * Checks state preconditions.
         *
         * Example:
         * {{{
         *     Preconditions.checkState (isOpen, "resource is closed");
         * }}}
         *
         * @param cond condition that must be true.
         * @param message error message when condition is false.
         */
        public static void checkState (bool cond, string message) {
            validate (cond, message, "Invalid state");
        }
    }
}
