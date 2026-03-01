using Vala.Collections;
using Vala.Io;
using Vala.Lang;

namespace Vala.Archive {
    /**
     * Static utility methods for Tar archive creation and extraction.
     */
    public class Tar : GLib.Object {
        /**
         * Creates a tar archive from file list.
         *
         * @param archive destination archive path.
         * @param files source files.
         * @return true on success.
         */
        public static bool create (Vala.Io.Path archive, ArrayList<Vala.Io.Path> files) {
            if (Objects.isNull (archive) || Objects.isNull (files) || files.size () == 0) {
                return false;
            }

            var cmd = new GLib.StringBuilder ();
            cmd.append ("tar -cf ");
            cmd.append (quote (archive.toString ()));
            var basenames = new HashSet<string> (GLib.str_hash, GLib.str_equal);

            bool hasFile = false;
            for (int i = 0; i < files.size (); i++) {
                Vala.Io.Path ? file = files.get (i);
                if (file == null || !Files.isFile (file)) {
                    continue;
                }

                string name = file.basename ();
                if (basenames.contains (name)) {
                    return false;
                }
                basenames.add (name);

                hasFile = true;
                cmd.append (" -C ");
                cmd.append (quote (file.parent ().toString ()));
                cmd.append (" ");
                cmd.append (quote (name));
            }

            if (!hasFile) {
                return false;
            }

            if (Files.exists (archive)) {
                Files.remove (archive);
            }
            return Vala.Io.Process.exec ("sh", { "-c", cmd.str });
        }

        /**
         * Creates a tar archive from all entries under directory.
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

            return Vala.Io.Process.exec (
                "tar",
                { "-cf", archive.toString (), "-C", dir.toString (), "." });
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
            if (containsArchiveLinks (archive)) {
                return false;
            }

            ArrayList<string> ? entries = list (archive);
            if (entries == null) {
                return false;
            }
            for (int i = 0; i < entries.size (); i++) {
                string ? entry = entries.get (i);
                if (entry == null || !isSafeArchiveEntry (entry, dest)) {
                    return false;
                }
            }

            return Vala.Io.Process.exec (
                "tar",
                { "-xf", archive.toString (), "-C", dest.toString () });
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

            string ? output = Vala.Io.Process.execWithOutput ("tar", { "-tf", archive.toString () });
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
                "tar",
            {
                "--append",
                "-f", archive.toString (),
                "-C", file.parent ().toString (),
                file.basename ()
            });
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

            Vala.Io.Path temp = parent.resolve (".tar-extract-%s.tmp".printf (GLib.Uuid.string_random ()));
            string cmd = "tar -xOf %s %s > %s".printf (
                quote (archive.toString ()),
                quote (entry),
                quote (temp.toString ())
            );
            bool extracted = Vala.Io.Process.exec ("sh", { "-c", cmd });
            if (!extracted) {
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

        private static string quote (string s) {
            return GLib.Shell.quote (s);
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
                return resolved == "." || !resolved.has_prefix ("..");
            }
            if (resolved == basePath) {
                return true;
            }
            return resolved.has_prefix (basePath + "/");
        }

        private static bool containsArchiveLinks (Vala.Io.Path archive) {
            string ? output = Vala.Io.Process.execWithOutput ("tar", { "-tvf", archive.toString () });
            if (output == null) {
                return true;
            }

            foreach (string line in output.split ("\n")) {
                string trimmed = line.strip ();
                if (trimmed.length == 0) {
                    continue;
                }

                // Reject symbolic links and hard links to avoid link traversal on extraction.
                char kind = trimmed[0];
                if (kind == 'l' || kind == 'h') {
                    return true;
                }
            }
            return false;
        }
    }
}
