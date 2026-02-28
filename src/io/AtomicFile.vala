namespace Vala.Io {
    /**
     * Atomic file update helper.
     *
     * AtomicFile writes data by replacing file contents in a single step,
     * reducing risk of partial writes and corrupted configuration files.
     * Optional backup support keeps previous contents before replacement.
     *
     * Example:
     * {{{
     *     var atomic = new AtomicFile ()
     *         .withBackup (true)
     *         .backupSuffix (".bak");
     *
     *     bool ok = atomic.write (new Path ("/tmp/app.conf"), "port=8080\n");
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
         * @return this AtomicFile instance.
         */
        public AtomicFile backupSuffix (string suffix) {
            if (suffix.length == 0) {
                error ("suffix must not be empty");
            }
            _backup_suffix = suffix;
            return this;
        }

        /**
         * Writes text atomically to the destination path.
         *
         * Existing file content is replaced as a single operation.
         *
         * @param path destination file path.
         * @param text text content to write.
         * @return true on success.
         */
        public bool write (Path path, string text) {
            return writeBytes (path, text.data);
        }

        /**
         * Writes bytes atomically to the destination path.
         *
         * Existing file content is replaced as a single operation.
         *
         * @param path destination file path.
         * @param data byte array to write.
         * @return true on success.
         */
        public bool writeBytes (Path path, uint8[] data) {
            if (_backup_enabled && Files.exists (path)) {
                Path backupPath = new Path (path.toString () + _backup_suffix);
                if (!Files.copy (path, backupPath)) {
                    return false;
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
                return true;
            } catch (GLib.Error e) {
                return false;
            }
        }

        /**
         * Appends text by reading current content and writing merged content
         * atomically.
         *
         * @param path destination file path.
         * @param text text to append.
         * @return true on success.
         */
        public bool append (Path path, string text) {
            string current = "";
            if (Files.exists (path)) {
                string ? existing = readConsistent (path);
                if (existing == null) {
                    return false;
                }
                current = existing;
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
         * @return true on success.
         */
        public bool replace (Path srcTmp, Path dst) {
            if (!Files.isFile (srcTmp)) {
                return false;
            }

            if (_backup_enabled && Files.exists (dst)) {
                Path backupPath = new Path (dst.toString () + _backup_suffix);
                if (!Files.copy (dst, backupPath)) {
                    return false;
                }
            }

            try {
                var srcFile = GLib.File.new_for_path (srcTmp.toString ());
                var dstFile = GLib.File.new_for_path (dst.toString ());
                srcFile.move (dstFile, GLib.FileCopyFlags.OVERWRITE);
                return true;
            } catch (GLib.Error e) {
                return false;
            }
        }

        /**
         * Reads text with basic consistency validation.
         *
         * File is read twice and compared. If content or size changes between
         * reads, this method treats it as inconsistent and returns null.
         *
         * @param path target file path.
         * @return stable text content, or null if inconsistent/unreadable.
         */
        public string ? readConsistent (Path path) {
            if (!Files.isFile (path)) {
                return null;
            }

            string ? first = Files.readAllText (path);
            if (first == null) {
                return null;
            }
            int64 firstSize = Files.size (path);
            if (firstSize < 0) {
                return null;
            }

            string ? second = Files.readAllText (path);
            if (second == null) {
                return null;
            }
            int64 secondSize = Files.size (path);
            if (secondSize < 0) {
                return null;
            }

            if (first != second) {
                return null;
            }
            if (firstSize != secondSize) {
                return null;
            }

            uint8[] secondData = second.data;
            int secondByteLength = secondData.length;
            if (secondByteLength > 0 && secondData[secondByteLength - 1] == '\0') {
                secondByteLength--;
            }
            if ((int64) secondByteLength != secondSize) {
                return null;
            }
            return second;
        }
    }
}
