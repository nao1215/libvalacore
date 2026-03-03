using Vala.Collections;
namespace Vala.Io {
    /**
     * Recoverable AtomicFile argument errors.
     */
    public errordomain AtomicFileError {
        INVALID_ARGUMENT,
        NOT_FOUND,
        IO
    }

    /**
     * Atomic file update helper.
     *
     * AtomicFile writes data by replacing file contents in a single step,
     * reducing risk of partial writes and corrupted configuration files.
     * Optional backup support keeps previous contents before replacement.
     *
     * Example:
     * {{{
     *     var configured = new AtomicFile ()
     *         .withBackup (true)
     *         .backupSuffix (".bak");
     *     assert (configured.isOk ());
     *     var atomic = configured.unwrap ();
     *
     *     var wrote = atomic.write (new Path ("/tmp/app.conf"), "port=8080\n");
     *     assert (wrote.isOk ());
     * }}}
     */
    public class AtomicFile : GLib.Object {
        private bool _backup_enabled = false;
        private string _backup_suffix = ".bak";

        /**
         * Creates an AtomicFile instance with default settings.
         */
        public AtomicFile () {
        }

        /**
         * Enables or disables backup creation before replacement.
         *
         * @param enabled true to create backup files during replace/write.
         * @return this AtomicFile instance.
         */
        public AtomicFile withBackup (bool enabled) {
            _backup_enabled = enabled;
            return this;
        }

        /**
         * Sets backup suffix used when backup is enabled.
         *
         * @param suffix backup suffix such as ".bak".
         * @return Result.ok(this AtomicFile instance) or
         *         Result.error(AtomicFileError.INVALID_ARGUMENT) when suffix is empty.
         */
        public Vala.Collections.Result<AtomicFile, GLib.Error> backupSuffix (string suffix) {
            if (suffix.length == 0) {
                return Vala.Collections.Result.error<AtomicFile, GLib.Error> (
                    new AtomicFileError.INVALID_ARGUMENT ("suffix must not be empty")
                );
            }
            _backup_suffix = suffix;
            return Vala.Collections.Result.ok<AtomicFile, GLib.Error> (this);
        }

        /**
         * Writes text atomically to the destination path.
         *
         * Existing file content is replaced as a single operation.
         *
         * @param path destination file path.
         * @param text text content to write.
         * @return Result.ok(true) on success, or
         *         Result.error(AtomicFileError.*) on failure.
         */
        public Vala.Collections.Result<bool, GLib.Error> write (Path path, string text) {
            return writeBytes (path, text.data);
        }

        /**
         * Writes bytes atomically to the destination path.
         *
         * Existing file content is replaced as a single operation.
         *
         * @param path destination file path.
         * @param data byte array to write.
         * @return Result.ok(true) on success, or
         *         Result.error(AtomicFileError.*) on failure.
         */
        public Vala.Collections.Result<bool, GLib.Error> writeBytes (Path path, uint8[] data) {
            if (_backup_enabled && Files.exists (path)) {
                Path backupPath = new Path (path.toString () + _backup_suffix);
                if (!Files.copy (path, backupPath)) {
                    return Vala.Collections.Result.error<bool, GLib.Error> (
                        new AtomicFileError.IO (
                            "failed to create backup file: %s".printf (backupPath.toString ())
                        )
                    );
                }
            }

            var file = GLib.File.new_for_path (path.toString ());
            try {
                string ? newEtag;
                file.replace_contents (
                    data,
                    null,
                    false,
                    GLib.FileCreateFlags.NONE,
                    out newEtag,
                    null
                );
                return Vala.Collections.Result.ok<bool, GLib.Error> (true);
            } catch (GLib.Error e) {
                return Vala.Collections.Result.error<bool, GLib.Error> (
                    new AtomicFileError.IO (
                        "failed to write file atomically: %s (%s)".printf (path.toString (), e.message)
                    )
                );
            }
        }

        /**
         * Appends text by reading current content and writing merged content
         * atomically.
         *
         * @param path destination file path.
         * @param text text to append.
         * @return Result.ok(true) on success, or
         *         Result.error(AtomicFileError.*) on failure.
         */
        public Vala.Collections.Result<bool, GLib.Error> append (Path path, string text) {
            string current = "";
            if (Files.exists (path)) {
                var consistent = readConsistent (path);
                if (consistent.isError ()) {
                    return Vala.Collections.Result.error<bool, GLib.Error> (consistent.unwrapError ());
                }
                current = consistent.unwrap ();
            }
            return write (path, current + text);
        }

        /**
         * Replaces destination with source temporary file.
         *
         * If backup mode is enabled and destination exists, destination is
         * copied to destination + backupSuffix before replacement.
         *
         * @param srcTmp source temporary file path.
         * @param dst destination file path.
         * @return Result.ok(true) on success, or
         *         Result.error(AtomicFileError.*) on failure.
         */
        public Vala.Collections.Result<bool, GLib.Error> replace (Path srcTmp, Path dst) {
            if (!Files.isFile (srcTmp)) {
                return Vala.Collections.Result.error<bool, GLib.Error> (
                    new AtomicFileError.NOT_FOUND (
                        "source temporary file not found: %s".printf (srcTmp.toString ())
                    )
                );
            }

            if (_backup_enabled && Files.exists (dst)) {
                Path backupPath = new Path (dst.toString () + _backup_suffix);
                if (!Files.copy (dst, backupPath)) {
                    return Vala.Collections.Result.error<bool, GLib.Error> (
                        new AtomicFileError.IO (
                            "failed to create backup file: %s".printf (backupPath.toString ())
                        )
                    );
                }
            }

            try {
                var srcFile = GLib.File.new_for_path (srcTmp.toString ());
                var dstFile = GLib.File.new_for_path (dst.toString ());
                srcFile.move (dstFile, GLib.FileCopyFlags.OVERWRITE);
                return Vala.Collections.Result.ok<bool, GLib.Error> (true);
            } catch (GLib.Error e) {
                return Vala.Collections.Result.error<bool, GLib.Error> (
                    new AtomicFileError.IO (
                        "failed to replace file: %s -> %s (%s)".printf (
                            srcTmp.toString (),
                            dst.toString (),
                            e.message
                        )
                    )
                );
            }
        }

        /**
         * Reads text with basic consistency validation.
         *
         * File is read twice and compared. If content or size changes between
         * reads, this method treats it as inconsistent and returns null.
         *
         * @param path target file path.
         * @return Result.ok(stable text content), or
         *         Result.error(AtomicFileError.NOT_FOUND / AtomicFileError.IO) on failure.
         */
        public Vala.Collections.Result<string, GLib.Error> readConsistent (Path path) {
            if (!Files.isFile (path)) {
                return Vala.Collections.Result.error<string, GLib.Error> (
                    new AtomicFileError.NOT_FOUND ("file not found: %s".printf (path.toString ()))
                );
            }

            string ? first = Files.readAllText (path);
            if (first == null) {
                return Vala.Collections.Result.error<string, GLib.Error> (
                    new AtomicFileError.IO ("failed to read file: %s".printf (path.toString ()))
                );
            }
            int64 firstSize = Files.size (path);
            if (firstSize < 0) {
                return Vala.Collections.Result.error<string, GLib.Error> (
                    new AtomicFileError.IO ("failed to stat file: %s".printf (path.toString ()))
                );
            }

            string ? second = Files.readAllText (path);
            if (second == null) {
                return Vala.Collections.Result.error<string, GLib.Error> (
                    new AtomicFileError.IO ("failed to re-read file: %s".printf (path.toString ()))
                );
            }
            int64 secondSize = Files.size (path);
            if (secondSize < 0) {
                return Vala.Collections.Result.error<string, GLib.Error> (
                    new AtomicFileError.IO ("failed to restat file: %s".printf (path.toString ()))
                );
            }

            if (first != second) {
                return Vala.Collections.Result.error<string, GLib.Error> (
                    new AtomicFileError.IO (
                        "inconsistent file contents detected: %s".printf (path.toString ())
                    )
                );
            }
            if (firstSize != secondSize) {
                return Vala.Collections.Result.error<string, GLib.Error> (
                    new AtomicFileError.IO ("inconsistent file size detected: %s".printf (path.toString ()))
                );
            }

            uint8[] secondData = second.data;
            int secondByteLength = secondData.length;
            if (secondByteLength > 0 && secondData[secondByteLength - 1] == '\0') {
                secondByteLength--;
            }
            if ((int64) secondByteLength != secondSize) {
                return Vala.Collections.Result.error<string, GLib.Error> (
                    new AtomicFileError.IO (
                        "inconsistent byte length detected: %s".printf (path.toString ())
                    )
                );
            }
            return Vala.Collections.Result.ok<string, GLib.Error> (second);
        }
    }
}
