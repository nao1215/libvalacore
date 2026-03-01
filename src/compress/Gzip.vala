using Vala.Io;
using Vala.Lang;

namespace Vala.Compress {
    /**
     * Static utility methods for Gzip compression and decompression.
     *
     * Example:
     * {{{
     *     uint8[] src = { 0x41, 0x42, 0x43 };
     *     uint8[] gz = Gzip.compress (src);
     *     uint8[]? restored = Gzip.decompress (gz);
     * }}}
     */
    public class Gzip : GLib.Object {
        /**
         * Compresses bytes with Gzip format.
         *
         * @param data source bytes.
         * @return compressed bytes. Empty array is returned on conversion failure.
         */
        public static uint8[] compress (uint8[] data) {
            if (data.length == 0) {
                return gzipEmptyPayload ();
            }

            uint8[] ? compressed = convert (
                data,
                new GLib.ZlibCompressor (GLib.ZlibCompressorFormat.GZIP, -1)
            );

            if (compressed == null) {
                uint8[] empty = new uint8[0];
                return empty;
            }
            return compressed;
        }

        /**
         * Decompresses Gzip bytes.
         *
         * @param data compressed bytes.
         * @return decompressed bytes, or null on invalid input.
         */
        public static uint8[] ? decompress (uint8[] data) {
            return convert (data, new GLib.ZlibDecompressor (GLib.ZlibCompressorFormat.GZIP));
        }

        /**
         * Compresses a file into Gzip binary file.
         *
         * @param src source file path.
         * @param dst destination file path.
         * @return true on success, false on read/write or conversion failure.
         */
        public static bool compressFile (Vala.Io.Path src, Vala.Io.Path dst) {
            if (Objects.isNull (src) || Objects.isNull (dst)) {
                return false;
            }

            uint8[] ? bytes = Files.readBytes (src);
            if (bytes == null) {
                return false;
            }
            if (bytes.length == 0) {
                return Files.writeBytes (dst, gzipEmptyPayload ());
            }

            uint8[] ? compressed = convert (
                bytes,
                new GLib.ZlibCompressor (GLib.ZlibCompressorFormat.GZIP, -1)
            );
            if (compressed == null) {
                return false;
            }
            return Files.writeBytes (dst, compressed);
        }

        /**
         * Decompresses a Gzip file into destination file.
         *
         * @param src source gzip file path.
         * @param dst destination plain file path.
         * @return true on success, false on read/write or conversion failure.
         */
        public static bool decompressFile (Vala.Io.Path src, Vala.Io.Path dst) {
            if (Objects.isNull (src) || Objects.isNull (dst)) {
                return false;
            }

            uint8[] ? bytes = Files.readBytes (src);
            if (bytes == null) {
                return false;
            }

            uint8[] ? plain = decompress (bytes);
            if (plain == null) {
                return false;
            }
            return Files.writeBytes (dst, plain);
        }

        /**
         * Compresses bytes with explicit compression level.
         *
         * @param data source bytes.
         * @param level compression level in range [1, 9].
         * @return compressed bytes. Empty array is returned on conversion failure.
         */
        public static uint8[] compressLevel (uint8[] data, int level) {
            if (level < 1 || level > 9) {
                return new uint8[0];
            }
            if (data.length == 0) {
                return gzipEmptyPayload ();
            }

            uint8[] ? compressed = convert (
                data,
                new GLib.ZlibCompressor (GLib.ZlibCompressorFormat.GZIP, level)
            );
            if (compressed == null) {
                uint8[] empty = new uint8[0];
                return empty;
            }
            return compressed;
        }

        private static uint8[] ? convert (uint8[] data, GLib.Converter converter) {
            int inputOffset = 0;
            var output = new GLib.ByteArray ();

            while (true) {
                unowned uint8[] inChunk = tailBytes (data, inputOffset);
                uint8[] outChunk = new uint8[4096];
                GLib.ConverterFlags flags = GLib.ConverterFlags.NONE;
                if (inputOffset >= data.length) {
                    flags = GLib.ConverterFlags.INPUT_AT_END;
                }

                size_t bytesRead = 0;
                size_t bytesWritten = 0;
                GLib.ConverterResult result;
                try {
                    result = converter.convert (
                        inChunk,
                        outChunk,
                        flags,
                        out bytesRead,
                        out bytesWritten
                    );
                } catch (Error e) {
                    return null;
                }

                if (bytesWritten > 0) {
                    output.append (outChunk[0 : (int) bytesWritten]);
                }

                inputOffset += (int) bytesRead;

                if (result == GLib.ConverterResult.FINISHED) {
                    break;
                }
                if (result == GLib.ConverterResult.ERROR) {
                    return null;
                }
                if (inputOffset >= data.length &&
                    bytesRead == 0 &&
                    bytesWritten == 0) {
                    break;
                }
            }

            if (output.len == 0) {
                uint8[] empty = new uint8[0];
                return empty;
            }
            return output.steal ();
        }

        private static unowned uint8[] tailBytes (uint8[] data, int offset) {
            if (offset >= data.length) {
                return data[data.length : data.length];
            }
            return data[offset : data.length];
        }

        private static uint8[] gzipEmptyPayload () {
            uint8[] payload = {
                0x1f, 0x8b, 0x08, 0x00,
                0x00, 0x00, 0x00, 0x00,
                0x00, 0x03, 0x03, 0x00,
                0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00
            };
            return payload;
        }
    }
}
