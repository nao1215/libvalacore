/**
 * Vala.Lang namespace provides language-level utilities such as null checking and OS interfaces.
 */
namespace Vala.Lang {
    /**
     * Utility methods for nullable object checks.
     *
     * This class mirrors common helper methods such as java.util.Objects for
     * null testing and improves readability in guard clauses.
     *
     * Example:
     * {{{
     *     string? name = get_name ();
     *     if (Objects.isNull (name)) {
     *         return;
     *     }
     *     assert (Objects.nonNull (name));
     * }}}
     */
    public class Objects : GLib.Object {
        /**
         * Returns whether the object is null.
         * @param obj Object to be checked.
         * @return true: object is null, false: object is not null.
         */
        public static bool isNull<T> (T ? obj) {
            return obj == null;
        }

        /**
         * Returns whether the object is not null.
         * @param obj Object to be checked.
         * @return true: object is not null, false: object is null.
         */
        public static bool nonNull<T> (T ? obj) {
            return !isNull (obj);
        }
    }
}
