namespace Vala.Lang {
    /**
     * Thread utility methods.
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
