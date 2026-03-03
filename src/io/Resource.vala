using Vala.Collections;

namespace Vala.Io {
    /**
     * Recoverable resource loading errors.
     */
    public errordomain ResourceError {
        INVALID_ARGUMENT,
        NOT_FOUND,
        IO
    }

    /**
     * Resource loading helper methods.
     *
     * This helper currently reads binary resources from a filesystem path and
     * returns the whole content as a byte array.
     *
     * Example:
     * {{{
     *     var bytes = Resource.readResource ("./assets/logo.bin");
     *     if (bytes.isOk ()) {
     *         print ("loaded=%zu\n", bytes.unwrap ().get_size ());
     *     }
     * }}}
     */
    public class Resource : GLib.Object {
        /**
         * Reads resource data from a file path.
         *
         * @param name resource file path.
         * @return Result.ok(resource bytes), or Result.error(ResourceError.*) on failure.
         */
        public static Result<GLib.Bytes, GLib.Error> readResource (string name) {
            if (name.length == 0) {
                return Result.error<GLib.Bytes, GLib.Error> (
                    new ResourceError.INVALID_ARGUMENT ("resource name must not be empty")
                );
            }

            try {
                uint8[] data;
                if (FileUtils.get_data (name, out data)) {
                    return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (data));
                }
            } catch (GLib.FileError e) {
                if (e is GLib.FileError.NOENT) {
                    return Result.error<GLib.Bytes, GLib.Error> (
                        new ResourceError.NOT_FOUND ("resource file not found: %s".printf (name))
                    );
                }
                return Result.error<GLib.Bytes, GLib.Error> (
                    new ResourceError.IO (
                        "failed to read resource file: %s: %s".printf (name, e.message)
                    )
                );
            }

            return Result.error<GLib.Bytes, GLib.Error> (
                new ResourceError.IO ("failed to read resource file: %s".printf (name))
            );
        }
    }
}
