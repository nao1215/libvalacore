namespace Vala.Io {
    /**
     * Callback delegate used by temporary resource helpers.
     */
    public delegate void TempFunc (Vala.Io.Path path);

    /**
     * Temporary file and directory helpers.
     *
     * These helpers create temporary resources, pass their paths into a
     * callback, and always remove resources afterward (even when callback
     * throws/fails), making cleanup deterministic.
     */
    public class Temp : GLib.Object {
        /**
         * Creates a temporary file, passes it to the callback, and removes it.
         *
         * @param func callback invoked with the temporary file path.
         * @return true on success.
         */
        public static bool withTempFile (TempFunc func) {
            Vala.Io.Path ? path = Files.tempFile ("valacore", ".tmp");
            if (path == null) {
                return false;
            }

            try {
                func (path);
                return true;
            } finally {
                Files.remove (path);
            }
        }

        /**
         * Creates a temporary directory, passes it to the callback, and removes it.
         *
         * @param func callback invoked with the temporary directory path.
         * @return true on success.
         */
        public static bool withTempDir (TempFunc func) {
            Vala.Io.Path ? path = Files.tempDir ("valacore");
            if (path == null) {
                return false;
            }

            try {
                func (path);
                return true;
            } finally {
                Files.deleteRecursive (path);
            }
        }
    }
}
