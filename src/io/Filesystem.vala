using Vala.Time;

namespace Vala.Io {
    /**
     * Filesystem metadata utility methods.
     */
    public class Filesystem : GLib.Object {
        /**
         * Returns file attributes for the given path.
         *
         * @param path target path.
         * @return file attributes, or null on failure.
         */
        public static GLib.FileInfo ? getFileAttributes (Vala.Io.Path path) {
            if (!Files.exists (path)) {
                return null;
            }

            try {
                var file = GLib.File.new_for_path (path.toString ());
                return file.query_info (
                    "standard::type,standard::size,time::modified,unix::uid,unix::gid,"
                    + "access::can-read,access::can-write,access::can-execute",
                    GLib.FileQueryInfoFlags.NONE
                );
            } catch (GLib.Error e) {
                return null;
            }
        }

        /**
         * Sets the last modified time for a file.
         *
         * @param path target path.
         * @param t modified time value.
         * @return true on success.
         */
        public static bool setLastModifiedTime (Vala.Io.Path path, Vala.Time.DateTime t) {
            if (!Files.exists (path)) {
                return false;
            }

            int64 unixTime = t.toUnixTimestamp ();
            if (unixTime < 0) {
                return false;
            }

            try {
                var file = GLib.File.new_for_path (path.toString ());
                var info = new GLib.FileInfo ();
                info.set_attribute_uint64 (GLib.FileAttribute.TIME_MODIFIED, (uint64) unixTime);
                file.set_attributes_from_info (info, GLib.FileQueryInfoFlags.NONE);
                return true;
            } catch (GLib.Error e) {
                return false;
            }
        }

        /**
         * Returns whether a path is readable.
         *
         * @param path target path.
         * @return true when readable.
         */
        public static bool isReadable (Vala.Io.Path path) {
            return Files.canRead (path);
        }

        /**
         * Returns whether a path is writable.
         *
         * @param path target path.
         * @return true when writable.
         */
        public static bool isWritable (Vala.Io.Path path) {
            return Files.canWrite (path);
        }

        /**
         * Returns whether a path is executable.
         *
         * @param path target path.
         * @return true when executable.
         */
        public static bool isExecutable (Vala.Io.Path path) {
            return Files.canExec (path);
        }

        /**
         * Returns owner name for the path.
         *
         * @param path target path.
         * @return owner name, or null on failure.
         */
        public static string ? getOwner (Vala.Io.Path path) {
            if (!Files.exists (path)) {
                return null;
            }

            Posix.Stat st;
            if (Posix.stat (path.toString (), out st) != 0) {
                return null;
            }

            unowned Posix.Passwd ? passwd = Posix.getpwuid (st.st_uid);
            if (passwd == null) {
                return null;
            }
            return passwd.pw_name;
        }

        /**
         * Sets owner by user name.
         *
         * @param path target path.
         * @param owner owner name.
         * @return true on success.
         */
        public static bool setOwner (Vala.Io.Path path, string owner) {
            if (!Files.exists (path) || owner.length == 0) {
                return false;
            }

            unowned Posix.Passwd ? passwd = Posix.getpwnam (owner);
            if (passwd == null) {
                return false;
            }

            Posix.Stat st;
            if (Posix.stat (path.toString (), out st) != 0) {
                return false;
            }

            return Posix.chown (path.toString (), passwd.pw_uid, st.st_gid) == 0;
        }
    }
}
