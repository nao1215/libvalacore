using Vala.Collections;
using Vala.Io;
using Vala.Lang;

namespace Vala.Archive {
    /**
     * Static utility methods for Zip archive creation and extraction.
     */
    public class Zip : GLib.Object {
        /**
         * Creates a zip archive from file list.
         *
         * @param archive destination archive path.
         * @param files source files.
         * @return true on success.
         */
        public static bool create (Vala.Io.Path archive, ArrayList<Vala.Io.Path> files) {
            if (Objects.isNull (archive) || Objects.isNull (files) || files.size () == 0) {
                return false;
            }

            if (Files.exists (archive)) {
                Files.remove (archive);
            }

            var args = new GLib.Array<string> ();
            args.append_val ("-qj");
            args.append_val (archive.toString ());
            args.append_val ("--");

            bool hasFile = false;
            for (int i = 0; i < files.size (); i++) {
                Vala.Io.Path ? file = files.get (i);
                if (file == null || !Files.isFile (file)) {
                    continue;
                }
                hasFile = true;
                args.append_val (file.toString ());
            }

            if (!hasFile) {
                return false;
            }

            string[] execArgs = new string[args.length];
            for (uint i = 0; i < args.length; i++) {
                execArgs[i] = args.index (i);
            }
            return Vala.Io.Process.exec ("zip", execArgs);
        }

        /**
         * Creates a zip archive from all entries under directory.
         *
         * @param archive destination archive path.
         * @param dir source directory.
         * @return true on success.
         */
        public static bool createFromDir (Vala.Io.Path archive, Vala.Io.Path dir) {
            if (Objects.isNull (archive) || Objects.isNull (dir) || !Files.isDir (dir)) {
                return false;
            }

            if (Files.exists (archive)) {
                Files.remove (archive);
            }

            try {
                var launcher = new GLib.SubprocessLauncher (GLib.SubprocessFlags.NONE);
                launcher.set_cwd (dir.toString ());
                string[] argv = { "zip", "-qr", archive.toString (), ".", null };
                var process = launcher.spawnv (argv);
                return process.wait_check (null);
            } catch (GLib.Error e) {
                return false;
            }
        }

        /**
         * Extracts archive to destination directory.
         *
         * @param archive source archive path.
         * @param dest destination directory.
         * @return true on success.
         */
        public static bool extract (Vala.Io.Path archive, Vala.Io.Path dest) {
            if (Objects.isNull (archive) || Objects.isNull (dest) || !Files.isFile (archive)) {
                return false;
            }
            if (!Files.exists (dest) && !Files.makeDirs (dest)) {
                return false;
            }
            return Vala.Io.Process.exec ("unzip", { "-qq", archive.toString (), "-d", dest.toString () });
        }

        /**
         * Lists all archive entries.
         *
         * @param archive source archive path.
         * @return archive entries or null on failure.
         */
        public static ArrayList<string> ? list (Vala.Io.Path archive) {
            if (Objects.isNull (archive) || !Files.isFile (archive)) {
                return null;
            }

            string ? output = Vala.Io.Process.execWithOutput ("unzip", { "-Z1", archive.toString () });
            if (output == null) {
                return null;
            }

            var entries = new ArrayList<string> ();
            foreach (string line in output.split ("\n")) {
                string trimmed = line.strip ();
                if (trimmed.length > 0) {
                    entries.add (trimmed);
                }
            }
            return entries;
        }

        /**
         * Adds one file to an existing archive.
         *
         * @param archive archive path.
         * @param file file to add.
         * @return true on success.
         */
        public static bool addFile (Vala.Io.Path archive, Vala.Io.Path file) {
            if (Objects.isNull (archive) || Objects.isNull (file)) {
                return false;
            }
            if (!Files.isFile (archive) || !Files.isFile (file)) {
                return false;
            }
            return Vala.Io.Process.exec (
                "zip",
                { "-q", "-j", "-g", archive.toString (), file.toString () });
        }

        /**
         * Extracts one archive entry into destination file path.
         *
         * @param archive archive path.
         * @param entry archive entry path.
         * @param dest destination file path.
         * @return true on success.
         */
        public static bool extractFile (Vala.Io.Path archive, string entry, Vala.Io.Path dest) {
            if (Objects.isNull (archive) || Objects.isNull (dest) || entry.strip ().length == 0) {
                return false;
            }
            if (!Files.isFile (archive)) {
                return false;
            }

            Vala.Io.Path parent = dest.parent ();
            if (!Files.exists (parent) && !Files.makeDirs (parent)) {
                return false;
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
                    return false;
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
                        return false;
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
                    return false;
                }
            } catch (GLib.Error e) {
                if (Files.exists (temp)) {
                    Files.remove (temp);
                }
                return false;
            }

            if (Files.exists (dest) && !Files.remove (dest)) {
                Files.remove (temp);
                return false;
            }
            if (!Files.move (temp, dest)) {
                Files.remove (temp);
                return false;
            }
            return true;
        }
    }
}
