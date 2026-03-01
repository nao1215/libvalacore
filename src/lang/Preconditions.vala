namespace Vala.Lang {
    /**
     * Recoverable precondition validation errors.
     */
    public errordomain PreconditionError {
        INVALID_ARGUMENT,
        INVALID_STATE
    }

    /**
     * Utility methods for precondition checks.
     *
     * Methods in this class throw recoverable errors when a condition is
     * violated. Use these checks for programmer errors (invalid arguments or
     * illegal state), and propagate the failure to callers.
     *
     * Example:
     * {{{
     *     Preconditions.checkArgument (port > 0, "port must be positive");
     *     Preconditions.checkState (is_initialized, "not initialized");
     * }}}
     */
    public class Preconditions : GLib.Object {
        private static string normalizeMessage (string message, string defaultMessage) {
            if (message.strip ().length == 0) {
                return defaultMessage;
            }
            return message;
        }

        private static void validate (bool cond,
                                      string message,
                                      string defaultMessage,
                                      bool argumentError) throws PreconditionError {
            if (cond) {
                return;
            }

            string finalMessage = normalizeMessage (message, defaultMessage);
            if (argumentError) {
                throw new PreconditionError.INVALID_ARGUMENT (finalMessage);
            }
            throw new PreconditionError.INVALID_STATE (finalMessage);
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
         * @throws PreconditionError.INVALID_ARGUMENT when condition is false.
         */
        public static void checkArgument (bool cond, string message) throws PreconditionError {
            validate (cond, message, "Invalid argument", true);
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
         * @throws PreconditionError.INVALID_STATE when condition is false.
         */
        public static void checkState (bool cond, string message) throws PreconditionError {
            validate (cond, message, "Invalid state", false);
        }
    }
}
