namespace Vala.Io {
    /**
     * Recoverable temp helper errors.
     */
    public errordomain TempError {
        CREATE_FAILED
    }

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
         * @return Result.ok(true) on success,
         *         Result.error(TempError.CREATE_FAILED) when temp file creation fails.
         */
        public static Vala.Collections.Result<bool, GLib.Error> withTempFile (TempFunc func) {
            Vala.Io.Path ? path = Files.tempFile ("valacore", ".tmp");
            if (path == null) {
                return Vala.Collections.Result.error<bool, GLib.Error> (
                    new TempError.CREATE_FAILED ("failed to create temporary file")
                );
            }

            try {
                func (path);
                return Vala.Collections.Result.ok<bool, GLib.Error> (true);
            } finally {
                Files.remove (path);
            }
        }

        /**
         * Creates a temporary directory, passes it to the callback, and removes it.
         *
         * @param func callback invoked with the temporary directory path.
         * @return Result.ok(true) on success,
         *         Result.error(TempError.CREATE_FAILED) when temp directory creation fails.
         */
        public static Vala.Collections.Result<bool, GLib.Error> withTempDir (TempFunc func) {
            Vala.Io.Path ? path = Files.tempDir ("valacore");
            if (path == null) {
                return Vala.Collections.Result.error<bool, GLib.Error> (
                    new TempError.CREATE_FAILED ("failed to create temporary directory")
                );
            }

            try {
                func (path);
                return Vala.Collections.Result.ok<bool, GLib.Error> (true);
            } finally {
                Files.deleteRecursive (path);
            }
        }
    }
}
