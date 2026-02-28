namespace Vala.Io {
    /**
     * Resource loading helper methods.
     *
     * This helper currently reads binary resources from a filesystem path and
     * returns the whole content as a byte array.
     *
     * Example:
     * {{{
     *     uint8[]? bytes = Resource.readResource ("./assets/logo.bin");
     *     if (bytes != null) {
     *         print ("loaded=%u\n", bytes.length);
     *     }
     * }}}
     */
    public class Resource : GLib.Object {
        /**
         * Reads resource data from a file path.
         *
         * @param name resource file path.
         * @return file bytes, or null on failure.
         */
        public static uint8[] ? readResource (string name) {
            if (name.length == 0) {
                return null;
            }

            try {
                uint8[] data;
                if (FileUtils.get_data (name, out data)) {
                    return data;
                }
            } catch (GLib.FileError e) {
                return null;
            }

            return null;
        }
    }
}
