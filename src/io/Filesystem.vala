using Vala.Collections;
using Vala.Time;

namespace Vala.Io {
    /**
     * Recoverable filesystem metadata errors.
     */
    public errordomain FilesystemError {
        INVALID_ARGUMENT,
        NOT_FOUND,
        IO
    }

    /**
     * Filesystem metadata utility methods.
     */
    public class Filesystem : GLib.Object {
        /**
         * Returns file attributes for the given path.
         *
         * @param path target path.
         * @return Result.ok(file attributes), or
         *         Result.error(FilesystemError.NOT_FOUND/IO) on failure.
         */
        public static Result<GLib.FileInfo, GLib.Error> getFileAttributes (Vala.Io.Path path) {
            if (!Files.exists (path)) {
                return Result.error<GLib.FileInfo, GLib.Error> (
                    new FilesystemError.NOT_FOUND ("path not found: %s".printf (path.toString ()))
                );
            }

            try {
                var file = GLib.File.new_for_path (path.toString ());
                return Result.ok<GLib.FileInfo, GLib.Error> (file.query_info (
                                                                 "standard::type,standard::size,time::modified,unix::uid,unix::gid,"
                                                                 + "access::can-read,access::can-write,access::can-execute",
                                                                 GLib.FileQueryInfoFlags.NONE
                ));
            } catch (GLib.Error e) {
                return Result.error<GLib.FileInfo, GLib.Error> (
                    new FilesystemError.IO ("failed to query file attributes: %s".printf (path.toString ()))
                );
            }
        }

        /**
         * Sets the last modified time for a file.
         *
         * @param path target path.
         * @param t modified time value.
         * @return Result.ok(true) on success, or Result.error(FilesystemError.*) on failure.
         */
        public static Result<bool, GLib.Error> setLastModifiedTime (Vala.Io.Path path, Vala.Time.DateTime t) {
            if (!Files.exists (path)) {
                return Result.error<bool, GLib.Error> (
                    new FilesystemError.NOT_FOUND ("path not found: %s".printf (path.toString ()))
                );
            }

            int64 unixTime = t.toUnixTimestamp ();
            if (unixTime < 0) {
                return Result.error<bool, GLib.Error> (
                    new FilesystemError.INVALID_ARGUMENT (
                        "modified time must not be negative: %s".printf (unixTime.to_string ())
                    )
                );
            }

            try {
                var file = GLib.File.new_for_path (path.toString ());
                var info = new GLib.FileInfo ();
                info.set_attribute_uint64 (GLib.FileAttribute.TIME_MODIFIED, (uint64) unixTime);
                file.set_attributes_from_info (info, GLib.FileQueryInfoFlags.NONE);
                return Result.ok<bool, GLib.Error> (true);
            } catch (GLib.Error e) {
                return Result.error<bool, GLib.Error> (
                    new FilesystemError.IO (
                        "failed to set modified time for path: %s".printf (path.toString ())
                    )
                );
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
         * @return Result.ok(owner name), or Result.error(FilesystemError.*) on failure.
         */
        public static Result<string, GLib.Error> getOwner (Vala.Io.Path path) {
            if (!Files.exists (path)) {
                return Result.error<string, GLib.Error> (
                    new FilesystemError.NOT_FOUND ("path not found: %s".printf (path.toString ()))
                );
            }

            Posix.Stat st;
            if (Posix.stat (path.toString (), out st) != 0) {
                return Result.error<string, GLib.Error> (
                    new FilesystemError.IO (
                        "failed to read file metadata for path: %s".printf (path.toString ())
                    )
                );
            }

            unowned Posix.Passwd ? passwd = Posix.getpwuid (st.st_uid);
            if (passwd == null) {
                return Result.error<string, GLib.Error> (
                    new FilesystemError.IO ("failed to resolve owner uid: %d".printf ((int) st.st_uid))
                );
            }
            return Result.ok<string, GLib.Error> (passwd.pw_name);
        }

        /**
         * Sets owner by user name.
         *
         * @param path target path.
         * @param owner owner name.
         * @return Result.ok(true) on success, or Result.error(FilesystemError.*) on failure.
         */
        public static Result<bool, GLib.Error> setOwner (Vala.Io.Path path, string owner) {
            if (!Files.exists (path)) {
                return Result.error<bool, GLib.Error> (
                    new FilesystemError.NOT_FOUND ("path not found: %s".printf (path.toString ()))
                );
            }

            if (owner.length == 0) {
                return Result.error<bool, GLib.Error> (
                    new FilesystemError.INVALID_ARGUMENT ("owner must not be empty")
                );
            }

            unowned Posix.Passwd ? passwd = Posix.getpwnam (owner);
            if (passwd == null) {
                return Result.error<bool, GLib.Error> (
                    new FilesystemError.NOT_FOUND ("owner not found: %s".printf (owner))
                );
            }

            Posix.Stat st;
            if (Posix.stat (path.toString (), out st) != 0) {
                return Result.error<bool, GLib.Error> (
                    new FilesystemError.IO ("failed to stat path: %s".printf (path.toString ()))
                );
            }

            if (Posix.chown (path.toString (), passwd.pw_uid, st.st_gid) != 0) {
                return Result.error<bool, GLib.Error> (
                    new FilesystemError.IO (
                        "failed to change owner for path: %s (owner=%s)".printf (path.toString (), owner)
                    )
                );
            }
            return Result.ok<bool, GLib.Error> (true);
        }
    }
}
