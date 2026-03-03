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

            if (Files.exists (archive) && !Files.remove (archive)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO ("failed to remove existing archive: %s".printf (archive.toString ()))
                );
            }

            var args = new GLib.Array<string> ();
            args.append_val ("-qj");
            args.append_val (archive.toString ());
            args.append_val ("--");
            var basenames = new HashSet<string> (GLib.str_hash, GLib.str_equal);

            bool hasFile = false;
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
                hasFile = true;
                args.append_val (file.toString ());
            }

            if (!hasFile) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.NOT_FOUND ("no regular files were provided")
                );
            }

            string[] execArgs = new string[args.length];
            for (uint i = 0; i < args.length; i++) {
                execArgs[i] = args.index (i);
            }
            if (!Vala.Io.Process.exec ("zip", execArgs)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO ("zip create command failed: %s".printf (archive.toString ()))
                );
            }
            return Result.ok<bool, GLib.Error> (true);
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
                return Result.error<bool, GLib.Error> (
                    new ZipError.INVALID_ARGUMENT (
                        "archive and existing source directory are required: %s".printf (dir.toString ())
                    )
                );
            }

            if (Files.exists (archive) && !Files.remove (archive)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO ("failed to remove existing archive: %s".printf (archive.toString ()))
                );
            }

            try {
                var launcher = new GLib.SubprocessLauncher (GLib.SubprocessFlags.NONE);
                launcher.set_cwd (dir.toString ());
                string[] argv = { "zip", "-qr", archive.toString (), ".", null };
                var process = launcher.spawnv (argv);
                if (!process.wait_check (null)) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.IO ("zip createFromDir command failed: %s".printf (archive.toString ()))
                    );
                }
                return Result.ok<bool, GLib.Error> (true);
            } catch (GLib.Error e) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO (
                        "zip createFromDir failed for dir=%s archive=%s: %s".printf (
                            dir.toString (),
                            archive.toString (),
                            e.message
                        )
                    )
                );
            }
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
            if (!Files.exists (dest) && !Files.makeDirs (dest)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO ("failed to create destination directory: %s".printf (dest.toString ()))
                );
            }

            var listed = list (archive);
            if (listed.isError ()) {
                return Result.error<bool, GLib.Error> (listed.unwrapError ());
            }
            ArrayList<string> entries = listed.unwrap ();
            for (int i = 0; i < entries.size (); i++) {
                string ? entry = entries.get (i);
                if (entry == null || !isSafeArchiveEntry (entry, dest)) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.SECURITY (
                            "unsafe zip entry rejected during extract: %s".printf (entry ?? "<null>")
                        )
                    );
                }
            }

            if (!Vala.Io.Process.exec ("unzip", { "-qq", archive.toString (), "-d", dest.toString () })) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO (
                        "unzip extract command failed: archive=%s dest=%s".printf (
                            archive.toString (),
                            dest.toString ()
                        )
                    )
                );
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

            string ? output = Vala.Io.Process.execWithOutput ("unzip", { "-Z1", archive.toString () });
            if (output == null) {
                return Result.error<ArrayList<string>, GLib.Error> (
                    new ZipError.IO ("failed to list zip entries: %s".printf (archive.toString ()))
                );
            }

            var entries = new ArrayList<string> ();
            foreach (string line in output.split ("\n")) {
                string trimmed = line.strip ();
                if (trimmed.length > 0) {
                    entries.add (trimmed);
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
            if (!Vala.Io.Process.exec (
                    "zip",
                    { "-q", "-j", "-g", archive.toString (), file.toString () })) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO (
                        "zip addFile command failed: archive=%s file=%s".printf (
                            archive.toString (),
                            file.toString ()
                        )
                    )
                );
            }
            return Result.ok<bool, GLib.Error> (true);
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
            var listed = list (archive);
            if (listed.isError ()) {
                return Result.error<bool, GLib.Error> (listed.unwrapError ());
            }
            string targetEntry = entry;
            if (targetEntry.has_prefix ("./")) {
                targetEntry = targetEntry.substring (2);
            }
            bool found = false;
            ArrayList<string> entries = listed.unwrap ();
            for (int i = 0; i < entries.size (); i++) {
                string ? listedEntry = entries.get (i);
                if (listedEntry == null) {
                    continue;
                }
                string normalized = listedEntry;
                if (normalized.has_prefix ("./")) {
                    normalized = normalized.substring (2);
                }
                if (normalized == targetEntry) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.NOT_FOUND (
                        "entry not found: entry=%s archive=%s".printf (entry, archive.toString ())
                    )
                );
            }

            Vala.Io.Path parent = dest.parent ();
            if (!Files.exists (parent) && !Files.makeDirs (parent)) {
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO ("failed to create parent directory: %s".printf (parent.toString ()))
                );
            }

            Vala.Io.Path temp = parent.resolve (".zip-extract-%s.tmp".printf (GLib.Uuid.string_random ()));
            try {
                string safeEntry = entry;
                if (safeEntry.has_prefix ("-")) {
                    safeEntry = "./" + safeEntry;
                }
                var process = new GLib.Subprocess (
                    GLib.SubprocessFlags.STDOUT_PIPE | GLib.SubprocessFlags.STDERR_SILENCE
                    ,
                    "unzip",
                    "-p",
                    archive.toString (),
                    safeEntry,
                    null
                );
                GLib.InputStream ? stdoutPipe = process.get_stdout_pipe ();
                if (stdoutPipe == null) {
                    return Result.error<bool, GLib.Error> (
                        new ZipError.IO ("failed to open unzip stdout stream: %s".printf (archive.toString ()))
                    );
                }

                GLib.File tempFile = GLib.File.new_for_path (temp.toString ());
                var outStream = tempFile.replace (null,
                                                  false,
                                                  GLib.FileCreateFlags.REPLACE_DESTINATION,
                                                  null);
                uint8[] buf = new uint8[8192];
                while (true) {
                    ssize_t read = stdoutPipe.read (buf, null);
                    if (read == 0) {
                        break;
                    }
                    if (read < 0) {
                        outStream.close (null);
                        Files.remove (temp);
                        return Result.error<bool, GLib.Error> (
                            new ZipError.IO ("failed to read unzip stream: %s".printf (archive.toString ()))
                        );
                    }
                    size_t written = 0;
                    outStream.write_all (buf[0 : (size_t) read], out written, null);
                }
                outStream.flush (null);
                outStream.close (null);

                if (!process.wait_check (null)) {
                    if (Files.exists (temp)) {
                        Files.remove (temp);
                    }
                    return Result.error<bool, GLib.Error> (
                        new ZipError.NOT_FOUND (
                            "entry not found or extraction failed: entry=%s archive=%s".printf (
                                entry,
                                archive.toString ()
                            )
                        )
                    );
                }
            } catch (GLib.Error e) {
                if (Files.exists (temp)) {
                    Files.remove (temp);
                }
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO (
                        "zip extractFile failed: archive=%s entry=%s reason=%s".printf (
                            archive.toString (),
                            entry,
                            e.message
                        )
                    )
                );
            }

            bool hadDest = Files.exists (dest);
            Vala.Io.Path backup = parent.resolve (".zip-dest-backup-%s.tmp".printf (GLib.Uuid.string_random ()));
            if (hadDest && !Files.move (dest, backup)) {
                Files.remove (temp);
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO ("failed to backup destination file: %s".printf (dest.toString ()))
                );
            }
            if (!Files.move (temp, dest)) {
                if (hadDest && Files.exists (backup)) {
                    Files.move (backup, dest);
                }
                Files.remove (temp);
                return Result.error<bool, GLib.Error> (
                    new ZipError.IO ("failed to move extracted file to destination: %s".printf (dest.toString ()))
                );
            }
            if (hadDest && Files.exists (backup)) {
                Files.remove (backup);
            }
            return Result.ok<bool, GLib.Error> (true);
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

            string basePath = canonicalizePathForSafety (dest.normalize ().toString ());
            string resolved = canonicalizePathForSafety (dest.resolve (trimmed).normalize ().toString ());
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

        private static string canonicalizePathForSafety (string path) {
            string normalized = new Vala.Io.Path (path).normalize ().toString ();
            string ? direct = Posix.realpath (normalized);
            if (direct != null) {
                return direct;
            }

            string cursor = normalized;
            string suffix = "";
            while (true) {
                string ? real = Posix.realpath (cursor);
                if (real != null) {
                    if (suffix.length == 0) {
                        return real;
                    }
                    if (real == "/") {
                        return "/" + suffix;
                    }
                    return real + "/" + suffix;
                }

                string parent = GLib.Path.get_dirname (cursor);
                string basename_part = GLib.Path.get_basename (cursor);
                if (parent == cursor) {
                    break;
                }

                suffix = suffix.length == 0 ? basename_part : basename_part + "/" + suffix;
                cursor = parent;
            }
            return normalized;
        }
    }
}
