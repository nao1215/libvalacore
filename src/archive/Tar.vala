using Vala.Collections;
using Vala.Io;
using Vala.Lang;

namespace Vala.Archive {
    /**
     * Error domain for tar archive operations.
     */
    public errordomain TarError {
        INVALID_ARGUMENT,
        NOT_FOUND,
        IO,
        SECURITY
    }

    /**
     * Static utility methods for Tar archive creation and extraction.
     */
    public class Tar : GLib.Object {
        private const int TAR_BLOCK_SIZE = 512;

        private class TarEntry : GLib.Object {
            public string name { get; private set; }
            public char typeflag { get; private set; }
            public string linkName { get; private set; }
            public int64 size { get; private set; }
            public int64 headerOffset { get; private set; }
            public int64 dataOffset { get; private set; }

            public TarEntry (string name,
                             char typeflag,
                             string linkName,
                             int64 size,
                             int64 headerOffset,
                             int64 dataOffset) {
                this.name = name;
                this.typeflag = typeflag;
                this.linkName = linkName;
                this.size = size;
                this.headerOffset = headerOffset;
                this.dataOffset = dataOffset;
            }

            public bool isRegularFile () {
                return typeflag == '\0' || typeflag == '0';
            }

            public bool isDirectory () {
                return typeflag == '5' || name.has_suffix ("/");
            }

            public bool isLink () {
                return typeflag == '1' || typeflag == '2';
            }
        }

        private class ParsedArchive : GLib.Object {
            public uint8[] bytes;
            public ArrayList<TarEntry> entries;
            public int64 contentEnd;

            public ParsedArchive (owned uint8[] bytes,
                                  ArrayList<TarEntry> entries,
                                  int64 contentEnd) {
                this.bytes = (owned) bytes;
                this.entries = entries;
                this.contentEnd = contentEnd;
            }
        }

        /**
         * Creates a tar archive from file list.
         *
         * @param archive destination archive path.
         * @param files source files.
         * @return Result.ok(true) on success, or Result.error(TarError) on failure.
         */
        public static Result<bool, GLib.Error> create (Vala.Io.Path archive, ArrayList<Vala.Io.Path> files) {
            if (Objects.isNull (archive) || Objects.isNull (files) || files.size () == 0) {
                return Result.error<bool, GLib.Error> (
                    new TarError.INVALID_ARGUMENT ("archive/files must not be null and files must not be empty")
                );
            }

            var basenames = new HashSet<string> (GLib.str_hash, GLib.str_equal);
            var output = new GLib.ByteArray ();
            bool hasFile = false;

            for (int i = 0; i < files.size (); i++) {
                Vala.Io.Path ? file = files.get (i);
                if (file == null || !Files.isFile (file)) {
                    continue;
                }

                string name = file.basename ();
                if (basenames.contains (name)) {
                    return Result.error<bool, GLib.Error> (
                        new TarError.INVALID_ARGUMENT ("duplicate basename is not allowed: %s".printf (name))
                    );
                }
                basenames.add (name);

                string archiveName = name;
                if (archiveName.has_prefix ("-")) {
                    archiveName = "./" + archiveName;
                }

                uint8[] ? fileBytes = Files.readBytes (file);
                if (fileBytes == null) {
                    return Result.error<bool, GLib.Error> (
                        new TarError.IO ("failed to read source file: %s".printf (file.toString ()))
                    );
                }

                var appended = appendRegularEntry (output, archiveName, fileBytes, 0644);
                if (appended.isError ()) {
                    return Result.error<bool, GLib.Error> (appended.unwrapError ());
                }
                hasFile = true;
            }

            if (!hasFile) {
                return Result.error<bool, GLib.Error> (
                    new TarError.NOT_FOUND ("no regular files were provided")
                );
            }

            appendEndBlocks (output);
            return writeArchiveBytes (archive, output.steal (), "failed to create tar archive");
        }

        /**
         * Creates a tar archive from all entries under directory.
         *
         * @param archive destination archive path.
         * @param dir source directory.
         * @return Result.ok(true) on success, or Result.error(TarError) on failure.
         */
        public static Result<bool, GLib.Error> createFromDir (Vala.Io.Path archive, Vala.Io.Path dir) {
            if (Objects.isNull (archive) || Objects.isNull (dir) || !Files.isDir (dir)) {
                string dir_text = Objects.isNull (dir) ? "<null>" : dir.toString ();
                return Result.error<bool, GLib.Error> (
                    new TarError.INVALID_ARGUMENT (
                        "archive and existing source directory are required: %s".printf (dir_text)
                    )
                );
            }

            var output = new GLib.ByteArray ();
            var rootHeader = appendDirectoryEntry (output, "./", 0755);
            if (rootHeader.isError ()) {
                return Result.error<bool, GLib.Error> (rootHeader.unwrapError ());
            }

            var appended = appendDirectoryTree (output, dir, "");
            if (appended.isError ()) {
                return Result.error<bool, GLib.Error> (appended.unwrapError ());
            }

            appendEndBlocks (output);
            return writeArchiveBytes (archive, output.steal (), "failed to create tar archive from directory");
        }

        /**
         * Extracts archive to destination directory.
         *
         * @param archive source archive path.
         * @param dest destination directory.
         * @return Result.ok(true) on success, or Result.error(TarError) on failure.
         */
        public static Result<bool, GLib.Error> extract (Vala.Io.Path archive, Vala.Io.Path dest) {
            if (Objects.isNull (archive) || Objects.isNull (dest)) {
                return Result.error<bool, GLib.Error> (
                    new TarError.INVALID_ARGUMENT ("archive and destination must not be null")
                );
            }
            if (!Files.isFile (archive)) {
                return Result.error<bool, GLib.Error> (
                    new TarError.NOT_FOUND ("archive does not exist: %s".printf (archive.toString ()))
                );
            }

            var ensureDest = ensureDestinationDir (dest);
            if (ensureDest.isError ()) {
                return Result.error<bool, GLib.Error> (ensureDest.unwrapError ());
            }

            var parsedResult = parseArchive (archive);
            if (parsedResult.isError ()) {
                return Result.error<bool, GLib.Error> (parsedResult.unwrapError ());
            }
            ParsedArchive parsed = parsedResult.unwrap ();

            for (int i = 0; i < parsed.entries.size (); i++) {
                TarEntry ? entry = parsed.entries.get (i);
                if (entry == null || !isSafeArchiveEntry (entry.name, dest)) {
                    return Result.error<bool, GLib.Error> (
                        new TarError.SECURITY (
                            "unsafe archive entry rejected: %s".printf (entry == null ? "<null>" : entry.name)
                        )
                    );
                }
                if (entry.isLink ()) {
                    return Result.error<bool, GLib.Error> (
                        new TarError.SECURITY ("archive contains symbolic/hard links: %s".printf (archive.toString ()))
                    );
                }
            }

            for (int i = 0; i < parsed.entries.size (); i++) {
                TarEntry ? entry = parsed.entries.get (i);
                if (entry == null) {
                    continue;
                }

                string relative = trimLeadingDotSlash (entry.name);
                Vala.Io.Path target = resolveArchiveEntryTarget (dest, relative);
                if (hasSymlinkComponent (dest, relative)) {
                    return Result.error<bool, GLib.Error> (
                        new TarError.SECURITY (
                            "archive extraction path traverses symlink component: %s".printf (entry.name)
                        )
                    );
                }

                if (entry.isDirectory ()) {
                    var ensured = ensureDirectoryPath (target);
                    if (ensured.isError ()) {
                        return Result.error<bool, GLib.Error> (ensured.unwrapError ());
                    }
                    continue;
                }

                if (!entry.isRegularFile ()) {
                    continue;
                }

                if (entry.size > int.MAX) {
                    return Result.error<bool, GLib.Error> (
                        new TarError.IO ("entry is too large to extract: %s".printf (entry.name))
                    );
                }

                int start = (int) entry.dataOffset;
                int end = (int) (entry.dataOffset + entry.size);
                uint8[] data = parsed.bytes[start : end];
                var replaced = replaceFileAtomically (
                    target,
                    data,
                    "failed to extract entry: %s".printf (entry.name)
                );
                if (replaced.isError ()) {
                    return Result.error<bool, GLib.Error> (replaced.unwrapError ());
                }
            }

            return Result.ok<bool, GLib.Error> (true);
        }

        /**
         * Lists all archive entries.
         *
         * @param archive source archive path.
         * @return Result.ok(entries) on success, or Result.error(TarError) on failure.
         */
        public static Result<ArrayList<string>, GLib.Error> list (Vala.Io.Path archive) {
            if (Objects.isNull (archive)) {
                return Result.error<ArrayList<string>, GLib.Error> (
                    new TarError.INVALID_ARGUMENT ("archive must not be null")
                );
            }
            if (!Files.isFile (archive)) {
                return Result.error<ArrayList<string>, GLib.Error> (
                    new TarError.NOT_FOUND ("archive does not exist: %s".printf (archive.toString ()))
                );
            }

            var parsedResult = parseArchive (archive);
            if (parsedResult.isError ()) {
                return Result.error<ArrayList<string>, GLib.Error> (parsedResult.unwrapError ());
            }

            var entries = new ArrayList<string> (GLib.str_equal);
            ArrayList<TarEntry> parsedEntries = parsedResult.unwrap ().entries;
            for (int i = 0; i < parsedEntries.size (); i++) {
                TarEntry ? entry = parsedEntries.get (i);
                if (entry != null && entry.name.strip ().length > 0) {
                    entries.add (entry.name);
                }
            }
            return Result.ok<ArrayList<string>, GLib.Error> (entries);
        }

        /**
         * Adds one file to an existing archive.
         *
         * @param archive archive path.
         * @param file file to add.
         * @return Result.ok(true) on success, or Result.error(TarError) on failure.
         */
        public static Result<bool, GLib.Error> addFile (Vala.Io.Path archive, Vala.Io.Path file) {
            if (Objects.isNull (archive) || Objects.isNull (file)) {
                return Result.error<bool, GLib.Error> (
                    new TarError.INVALID_ARGUMENT ("archive and file must not be null")
                );
            }
            if (!Files.isFile (archive)) {
                return Result.error<bool, GLib.Error> (
                    new TarError.NOT_FOUND ("archive does not exist: %s".printf (archive.toString ()))
                );
            }
            if (!Files.isFile (file)) {
                return Result.error<bool, GLib.Error> (
                    new TarError.NOT_FOUND ("file does not exist: %s".printf (file.toString ()))
                );
            }

            var parsedResult = parseArchive (archive);
            if (parsedResult.isError ()) {
                return Result.error<bool, GLib.Error> (parsedResult.unwrapError ());
            }
            ParsedArchive parsed = parsedResult.unwrap ();

            uint8[] ? fileBytes = Files.readBytes (file);
            if (fileBytes == null) {
                return Result.error<bool, GLib.Error> (
                    new TarError.IO ("failed to read file to append: %s".printf (file.toString ()))
                );
            }

            string entryName = file.basename ();
            if (entryName.has_prefix ("-")) {
                entryName = "./" + entryName;
            }
            string normalizedEntryName = trimLeadingDotSlash (entryName);
            for (int i = 0; i < parsed.entries.size (); i++) {
                TarEntry ? existing = parsed.entries.get (i);
                if (existing == null) {
                    continue;
                }
                if (trimLeadingDotSlash (existing.name) == normalizedEntryName) {
                    return Result.error<bool, GLib.Error> (
                        new TarError.INVALID_ARGUMENT (
                            "archive entry already exists: %s".printf (entryName)
                        )
                    );
                }
            }

            var output = new GLib.ByteArray ();
            output.append (parsed.bytes[0 : (int) parsed.contentEnd]);
            var appended = appendRegularEntry (output, entryName, fileBytes, 0644);
            if (appended.isError ()) {
                return Result.error<bool, GLib.Error> (appended.unwrapError ());
            }
            appendEndBlocks (output);

            return writeArchiveBytes (
                archive,
                output.steal (),
                "failed to append file to archive: archive=%s file=%s".printf (archive.toString (), file.toString ())
            );
        }

        /**
         * Extracts one archive entry into destination file path.
         *
         * @param archive archive path.
         * @param entry archive entry path.
         * @param dest destination file path.
         * @return Result.ok(true) on success, or Result.error(TarError) on failure.
         */
        public static Result<bool, GLib.Error> extractFile (Vala.Io.Path archive,
                                                            string entry,
                                                            Vala.Io.Path dest) {
            if (Objects.isNull (archive) || Objects.isNull (dest) || entry.strip ().length == 0) {
                return Result.error<bool, GLib.Error> (
                    new TarError.INVALID_ARGUMENT ("archive, entry and destination must be valid")
                );
            }
            if (!Files.isFile (archive)) {
                return Result.error<bool, GLib.Error> (
                    new TarError.NOT_FOUND ("archive does not exist: %s".printf (archive.toString ()))
                );
            }

            var parsedResult = parseArchive (archive);
            if (parsedResult.isError ()) {
                return Result.error<bool, GLib.Error> (parsedResult.unwrapError ());
            }
            ParsedArchive parsed = parsedResult.unwrap ();

            string targetEntry = trimLeadingDotSlash (entry);
            TarEntry ? matchedEntry = null;

            for (int i = 0; i < parsed.entries.size (); i++) {
                TarEntry ? current = parsed.entries.get (i);
                if (current == null) {
                    continue;
                }
                if (trimLeadingDotSlash (current.name) == targetEntry) {
                    matchedEntry = current;
                    break;
                }
            }

            if (matchedEntry == null) {
                return Result.error<bool, GLib.Error> (
                    new TarError.NOT_FOUND ("entry not found: entry=%s archive=%s".printf (entry, archive.toString ()))
                );
            }

            if (matchedEntry.isLink ()) {
                return Result.error<bool, GLib.Error> (
                    new TarError.SECURITY ("entry is a symbolic/hard link: %s".printf (matchedEntry.name))
                );
            }
            if (!matchedEntry.isRegularFile ()) {
                return Result.error<bool, GLib.Error> (
                    new TarError.INVALID_ARGUMENT ("entry is not a regular file: %s".printf (matchedEntry.name))
                );
            }

            if (matchedEntry.size > int.MAX) {
                return Result.error<bool, GLib.Error> (
                    new TarError.IO ("entry is too large to extract: %s".printf (matchedEntry.name))
                );
            }

            int start = (int) matchedEntry.dataOffset;
            int end = (int) (matchedEntry.dataOffset + matchedEntry.size);
            uint8[] payload = parsed.bytes[start : end];

            return replaceFileAtomically (
                dest,
                payload,
                "failed to extract entry: %s".printf (matchedEntry.name)
            );
        }

        private static Result<bool, GLib.Error> appendDirectoryTree (GLib.ByteArray output,
                                                                     Vala.Io.Path currentDir,
                                                                     string relativeDir) {
            GLib.List<string> ? names = Files.listDir (currentDir);
            if (names == null) {
                return Result.error<bool, GLib.Error> (
                    new TarError.IO ("failed to list source directory: %s".printf (currentDir.toString ()))
                );
            }
            names.sort ((a, b) => {
                return a.collate (b);
            });

            foreach (string name in names) {
                Vala.Io.Path child = currentDir.resolve (name);
                string relativePath = relativeDir.length == 0 ? name : relativeDir + "/" + name;
                string archiveEntry = "./" + relativePath;

                if (Files.isSymbolicFile (child)) {
                    Vala.Io.Path ? linkTarget = Files.readSymlink (child);
                    if (linkTarget == null) {
                        return Result.error<bool, GLib.Error> (
                            new TarError.IO ("failed to read symbolic link: %s".printf (child.toString ()))
                        );
                    }
                    var linkAppended = appendSymlinkEntry (output, archiveEntry, linkTarget.toString ());
                    if (linkAppended.isError ()) {
                        return Result.error<bool, GLib.Error> (linkAppended.unwrapError ());
                    }
                    continue;
                }

                if (Files.isDir (child)) {
                    var dirAppended = appendDirectoryEntry (output, archiveEntry + "/", 0755);
                    if (dirAppended.isError ()) {
                        return Result.error<bool, GLib.Error> (dirAppended.unwrapError ());
                    }
                    var nested = appendDirectoryTree (output, child, relativePath);
                    if (nested.isError ()) {
                        return Result.error<bool, GLib.Error> (nested.unwrapError ());
                    }
                    continue;
                }

                if (!Files.isFile (child)) {
                    continue;
                }

                uint8[] ? fileBytes = Files.readBytes (child);
                if (fileBytes == null) {
                    return Result.error<bool, GLib.Error> (
                        new TarError.IO ("failed to read source file: %s".printf (child.toString ()))
                    );
                }

                var fileAppended = appendRegularEntry (output, archiveEntry, fileBytes, 0644);
                if (fileAppended.isError ()) {
                    return Result.error<bool, GLib.Error> (fileAppended.unwrapError ());
                }
            }

            return Result.ok<bool, GLib.Error> (true);
        }

        private static Result<bool, GLib.Error> appendRegularEntry (GLib.ByteArray output,
                                                                    string entryName,
                                                                    uint8[] data,
                                                                    int mode) {
            var headerResult = buildHeader (entryName, '0', data.length, "", mode);
            if (headerResult.isError ()) {
                return Result.error<bool, GLib.Error> (headerResult.unwrapError ());
            }
            output.append (headerResult.unwrap ().get_data ());
            output.append (data);

            int padding = (int) ((TAR_BLOCK_SIZE - (data.length % TAR_BLOCK_SIZE)) % TAR_BLOCK_SIZE);
            if (padding > 0) {
                output.append (new uint8[padding]);
            }
            return Result.ok<bool, GLib.Error> (true);
        }

        private static Result<bool, GLib.Error> appendDirectoryEntry (GLib.ByteArray output,
                                                                      string entryName,
                                                                      int mode) {
            var headerResult = buildHeader (entryName, '5', 0, "", mode);
            if (headerResult.isError ()) {
                return Result.error<bool, GLib.Error> (headerResult.unwrapError ());
            }
            output.append (headerResult.unwrap ().get_data ());
            return Result.ok<bool, GLib.Error> (true);
        }

        private static Result<bool, GLib.Error> appendSymlinkEntry (GLib.ByteArray output,
                                                                    string entryName,
                                                                    string linkTarget) {
            var headerResult = buildHeader (entryName, '2', 0, linkTarget, 0777);
            if (headerResult.isError ()) {
                return Result.error<bool, GLib.Error> (headerResult.unwrapError ());
            }
            output.append (headerResult.unwrap ().get_data ());
            return Result.ok<bool, GLib.Error> (true);
        }

        private static Result<GLib.Bytes, GLib.Error> buildHeader (string name,
                                                                   char typeflag,
                                                                   int64 size,
                                                                   string linkName,
                                                                   int mode) {
            if (name.strip ().length == 0) {
                return Result.error<GLib.Bytes, GLib.Error> (
                    new TarError.INVALID_ARGUMENT ("tar entry name must not be empty")
                );
            }
            if (size < 0) {
                return Result.error<GLib.Bytes, GLib.Error> (
                    new TarError.INVALID_ARGUMENT ("tar entry size must not be negative")
                );
            }

            uint8[] header = new uint8[TAR_BLOCK_SIZE];
            if (!writeNameField (header, name)) {
                return Result.error<GLib.Bytes, GLib.Error> (
                    new TarError.INVALID_ARGUMENT ("tar entry name is too long: %s".printf (name))
                );
            }
            if (typeflag == '2' && !writeAsciiField (header, 157, 100, linkName)) {
                return Result.error<GLib.Bytes, GLib.Error> (
                    new TarError.INVALID_ARGUMENT ("tar link target is too long: %s".printf (linkName))
                );
            }

            writeOctalField (header, 100, 8, mode);
            writeOctalField (header, 108, 8, 0);
            writeOctalField (header, 116, 8, 0);
            writeOctalField (header, 124, 12, size);
            writeOctalField (header, 136, 12, 0);
            header[156] = (uint8) typeflag;
            writeAsciiField (header, 257, 6, "ustar");
            writeAsciiField (header, 263, 2, "00");
            writeChecksumField (header);
            return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (header));
        }

        private static bool writeNameField (uint8[] header, string rawName) {
            string name = rawName;
            bool hadTrailingSlash = name.has_suffix ("/");
            if (name.length > 1 && hadTrailingSlash) {
                name = name.substring (0, name.length - 1);
            }
            if (name.length <= 100) {
                string encoded = hadTrailingSlash && !name.has_suffix ("/") ? name + "/" : name;
                return writeAsciiField (header, 0, 100, encoded);
            }

            int slashIndex = -1;
            for (int i = 0; i < name.length; i++) {
                if (name[i] == '/') {
                    string prefix = name.substring (0, i);
                    string baseName = name.substring (i + 1);
                    if (hadTrailingSlash) {
                        baseName += "/";
                    }
                    if (prefix.length <= 155 && baseName.length <= 100) {
                        slashIndex = i;
                    }
                }
            }

            if (slashIndex < 0) {
                return false;
            }

            string prefixPart = name.substring (0, slashIndex);
            string namePart = name.substring (slashIndex + 1);
            if (hadTrailingSlash) {
                namePart += "/";
            }

            return writeAsciiField (header, 0, 100, namePart)
                   && writeAsciiField (header, 345, 155, prefixPart);
        }

        private static bool writeAsciiField (uint8[] header,
                                             int offset,
                                             int width,
                                             string value) {
            if (value.length > width) {
                return false;
            }
            for (int i = 0; i < value.length; i++) {
                header[offset + i] = (uint8) value[i];
            }
            return true;
        }

        private static void writeOctalField (uint8[] header,
                                             int offset,
                                             int width,
                                             int64 value) {
            int digitsWidth = width - 1;
            string octal = toOctalString (value);
            if (octal.length > digitsWidth) {
                octal = octal.substring (octal.length - digitsWidth);
            }
            int pad = digitsWidth - octal.length;
            for (int i = 0; i < pad; i++) {
                header[offset + i] = (uint8) '0';
            }
            for (int i = 0; i < octal.length; i++) {
                header[offset + pad + i] = (uint8) octal[i];
            }
            header[offset + width - 1] = 0;
        }

        private static void writeChecksumField (uint8[] header) {
            for (int i = 0; i < 8; i++) {
                header[148 + i] = (uint8) ' ';
            }

            int64 sum = 0;
            for (int i = 0; i < TAR_BLOCK_SIZE; i++) {
                sum += header[i];
            }

            string octal = toOctalString (sum);
            if (octal.length > 6) {
                octal = octal.substring (octal.length - 6);
            }
            int pad = 6 - octal.length;
            for (int i = 0; i < pad; i++) {
                header[148 + i] = (uint8) '0';
            }
            for (int i = 0; i < octal.length; i++) {
                header[148 + pad + i] = (uint8) octal[i];
            }
            header[154] = 0;
            header[155] = (uint8) ' ';
        }

        private static string toOctalString (int64 value) {
            if (value <= 0) {
                return "0";
            }
            string out = "";
            int64 current = value;
            while (current > 0) {
                int digit = (int) (current & 7);
                out = ((char) ('0' + digit)).to_string () + out;
                current >>= 3;
            }
            return out;
        }

        private static void appendEndBlocks (GLib.ByteArray output) {
            output.append (new uint8[TAR_BLOCK_SIZE]);
            output.append (new uint8[TAR_BLOCK_SIZE]);
        }

        private static Result<bool, GLib.Error> writeArchiveBytes (Vala.Io.Path archive,
                                                                   uint8[] bytes,
                                                                   string errorContext) {
            if (Files.exists (archive) && !Files.remove (archive)) {
                return Result.error<bool, GLib.Error> (
                    new TarError.IO ("failed to remove existing archive: %s".printf (archive.toString ()))
                );
            }
            if (!Files.writeBytes (archive, bytes)) {
                return Result.error<bool, GLib.Error> (
                    new TarError.IO ("%s: %s".printf (errorContext, archive.toString ()))
                );
            }
            return Result.ok<bool, GLib.Error> (true);
        }

        private static Result<ParsedArchive, GLib.Error> parseArchive (Vala.Io.Path archive) {
            uint8[] ? bytes = Files.readBytes (archive);
            if (bytes == null) {
                return Result.error<ParsedArchive, GLib.Error> (
                    new TarError.IO ("failed to read archive: %s".printf (archive.toString ()))
                );
            }
            if (bytes.length % TAR_BLOCK_SIZE != 0) {
                return Result.error<ParsedArchive, GLib.Error> (
                    new TarError.IO ("invalid tar archive size: %s".printf (archive.toString ()))
                );
            }

            var entries = new ArrayList<TarEntry> ();
            int64 offset = 0;
            int64 contentEnd = 0;

            while (offset + TAR_BLOCK_SIZE <= bytes.length) {
                if (isZeroBlock (bytes, offset)) {
                    break;
                }

                bool checksumValid = hasValidHeaderChecksum (bytes, offset);
                if (!checksumValid) {
                    return Result.error<ParsedArchive, GLib.Error> (
                        new TarError.IO ("invalid tar header checksum: %s".printf (archive.toString ()))
                    );
                }

                string name = readHeaderString (bytes, offset + 0, 100);
                string prefix = readHeaderString (bytes, offset + 345, 155);
                if (prefix.length > 0) {
                    name = prefix + "/" + name;
                }
                if (name.strip ().length == 0) {
                    return Result.error<ParsedArchive, GLib.Error> (
                        new TarError.IO ("invalid tar entry name: %s".printf (archive.toString ()))
                    );
                }

                int64 size = 0;
                if (!parseOctalField (bytes, offset + 124, 12, out size) || size < 0) {
                    return Result.error<ParsedArchive, GLib.Error> (
                        new TarError.IO ("invalid tar entry size: %s".printf (archive.toString ()))
                    );
                }

                char typeflag = (char) bytes[(int) (offset + 156)];
                string linkName = readHeaderString (bytes, offset + 157, 100);
                int64 dataSize = size;
                int64 paddedDataSize = alignToBlockSize (dataSize);

                if (offset + TAR_BLOCK_SIZE + paddedDataSize > bytes.length) {
                    return Result.error<ParsedArchive, GLib.Error> (
                        new TarError.IO ("tar archive is truncated: %s".printf (archive.toString ()))
                    );
                }

                entries.add (new TarEntry (
                                 name,
                                 typeflag,
                                 linkName,
                                 size,
                                 offset,
                                 offset + TAR_BLOCK_SIZE
                ));

                offset += TAR_BLOCK_SIZE + paddedDataSize;
                contentEnd = offset;
            }

            return Result.ok<ParsedArchive, GLib.Error> (
                new ParsedArchive ((owned) bytes, entries, contentEnd)
            );
        }

        private static bool hasValidHeaderChecksum (uint8[] bytes, int64 headerOffset) {
            int64 stored = 0;
            if (!parseOctalField (bytes, headerOffset + 148, 8, out stored)) {
                return false;
            }

            int64 sum = 0;
            for (int i = 0; i < TAR_BLOCK_SIZE; i++) {
                if (i >= 148 && i < 156) {
                    sum += ' ';
                } else {
                    sum += bytes[(int) (headerOffset + i)];
                }
            }
            return sum == stored;
        }

        private static bool parseOctalField (uint8[] bytes,
                                             int64 offset,
                                             int width,
                                             out int64 value) {
            value = 0;
            bool started = false;

            for (int i = 0; i < width; i++) {
                uint8 raw = bytes[(int) (offset + i)];
                if (raw == 0 || raw == ' ') {
                    if (started) {
                        bool onlyPadding = true;
                        for (int j = i + 1; j < width; j++) {
                            uint8 rest = bytes[(int) (offset + j)];
                            if (rest != 0 && rest != ' ') {
                                onlyPadding = false;
                                break;
                            }
                        }
                        if (!onlyPadding) {
                            return false;
                        }
                        break;
                    }
                    continue;
                }

                if (raw < '0' || raw > '7') {
                    return false;
                }
                started = true;

                if (value > (int64.MAX >> 3)) {
                    return false;
                }
                value = (value << 3) + (raw - '0');
            }

            return true;
        }

        private static string readHeaderString (uint8[] bytes,
                                                int64 offset,
                                                int width) {
            var builder = new GLib.StringBuilder ();
            for (int i = 0; i < width; i++) {
                uint8 raw = bytes[(int) (offset + i)];
                if (raw == 0) {
                    break;
                }
                builder.append_c ((char) raw);
            }
            return builder.str;
        }

        private static bool isZeroBlock (uint8[] bytes, int64 offset) {
            for (int i = 0; i < TAR_BLOCK_SIZE; i++) {
                if (bytes[(int) (offset + i)] != 0) {
                    return false;
                }
            }
            return true;
        }

        private static int64 alignToBlockSize (int64 n) {
            if (n <= 0) {
                return 0;
            }
            int64 rem = n % TAR_BLOCK_SIZE;
            if (rem == 0) {
                return n;
            }
            return n + (TAR_BLOCK_SIZE - rem);
        }

        private static Result<bool, GLib.Error> ensureDestinationDir (Vala.Io.Path dest) {
            if (Files.exists (dest) && Files.isSymbolicFile (dest)) {
                return Result.error<bool, GLib.Error> (
                    new TarError.SECURITY ("destination must not be a symbolic link: %s".printf (dest.toString ()))
                );
            }
            if (!Files.exists (dest)) {
                if (!Files.makeDirs (dest)) {
                    return Result.error<bool, GLib.Error> (
                        new TarError.IO ("failed to create destination directory: %s".printf (dest.toString ()))
                    );
                }
            } else if (!Files.isDir (dest)) {
                return Result.error<bool, GLib.Error> (
                    new TarError.INVALID_ARGUMENT ("destination must be a directory: %s".printf (dest.toString ()))
                );
            } else if (!Files.canWrite (dest)) {
                return Result.error<bool, GLib.Error> (
                    new TarError.INVALID_ARGUMENT (
                        "destination directory is not writable: %s".printf (dest.toString ())
                    )
                );
            }
            return Result.ok<bool, GLib.Error> (true);
        }

        private static Result<bool, GLib.Error> ensureDirectoryPath (Vala.Io.Path dirPath) {
            if (Files.exists (dirPath)) {
                if (Files.isSymbolicFile (dirPath)) {
                    return Result.error<bool, GLib.Error> (
                        new TarError.SECURITY ("directory path is symbolic link: %s".printf (dirPath.toString ()))
                    );
                }
                if (!Files.isDir (dirPath)) {
                    return Result.error<bool, GLib.Error> (
                        new TarError.IO ("destination path is not a directory: %s".printf (dirPath.toString ()))
                    );
                }
                return Result.ok<bool, GLib.Error> (true);
            }

            if (!Files.makeDirs (dirPath)) {
                return Result.error<bool, GLib.Error> (
                    new TarError.IO ("failed to create directory: %s".printf (dirPath.toString ()))
                );
            }
            return Result.ok<bool, GLib.Error> (true);
        }

        private static Result<bool, GLib.Error> replaceFileAtomically (Vala.Io.Path dest,
                                                                       uint8[] data,
                                                                       string failurePrefix) {
            Vala.Io.Path parent = dest.parent ();
            if (Files.exists (parent)) {
                if (Files.isSymbolicFile (parent)) {
                    return Result.error<bool, GLib.Error> (
                        new TarError.SECURITY ("destination parent is symbolic link: %s".printf (parent.toString ()))
                    );
                }
                if (!Files.isDir (parent)) {
                    return Result.error<bool, GLib.Error> (
                        new TarError.INVALID_ARGUMENT (
                            "destination parent is not a directory: %s".printf (parent.toString ())
                        )
                    );
                }
                if (!Files.canWrite (parent)) {
                    return Result.error<bool, GLib.Error> (
                        new TarError.INVALID_ARGUMENT (
                            "destination parent is not writable: %s".printf (parent.toString ())
                        )
                    );
                }
            } else if (!Files.makeDirs (parent)) {
                return Result.error<bool, GLib.Error> (
                    new TarError.IO ("failed to create parent directory: %s".printf (parent.toString ()))
                );
            }

            if (Files.exists (dest) && Files.isSymbolicFile (dest)) {
                return Result.error<bool, GLib.Error> (
                    new TarError.SECURITY ("destination file is symbolic link: %s".printf (dest.toString ()))
                );
            }
            if (Files.exists (dest) && Files.isDir (dest)) {
                return Result.error<bool, GLib.Error> (
                    new TarError.SECURITY ("destination file is a directory: %s".printf (dest.toString ()))
                );
            }

            Vala.Io.Path temp = parent.resolve (".tar-write-%s.tmp".printf (GLib.Uuid.string_random ()));
            if (!Files.writeBytes (temp, data)) {
                return Result.error<bool, GLib.Error> (
                    new TarError.IO ("%s: failed to write temp file".printf (failurePrefix))
                );
            }

            bool hadDest = Files.exists (dest);
            Vala.Io.Path backup = parent.resolve (".tar-backup-%s.tmp".printf (GLib.Uuid.string_random ()));
            if (hadDest && !Files.move (dest, backup)) {
                Files.remove (temp);
                return Result.error<bool, GLib.Error> (
                    new TarError.IO ("%s: failed to backup destination".printf (failurePrefix))
                );
            }

            if (!Files.move (temp, dest)) {
                string message = "%s: failed to move temp file to destination".printf (failurePrefix);
                if (hadDest && Files.exists (backup)) {
                    if (!Files.move (backup, dest)) {
                        Files.remove (temp);
                        return Result.error<bool, GLib.Error> (
                            new TarError.IO ("%s; rollback failed".printf (message))
                        );
                    }
                }
                Files.remove (temp);
                return Result.error<bool, GLib.Error> (
                    new TarError.IO (message)
                );
            }

            if (hadDest && Files.exists (backup)) {
                Files.remove (backup);
            }
            return Result.ok<bool, GLib.Error> (true);
        }

        private static string trimLeadingDotSlash (string value) {
            string out = value;
            while (out.has_prefix ("./")) {
                out = out.substring (2);
            }
            return out;
        }

        private static Vala.Io.Path resolveArchiveEntryTarget (Vala.Io.Path dest, string relative) {
            if (relative.length == 0 || relative == ".") {
                return dest;
            }
            return dest.resolve (relative);
        }

        private static bool hasSymlinkComponent (Vala.Io.Path dest, string relative) {
            if (Files.exists (dest) && Files.isSymbolicFile (dest)) {
                return true;
            }

            string normalized = trimLeadingDotSlash (relative);
            if (normalized.length == 0 || normalized == ".") {
                return false;
            }

            string[] parts = normalized.split ("/");
            Vala.Io.Path cursor = dest;
            for (int i = 0; i < parts.length; i++) {
                string part = parts[i];
                if (part.length == 0 || part == ".") {
                    continue;
                }
                cursor = cursor.resolve (part);
                if (Files.exists (cursor) && Files.isSymbolicFile (cursor)) {
                    return true;
                }
            }
            return false;
        }

        private static bool isSafeArchiveEntry (string entry, Vala.Io.Path dest) {
            string trimmed = entry.strip ();
            if (trimmed.length == 0 || trimmed.has_prefix ("/")) {
                return false;
            }

            string[] parts = trimmed.split ("/");
            for (int i = 0; i < parts.length; i++) {
                if (parts[i] == "..") {
                    return false;
                }
            }

            string basePath = dest.normalize ().toString ();
            string resolved = dest.resolve (trimmed).normalize ().toString ();
            if (basePath == "/") {
                return resolved.has_prefix ("/");
            }
            if (basePath == ".") {
                return resolved == "."
                       || !(resolved == ".." || resolved.has_prefix ("../"));
            }
            if (resolved == basePath) {
                return true;
            }
            return resolved.has_prefix (basePath + "/");
        }
    }
}
