using Vala.Collections;
using Vala.Io;
using Vala.Lang;

namespace Vala.Archive {
    /**
     * Error domain for zip archive operations.
     */
    public errordomain ZipError {
        INVALID_ARGUMENT,
        NOT_FOUND,
        IO,
        SECURITY
    }

    /**
     * Static utility methods for Zip archive creation and extraction.
     */
    public class Zip : GLib.Object {
        private const uint32 ZIP_LOCAL_FILE_HEADER_SIGNATURE = 0x04034b50;
        private const uint32 ZIP_CENTRAL_FILE_HEADER_SIGNATURE = 0x02014b50;
        private const uint32 ZIP_EOCD_SIGNATURE = 0x06054b50;
        private const uint16 ZIP_STORE_METHOD = 0;
        private const int ZIP_LOCAL_HEADER_SIZE = 30;
        private const int ZIP_CENTRAL_HEADER_SIZE = 46;
        private const int ZIP_EOCD_MIN_SIZE = 22;
        private const int ZIP_MAX_COMMENT_SIZE = 65535;

        private class ZipEntry : GLib.Object {
            public string name { get; private set; }
            public uint16 method { get; private set; }
            public uint16 flags { get; private set; }
            public uint32 crc32 { get; private set; }
            public uint32 compressedSize { get; private set; }
            public uint32 uncompressedSize { get; private set; }
            public int64 localHeaderOffset { get; private set; }
            public int64 dataOffset { get; private set; }

            public ZipEntry (string name,
                             uint16 method,
                             uint16 flags,
                             uint32 crc32,
                             uint32 compressedSize,
                             uint32 uncompressedSize,
                             int64 localHeaderOffset,
                             int64 dataOffset) {
                this.name = name;
                this.method = method;
                this.flags = flags;
                this.crc32 = crc32;
                this.compressedSize = compressedSize;
                this.uncompressedSize = uncompressedSize;
                this.localHeaderOffset = localHeaderOffset;
                this.dataOffset = dataOffset;
            }

            public bool isDirectory () {
                return name.has_suffix ("/");
            }

            public bool supportsDirectExtract () {
                return method == ZIP_STORE_METHOD;
            }
        }

        private class ParsedZip : GLib.Object {
            public uint8[] bytes;
            public ArrayList<ZipEntry> entries;

            public ParsedZip (owned uint8[] bytes, ArrayList<ZipEntry> entries) {
                this.bytes = (owned) bytes;
                this.entries = entries;
            }
        }

        private class ZipWriteEntry : GLib.Object {
            public string name;
            public uint8[] data;
            public bool directory;

            public ZipWriteEntry (string name, owned uint8[] data, bool directory) {
                this.name = name;
                this.data = (owned) data;
                this.directory = directory;
            }
        }

        private class ZipCentralRecord : GLib.Object {
            public string name;
            public uint32 crc32;
            public uint32 size;
            public uint32 localOffset;
            public bool directory;

            public ZipCentralRecord (string name,
                                     uint32 crc32,
                                     uint32 size,
                                     uint32 localOffset,
                                     bool directory) {
                this.name = name;
                this.crc32 = crc32;
                this.size = size;
                this.localOffset = localOffset;
                this.directory = directory;
            }
        }

        /**
         * Creates a zip archive from file list.
         *
         * @param archive destination archive path.
         * @param files source files.
         * @return Result.ok(true) on success, or Result.error(ZipError) on failure.
         */
        public static Result<bool, GLib.Error> create (Vala.Io.Path archive, ArrayList<Vala.Io.Path> files) {
            if (Objects.isNull (archive) || Objects.isNull (files) || files.size () == 0) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.INVALID_ARGUMENT ("archive/files must not be null and files must not be empty")
                );
            }

            var basenames = new HashSet<string> (GLib.str_hash, GLib.str_equal);
            var entries = new ArrayList<ZipWriteEntry> ();

            for (int i = 0; i < files.size (); i++) {
                Vala.Io.Path ? file = files.get (i);
                if (file == null || !Files.isFile (file)) {
                    continue;
                }

                string name = file.basename ();
                if (basenames.contains (name)) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.INVALID_ARGUMENT (
                            "duplicate basename is not allowed for zip -j mode: %s".printf (name)
                        )
                    );
                }
                basenames.add (name);

                uint8[] ? fileBytes = Files.readBytes (file);
                if (fileBytes == null) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.IO ("failed to read source file: %s".printf (file.toString ()))
                    );
                }

                entries.add (new ZipWriteEntry (name, fileBytes, false));
            }

            if (entries.size () == 0) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.NOT_FOUND ("no regular files were provided")
                );
            }

            var built = buildZipBytes (entries);
            if (built.isError ()) {
                return Result.error<bool, GLib.Error> (built.unwrapError ());
            }
            return writeArchiveBytes (archive, built.unwrap ().get_data (), "failed to create zip archive");
        }

        /**
         * Creates a zip archive from all entries under directory.
         *
         * @param archive destination archive path.
         * @param dir source directory.
         * @return Result.ok(true) on success, or Result.error(ZipError) on failure.
         */
        public static Result<bool, GLib.Error> createFromDir (Vala.Io.Path archive, Vala.Io.Path dir) {
            if (Objects.isNull (archive) || Objects.isNull (dir) || !Files.isDir (dir)) {
                string dirText = Objects.isNull (dir) ? "<null>" : dir.toString ();
                return Result.error<bool, GLib.Error> (
                    new ZipError.INVALID_ARGUMENT (
                        "archive and existing source directory are required: %s".printf (dirText)
                    )
                );
            }

            var entries = new ArrayList<ZipWriteEntry> ();
            var collected = collectDirectoryEntries (dir, "", entries);
            if (collected.isError ()) {
                return Result.error<bool, GLib.Error> (collected.unwrapError ());
            }

            var built = buildZipBytes (entries);
            if (built.isError ()) {
                return Result.error<bool, GLib.Error> (built.unwrapError ());
            }
            return writeArchiveBytes (
                archive,
                built.unwrap ().get_data (),
                "failed to create zip archive from directory"
            );
        }

        /**
         * Extracts archive to destination directory.
         *
         * @param archive source archive path.
         * @param dest destination directory.
         * @return Result.ok(true) on success, or Result.error(ZipError) on failure.
         */
        public static Result<bool, GLib.Error> extract (Vala.Io.Path archive, Vala.Io.Path dest) {
            if (Objects.isNull (archive) || Objects.isNull (dest)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.INVALID_ARGUMENT ("archive and dest must not be null")
                );
            }
            if (!Files.isFile (archive)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.NOT_FOUND ("archive does not exist: %s".printf (archive.toString ()))
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
            ParsedZip parsed = parsedResult.unwrap ();

            for (int i = 0; i < parsed.entries.size (); i++) {
                ZipEntry ? entry = parsed.entries.get (i);
                if (entry == null || !isSafeArchiveEntry (entry.name, dest)) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.SECURITY (
                            "unsafe zip entry rejected during extract: %s".printf (
                                entry == null ? "<null>" : entry.name
                            )
                        )
                    );
                }

                if (!entry.supportsDirectExtract ()) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.IO ("unsupported zip compression method: %u".printf (entry.method))
                    );
                }
            }

            string destinationRoot = dest.normalize ().toString ();
            for (int i = 0; i < parsed.entries.size (); i++) {
                ZipEntry ? entry = parsed.entries.get (i);
                if (entry == null) {
                    continue;
                }

                string relative = trimLeadingDotSlash (entry.name);
                Vala.Io.Path target = resolveArchiveEntryTarget (dest, relative);
                if (hasSymlinkComponent (dest, relative)) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.SECURITY (
                            "zip extraction path traverses symlink component: %s".printf (entry.name)
                        )
                    );
                }
                string targetPath = target.normalize ().toString ();
                bool resolvesToRoot = relative.length == 0 || relative == "." || targetPath == destinationRoot;
                if (!entry.isDirectory () && resolvesToRoot) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.SECURITY (
                            "zip entry resolves to extraction root file path: %s".printf (entry.name)
                        )
                    );
                }

                if (entry.isDirectory ()) {
                    var dirEnsured = ensureDirectoryPath (target);
                    if (dirEnsured.isError ()) {
                        return Result.error<bool, GLib.Error> (dirEnsured.unwrapError ());
                    }
                    continue;
                }

                int64 dataStart = entry.dataOffset;
                int64 dataEnd = entry.dataOffset + entry.compressedSize;
                if (!hasRange (parsed.bytes, dataStart, entry.compressedSize)) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.IO ("corrupted zip entry size: %s".printf (entry.name))
                    );
                }

                uint8[] payload = parsed.bytes[(int) dataStart : (int) dataEnd];
                if (entry.compressedSize != entry.uncompressedSize) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.IO ("unsupported zip entry with data descriptor: %s".printf (entry.name))
                    );
                }

                uint32 actualCrc = crc32 (payload);
                if (actualCrc != entry.crc32) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.IO ("zip CRC32 mismatch for entry: %s".printf (entry.name))
                    );
                }

                var replaced = replaceFileAtomically (
                    target,
                    payload,
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
         * @return Result.ok(entries) on success, or Result.error(ZipError) on failure.
         */
        public static Result<ArrayList<string>, GLib.Error> list (Vala.Io.Path archive) {
            if (Objects.isNull (archive)) {
                return Result.error<ArrayList<string>, GLib.Error> (
                    new ZipError.INVALID_ARGUMENT ("archive must not be null")
                );
            }
            if (!Files.isFile (archive)) {
                return Result.error<ArrayList<string>, GLib.Error> (
                    new ZipError.NOT_FOUND ("archive does not exist: %s".printf (archive.toString ()))
                );
            }

            var parsedResult = parseArchive (archive);
            if (parsedResult.isError ()) {
                return Result.error<ArrayList<string>, GLib.Error> (parsedResult.unwrapError ());
            }

            var entries = new ArrayList<string> (GLib.str_equal);
            ArrayList<ZipEntry> parsedEntries = parsedResult.unwrap ().entries;
            for (int i = 0; i < parsedEntries.size (); i++) {
                ZipEntry ? entry = parsedEntries.get (i);
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
         * @return Result.ok(true) on success, or Result.error(ZipError) on failure.
         */
        public static Result<bool, GLib.Error> addFile (Vala.Io.Path archive, Vala.Io.Path file) {
            if (Objects.isNull (archive) || Objects.isNull (file)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.INVALID_ARGUMENT ("archive and file must not be null")
                );
            }
            if (!Files.isFile (archive)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.NOT_FOUND ("archive does not exist: %s".printf (archive.toString ()))
                );
            }
            if (!Files.isFile (file)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.NOT_FOUND ("file does not exist: %s".printf (file.toString ()))
                );
            }

            var parsedResult = parseArchive (archive);
            if (parsedResult.isError ()) {
                return Result.error<bool, GLib.Error> (parsedResult.unwrapError ());
            }
            ParsedZip parsed = parsedResult.unwrap ();

            var entries = new ArrayList<ZipWriteEntry> ();
            for (int i = 0; i < parsed.entries.size (); i++) {
                ZipEntry ? entry = parsed.entries.get (i);
                if (entry == null) {
                    continue;
                }
                if (!entry.supportsDirectExtract ()) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.IO ("unsupported zip compression method: %u".printf (entry.method))
                    );
                }

                if (entry.isDirectory ()) {
                    uint8[] empty = new uint8[0];
                    entries.add (new ZipWriteEntry (entry.name, empty, true));
                    continue;
                }

                if (!hasRange (parsed.bytes, entry.dataOffset, entry.compressedSize)) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.IO ("corrupted zip entry data: %s".printf (entry.name))
                    );
                }

                int start = (int) entry.dataOffset;
                int end = (int) (entry.dataOffset + entry.compressedSize);
                uint8[] data = parsed.bytes[start : end];
                entries.add (new ZipWriteEntry (entry.name, data, false));
            }

            uint8[] ? fileBytes = Files.readBytes (file);
            if (fileBytes == null) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO ("failed to read file for zip append: %s".printf (file.toString ()))
                );
            }

            entries.add (new ZipWriteEntry (file.basename (), fileBytes, false));
            var built = buildZipBytes (entries);
            if (built.isError ()) {
                return Result.error<bool, GLib.Error> (built.unwrapError ());
            }

            return writeArchiveBytes (
                archive,
                built.unwrap ().get_data (),
                "failed to append file into zip archive: archive=%s file=%s".printf (
                    archive.toString (),
                    file.toString ()
                )
            );
        }

        /**
         * Extracts one archive entry into destination file path.
         *
         * @param archive archive path.
         * @param entry archive entry path.
         * @param dest destination file path.
         * @return Result.ok(true) on success, or Result.error(ZipError) on failure.
         */
        public static Result<bool, GLib.Error> extractFile (Vala.Io.Path archive,
                                                            string entry,
                                                            Vala.Io.Path dest) {
            if (Objects.isNull (archive) || Objects.isNull (dest) || entry.strip ().length == 0) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.INVALID_ARGUMENT ("archive, entry and dest must be valid")
                );
            }
            if (!Files.isFile (archive)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.NOT_FOUND ("archive does not exist: %s".printf (archive.toString ()))
                );
            }

            var parsedResult = parseArchive (archive);
            if (parsedResult.isError ()) {
                return Result.error<bool, GLib.Error> (parsedResult.unwrapError ());
            }
            ParsedZip parsed = parsedResult.unwrap ();

            string targetEntry = trimLeadingDotSlash (entry);
            ZipEntry ? matched = null;
            for (int i = 0; i < parsed.entries.size (); i++) {
                ZipEntry ? current = parsed.entries.get (i);
                if (current == null) {
                    continue;
                }
                if (trimLeadingDotSlash (current.name) == targetEntry) {
                    matched = current;
                    break;
                }
            }

            if (matched == null) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.NOT_FOUND (
                        "entry not found: entry=%s archive=%s".printf (entry, archive.toString ())
                    )
                );
            }
            if (matched.isDirectory ()) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.INVALID_ARGUMENT ("entry is not a file: %s".printf (matched.name))
                );
            }
            if (!matched.supportsDirectExtract ()) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO ("unsupported zip compression method: %u".printf (matched.method))
                );
            }
            if (!hasRange (parsed.bytes, matched.dataOffset, matched.compressedSize)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO ("corrupted zip entry data: %s".printf (matched.name))
                );
            }

            int start = (int) matched.dataOffset;
            int end = (int) (matched.dataOffset + matched.compressedSize);
            uint8[] payload = parsed.bytes[start : end];
            if (crc32 (payload) != matched.crc32) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO ("zip CRC32 mismatch for entry: %s".printf (matched.name))
                );
            }

            return replaceFileAtomically (dest, payload, "failed to extract entry: %s".printf (matched.name));
        }

        private static Result<bool, GLib.Error> collectDirectoryEntries (Vala.Io.Path current,
                                                                         string relative,
                                                                         ArrayList<ZipWriteEntry> outEntries) {
            GLib.List<string> ? names = Files.listDir (current);
            if (names == null) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO ("failed to read source directory: %s".printf (current.toString ()))
                );
            }
            names.sort ((a, b) => {
                return a.collate (b);
            });

            foreach (string name in names) {
                Vala.Io.Path child = current.resolve (name);
                string rel = relative.length == 0 ? name : relative + "/" + name;
                if (Files.isSymbolicFile (child)) {
                    continue;
                }
                if (Files.isDir (child)) {
                    uint8[] empty = new uint8[0];
                    outEntries.add (new ZipWriteEntry (rel + "/", empty, true));
                    var nested = collectDirectoryEntries (child, rel, outEntries);
                    if (nested.isError ()) {
                        return Result.error<bool, GLib.Error> (nested.unwrapError ());
                    }
                    continue;
                }
                if (!Files.isFile (child)) {
                    continue;
                }

                uint8[] ? bytes = Files.readBytes (child);
                if (bytes == null) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.IO ("failed to read source file: %s".printf (child.toString ()))
                    );
                }
                outEntries.add (new ZipWriteEntry (rel, bytes, false));
            }

            return Result.ok<bool, GLib.Error> (true);
        }

        private static Result<GLib.Bytes, GLib.Error> buildZipBytes (ArrayList<ZipWriteEntry> entries) {
            var output = new GLib.ByteArray ();
            var central = new ArrayList<ZipCentralRecord> ();

            for (int i = 0; i < entries.size (); i++) {
                ZipWriteEntry ? entry = entries.get (i);
                if (entry == null) {
                    continue;
                }

                string entryName = normalizeEntryName (entry.name, entry.directory);
                if (entryName.strip ().length == 0) {
                    return Result.error<GLib.Bytes, GLib.Error> (
                        new ZipError.INVALID_ARGUMENT ("zip entry name must not be empty")
                    );
                }

                uint8[] nameBytes = entryName.data[0 : entryName.length];
                if (nameBytes.length > uint16.MAX) {
                    return Result.error<GLib.Bytes, GLib.Error> (
                        new ZipError.INVALID_ARGUMENT ("zip entry name is too long: %s".printf (entryName))
                    );
                }

                uint8[] payload = entry.directory ? new uint8[0] : entry.data;
                if (payload.length > uint32.MAX) {
                    return Result.error<GLib.Bytes, GLib.Error> (
                        new ZipError.INVALID_ARGUMENT ("zip entry is too large: %s".printf (entryName))
                    );
                }

                if (output.len > uint32.MAX) {
                    return Result.error<GLib.Bytes, GLib.Error> (
                        new ZipError.IO ("zip local header offset overflow")
                    );
                }

                uint32 localOffset = output.len;
                uint32 crc = crc32 (payload);
                uint32 size = (uint32) payload.length;

                appendLe32 (output, ZIP_LOCAL_FILE_HEADER_SIGNATURE);
                appendLe16 (output, 20);
                appendLe16 (output, 0);
                appendLe16 (output, ZIP_STORE_METHOD);
                appendLe16 (output, 0);
                appendLe16 (output, 0);
                appendLe32 (output, crc);
                appendLe32 (output, size);
                appendLe32 (output, size);
                appendLe16 (output, (uint16) nameBytes.length);
                appendLe16 (output, 0);
                output.append (nameBytes);
                output.append (payload);

                central.add (new ZipCentralRecord (entryName, crc, size, localOffset, entry.directory));
            }

            if (output.len > uint32.MAX) {
                return Result.error<GLib.Bytes, GLib.Error> (
                    new ZipError.IO ("zip central directory offset overflow")
                );
            }
            uint32 centralOffset = output.len;

            for (int i = 0; i < central.size (); i++) {
                ZipCentralRecord ? record = central.get (i);
                if (record == null) {
                    continue;
                }

                uint8[] nameBytes = record.name.data[0 : record.name.length];
                appendLe32 (output, ZIP_CENTRAL_FILE_HEADER_SIGNATURE);
                appendLe16 (output, 20);
                appendLe16 (output, 20);
                appendLe16 (output, 0);
                appendLe16 (output, ZIP_STORE_METHOD);
                appendLe16 (output, 0);
                appendLe16 (output, 0);
                appendLe32 (output, record.crc32);
                appendLe32 (output, record.size);
                appendLe32 (output, record.size);
                appendLe16 (output, (uint16) nameBytes.length);
                appendLe16 (output, 0);
                appendLe16 (output, 0);
                appendLe16 (output, 0);
                appendLe16 (output, 0);
                appendLe32 (output, (uint32) (record.directory ? 0x10 : 0));
                appendLe32 (output, record.localOffset);
                output.append (nameBytes);
            }

            if (output.len < centralOffset) {
                return Result.error<GLib.Bytes, GLib.Error> (
                    new ZipError.IO ("invalid zip central directory range")
                );
            }
            uint32 centralSize = output.len - centralOffset;

            if (central.size () > uint16.MAX) {
                return Result.error<GLib.Bytes, GLib.Error> (
                    new ZipError.IO ("zip64 archives are not supported")
                );
            }

            appendLe32 (output, ZIP_EOCD_SIGNATURE);
            appendLe16 (output, 0);
            appendLe16 (output, 0);
            appendLe16 (output, (uint16) central.size ());
            appendLe16 (output, (uint16) central.size ());
            appendLe32 (output, centralSize);
            appendLe32 (output, centralOffset);
            appendLe16 (output, 0);

            return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (output.steal ()));
        }

        private static string normalizeEntryName (string name, bool directory) {
            string normalized = name;
            while (normalized.has_prefix ("./")) {
                normalized = normalized.substring (2);
            }
            normalized = normalized.replace ("\\", "/");
            if (directory && normalized.length > 0 && !normalized.has_suffix ("/")) {
                normalized += "/";
            }
            return normalized;
        }

        private static Result<bool, GLib.Error> writeArchiveBytes (Vala.Io.Path archive,
                                                                   uint8[] bytes,
                                                                   string errorContext) {
            return replaceFileAtomically (archive, bytes, errorContext);
        }

        private static Result<ParsedZip, GLib.Error> parseArchive (Vala.Io.Path archive) {
            uint8[] ? bytes = Files.readBytes (archive);
            if (bytes == null) {
                return Result.error<ParsedZip, GLib.Error> (
                    new ZipError.IO ("failed to read zip archive: %s".printf (archive.toString ()))
                );
            }
            if (bytes.length < ZIP_EOCD_MIN_SIZE) {
                return Result.error<ParsedZip, GLib.Error> (
                    new ZipError.IO ("invalid zip archive (too small): %s".printf (archive.toString ()))
                );
            }

            int eocdOffset = findEocdOffset (bytes);
            if (eocdOffset < 0) {
                return Result.error<ParsedZip, GLib.Error> (
                    new ZipError.IO ("end of central directory not found: %s".printf (archive.toString ()))
                );
            }

            uint16 diskNo = readLe16 (bytes, eocdOffset + 4);
            uint16 cdStartDisk = readLe16 (bytes, eocdOffset + 6);
            if (diskNo != 0 || cdStartDisk != 0) {
                return Result.error<ParsedZip, GLib.Error> (
                    new ZipError.IO ("multi-disk zip archives are not supported")
                );
            }

            uint16 totalEntries = readLe16 (bytes, eocdOffset + 10);
            uint32 centralSize = readLe32 (bytes, eocdOffset + 12);
            uint32 centralOffset = readLe32 (bytes, eocdOffset + 16);
            int64 centralStart = centralOffset;
            int64 centralEnd = centralStart + centralSize;
            if (centralEnd < centralStart) {
                return Result.error<ParsedZip, GLib.Error> (
                    new ZipError.IO ("invalid zip central directory range: %s".printf (archive.toString ()))
                );
            }

            if (!hasRange (bytes, centralOffset, centralSize)) {
                return Result.error<ParsedZip, GLib.Error> (
                    new ZipError.IO ("invalid zip central directory range: %s".printf (archive.toString ()))
                );
            }

            var entries = new ArrayList<ZipEntry> ();
            int64 pos = centralStart;
            for (uint16 i = 0; i < totalEntries; i++) {
                if (pos < centralStart
                    || pos > centralEnd
                    || (centralEnd - pos) < ZIP_CENTRAL_HEADER_SIZE) {
                    return Result.error<ParsedZip, GLib.Error> (
                        new ZipError.IO ("truncated central file header: %s".printf (archive.toString ()))
                    );
                }
                if (readLe32 (bytes, pos) != ZIP_CENTRAL_FILE_HEADER_SIGNATURE) {
                    return Result.error<ParsedZip, GLib.Error> (
                        new ZipError.IO ("invalid central file header signature: %s".printf (archive.toString ()))
                    );
                }

                uint16 flags = readLe16 (bytes, pos + 8);
                uint16 method = readLe16 (bytes, pos + 10);
                uint32 crc = readLe32 (bytes, pos + 16);
                uint32 compressedSize = readLe32 (bytes, pos + 20);
                uint32 uncompressedSize = readLe32 (bytes, pos + 24);
                uint16 nameLen = readLe16 (bytes, pos + 28);
                uint16 extraLen = readLe16 (bytes, pos + 30);
                uint16 commentLen = readLe16 (bytes, pos + 32);
                uint32 localOffset = readLe32 (bytes, pos + 42);

                int64 headerLen = ZIP_CENTRAL_HEADER_SIZE + nameLen + extraLen + commentLen;
                if (headerLen < ZIP_CENTRAL_HEADER_SIZE || headerLen > (centralEnd - pos)) {
                    return Result.error<ParsedZip, GLib.Error> (
                        new ZipError.IO ("truncated central entry: %s".printf (archive.toString ()))
                    );
                }

                string name = readString (bytes, pos + ZIP_CENTRAL_HEADER_SIZE, nameLen);
                if (name.strip ().length == 0) {
                    return Result.error<ParsedZip, GLib.Error> (
                        new ZipError.IO ("invalid zip entry name: %s".printf (archive.toString ()))
                    );
                }
                if ((flags & 0x0001) != 0) {
                    return Result.error<ParsedZip, GLib.Error> (
                        new ZipError.IO ("encrypted zip entries are not supported: %s".printf (name))
                    );
                }
                if ((flags & 0x0008) != 0) {
                    return Result.error<ParsedZip, GLib.Error> (
                        new ZipError.IO ("zip data descriptor entries are not supported: %s".printf (name))
                    );
                }

                int64 localHeaderOffset = localOffset;
                if (!hasRange (bytes, localHeaderOffset, ZIP_LOCAL_HEADER_SIZE)) {
                    return Result.error<ParsedZip, GLib.Error> (
                        new ZipError.IO ("invalid local header offset: %s".printf (name))
                    );
                }
                if (readLe32 (bytes, localHeaderOffset) != ZIP_LOCAL_FILE_HEADER_SIGNATURE) {
                    return Result.error<ParsedZip, GLib.Error> (
                        new ZipError.IO ("invalid local file header signature: %s".printf (name))
                    );
                }

                uint16 localNameLen = readLe16 (bytes, localHeaderOffset + 26);
                uint16 localExtraLen = readLe16 (bytes, localHeaderOffset + 28);
                int64 dataOffset = localHeaderOffset + ZIP_LOCAL_HEADER_SIZE + localNameLen + localExtraLen;
                if (!hasRange (bytes, dataOffset, compressedSize)) {
                    return Result.error<ParsedZip, GLib.Error> (
                        new ZipError.IO ("invalid local file data range: %s".printf (name))
                    );
                }

                entries.add (new ZipEntry (
                                 name,
                                 method,
                                 flags,
                                 crc,
                                 compressedSize,
                                 uncompressedSize,
                                 localHeaderOffset,
                                 dataOffset
                ));

                pos += headerLen;
            }

            return Result.ok<ParsedZip, GLib.Error> (new ParsedZip ((owned) bytes, entries));
        }

        private static int findEocdOffset (uint8[] bytes) {
            int maxComment = ZIP_MAX_COMMENT_SIZE;
            int start = bytes.length - ZIP_EOCD_MIN_SIZE;
            int min = bytes.length - ZIP_EOCD_MIN_SIZE - maxComment;
            if (min < 0) {
                min = 0;
            }

            for (int i = start; i >= min; i--) {
                if (readLe32 (bytes, i) != ZIP_EOCD_SIGNATURE) {
                    continue;
                }
                uint16 commentLen = readLe16 (bytes, i + 20);
                if (i + ZIP_EOCD_MIN_SIZE + commentLen == bytes.length) {
                    return i;
                }
            }
            return -1;
        }

        private static uint16 readLe16 (uint8[] bytes, int64 offset) {
            int pos = (int) offset;
            return (uint16) (((uint16) bytes[pos]) | ((uint16) bytes[pos + 1] << 8));
        }

        private static uint32 readLe32 (uint8[] bytes, int64 offset) {
            int pos = (int) offset;
            return (uint32) (((uint32) bytes[pos])
                             | ((uint32) bytes[pos + 1] << 8)
                             | ((uint32) bytes[pos + 2] << 16)
                             | ((uint32) bytes[pos + 3] << 24));
        }

        private static void appendLe16 (GLib.ByteArray buffer, uint16 value) {
            uint8[] bytes = {
                (uint8) (value & 0xff),
                (uint8) ((value >> 8) & 0xff)
            };
            buffer.append (bytes);
        }

        private static void appendLe32 (GLib.ByteArray buffer, uint32 value) {
            uint8[] bytes = {
                (uint8) (value & 0xff),
                (uint8) ((value >> 8) & 0xff),
                (uint8) ((value >> 16) & 0xff),
                (uint8) ((value >> 24) & 0xff)
            };
            buffer.append (bytes);
        }

        private static string readString (uint8[] bytes, int64 offset, int64 length) {
            var builder = new GLib.StringBuilder ();
            for (int64 i = 0; i < length; i++) {
                builder.append_c ((char) bytes[(int) (offset + i)]);
            }
            return builder.str;
        }

        private static bool hasRange (uint8[] bytes, int64 offset, int64 length) {
            if (offset < 0 || length < 0) {
                return false;
            }
            if (offset > bytes.length) {
                return false;
            }
            int64 end = offset + length;
            if (end < offset) {
                return false;
            }
            return end <= bytes.length;
        }

        private static uint32 crc32 (uint8[] bytes) {
            uint32 crc = uint32.MAX;
            for (int i = 0; i < bytes.length; i++) {
                crc ^= bytes[i];
                for (int j = 0; j < 8; j++) {
                    if ((crc & 1) != 0) {
                        crc = (crc >> 1) ^ ((uint32) 0xedb88320);
                    } else {
                        crc >>= 1;
                    }
                }
            }
            return crc ^ uint32.MAX;
        }

        private static Result<bool, GLib.Error> ensureDestinationDir (Vala.Io.Path dest) {
            if (Files.exists (dest) && Files.isSymbolicFile (dest)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.SECURITY ("destination must not be a symbolic link: %s".printf (dest.toString ()))
                );
            }
            if (!Files.exists (dest)) {
                if (!Files.makeDirs (dest)) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.IO ("failed to create destination directory: %s".printf (dest.toString ()))
                    );
                }
            } else if (!Files.isDir (dest)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.INVALID_ARGUMENT ("destination must be a directory: %s".printf (dest.toString ()))
                );
            }
            return Result.ok<bool, GLib.Error> (true);
        }

        private static Result<bool, GLib.Error> ensureDirectoryPath (Vala.Io.Path dirPath) {
            if (Files.exists (dirPath)) {
                if (Files.isSymbolicFile (dirPath)) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.SECURITY ("directory path is symbolic link: %s".printf (dirPath.toString ()))
                    );
                }
                if (!Files.isDir (dirPath)) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.IO ("destination path is not a directory: %s".printf (dirPath.toString ()))
                    );
                }
                return Result.ok<bool, GLib.Error> (true);
            }

            if (!Files.makeDirs (dirPath)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO ("failed to create directory: %s".printf (dirPath.toString ()))
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
                        new ZipError.SECURITY ("destination parent is symbolic link: %s".printf (parent.toString ()))
                    );
                }
                if (!Files.isDir (parent)) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.INVALID_ARGUMENT (
                            "destination parent is not a directory: %s".printf (parent.toString ())
                        )
                    );
                }
            } else if (!Files.makeDirs (parent)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO ("failed to create parent directory: %s".printf (parent.toString ()))
                );
            }

            if (Files.exists (dest) && Files.isSymbolicFile (dest)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.SECURITY ("destination file is symbolic link: %s".printf (dest.toString ()))
                );
            }
            if (Files.exists (dest) && Files.isDir (dest)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.SECURITY ("destination file is a directory: %s".printf (dest.toString ()))
                );
            }

            Vala.Io.Path temp = parent.resolve (".zip-write-%s.tmp".printf (GLib.Uuid.string_random ()));
            if (!Files.writeBytes (temp, data)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO ("%s: failed to write temp file".printf (failurePrefix))
                );
            }

            bool hadDest = Files.exists (dest);
            Vala.Io.Path backup = parent.resolve (".zip-backup-%s.tmp".printf (GLib.Uuid.string_random ()));
            if (hadDest && !Files.move (dest, backup)) {
                Files.remove (temp);
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO ("%s: failed to backup destination".printf (failurePrefix))
                );
            }

            if (!Files.move (temp, dest)) {
                string message = "%s: failed to move temp file to destination".printf (failurePrefix);
                if (hadDest && Files.exists (backup)) {
                    if (!Files.move (backup, dest)) {
                        Files.remove (temp);
                        return Result.error<bool, GLib.Error> (
                            new ZipError.IO ("%s; rollback failed".printf (message))
                        );
                    }
                }
                Files.remove (temp);
                return Result.error<bool, GLib.Error> (new ZipError.IO (message));
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
