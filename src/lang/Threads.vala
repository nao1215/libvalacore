namespace Vala.Lang {
    /**
     * Thread utility methods.
     *
     * This class provides small helpers around common thread operations.
     * Use this helper when you need simple sleep behavior without directly
     * dealing with microsecond conversions.
     *
     * Example:
     * {{{
     *     // Back off for 50ms before retrying.
     *     Threads.sleepMillis (50);
     * }}}
     */
    public class Threads : GLib.Object {
        /**
         * Sleeps current thread for milliseconds.
         *
         * @param ms sleep time in milliseconds.
         */
        public static void sleepMillis (int ms) {
            if (ms <= 0) {
                return;
            }
            Thread.usleep ((ulong) ms * 1000);
        }
    }
}
