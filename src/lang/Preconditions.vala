using Vala.Collections;
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
     * Methods in this class return Result values when a condition is
     * violated. Use these checks for programmer errors (invalid arguments or
     * illegal state), and propagate the failure contract to callers.
     *
     * Example:
     * {{{
     *     var argOk = Preconditions.checkArgument (port > 0, "port must be positive");
     *     if (argOk.isError ()) {
     *         return;
     *     }
     *     var stateOk = Preconditions.checkState (is_initialized, "not initialized");
     *     if (stateOk.isError ()) {
     *         return;
     *     }
     * }}}
     */
    public class Preconditions : GLib.Object {
        private static string normalizeMessage (string message, string defaultMessage) {
            if (message.strip ().length == 0) {
                return defaultMessage;
            }
            return message;
        }

        private static Vala.Collections.Result<bool ?, GLib.Error> validate (bool cond,
                                                                             string message,
                                                                             string defaultMessage,
                                                                             bool argumentError) {
            if (cond) {
                return Vala.Collections.Result.ok<bool ?, GLib.Error> (true);
            }

            string finalMessage = normalizeMessage (message, defaultMessage);
            if (argumentError) {
                return Vala.Collections.Result.error<bool ?, GLib.Error> (
                    new PreconditionError.INVALID_ARGUMENT (finalMessage)
                );
            }
            return Vala.Collections.Result.error<bool ?, GLib.Error> (
                new PreconditionError.INVALID_STATE (finalMessage)
            );
        }

        /**
         * Checks argument preconditions.
         *
         * Example:
         * {{{
         *     var result = Preconditions.checkArgument (name.length > 0, "name must not be empty");
         *     if (result.isError ()) {
         *         return;
         *     }
         * }}}
         *
         * @param cond condition that must be true.
         * @param message error message when condition is false.
         * @return Result.ok(true) on success, or
         *         Result.error(PreconditionError.INVALID_ARGUMENT) when condition is false.
         */
        public static Vala.Collections.Result<bool ?, GLib.Error> checkArgument (bool cond, string message) {
            return validate (cond, message, "Invalid argument", true);
        }

        /**
         * Checks state preconditions.
         *
         * Example:
         * {{{
         *     var result = Preconditions.checkState (isOpen, "resource is closed");
         *     if (result.isError ()) {
         *         return;
         *     }
         * }}}
         *
         * @param cond condition that must be true.
         * @param message error message when condition is false.
         * @return Result.ok(true) on success, or
         *         Result.error(PreconditionError.INVALID_STATE) when condition is false.
         */
        public static Vala.Collections.Result<bool ?, GLib.Error> checkState (bool cond, string message) {
            return validate (cond, message, "Invalid state", false);
        }
    }
}
