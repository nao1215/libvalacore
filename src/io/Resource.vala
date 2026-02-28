namespace Vala.Io {
    /**
     * Resource loading helper methods.
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
