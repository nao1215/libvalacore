using Vala.Io;
using Vala.Lang;
using Vala.Collections;

namespace Vala.Compress {
    /**
     * Error domain for gzip operations.
     */
    public errordomain GzipError {
        INVALID_ARGUMENT,
        NOT_FOUND,
        IO,
        PARSE
    }

    /**
     * Static utility methods for Gzip compression and decompression.
     *
     * Example:
     * {{{
     *     uint8[] src = { 0x41, 0x42, 0x43 };
     *     var compressed = Gzip.compress (src);
     *     if (compressed.isOk ()) {
     *         var restored = Gzip.decompress (compressed.unwrap ());
     *     }
     * }}}
     */
    public class Gzip : GLib.Object {
        /**
         * Compresses bytes with Gzip format.
         *
         * @param data source bytes.
         * @return Result.ok(compressed bytes), or Result.error(GzipError.IO) on conversion failure.
         */
        public static Result<GLib.Bytes, GLib.Error> compress (uint8[] data) {
            if (data.length == 0) {
                uint8[] ? compressedEmpty = convert (
                    data,
                    new GLib.ZlibCompressor (GLib.ZlibCompressorFormat.GZIP, -1)
                );
                if (compressedEmpty == null) {
                    return Result.error<GLib.Bytes, GLib.Error> (
                        new GzipError.IO ("failed to compress empty gzip payload")
                    );
                }
                if (compressedEmpty.length == 0) {
                    compressedEmpty = gzipEmptyPayload ();
                }
                return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (compressedEmpty));
            }

            uint8[] ? compressed = convert (
                data,
                new GLib.ZlibCompressor (GLib.ZlibCompressorFormat.GZIP, -1)
            );

            if (compressed == null) {
                return Result.error<GLib.Bytes, GLib.Error> (
                    new GzipError.IO ("failed to compress gzip payload")
                );
            }
            return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (compressed));
        }

        /**
         * Decompresses Gzip bytes.
         *
         * @param data compressed bytes.
         * @return Result.ok(decompressed bytes), or Result.error(GzipError.PARSE) on invalid input.
         */
        public static Result<GLib.Bytes, GLib.Error> decompress (uint8[] data) {
            if (isGzipEmptyPayload (data)) {
                return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (new uint8[0]));
            }
            uint8[] ? plain = convert (data, new GLib.ZlibDecompressor (GLib.ZlibCompressorFormat.GZIP));
            if (plain == null) {
                return Result.error<GLib.Bytes, GLib.Error> (
                    new GzipError.PARSE ("invalid gzip payload")
                );
            }
            return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (plain));
        }

        /**
         * Compresses a file into Gzip binary file.
         *
         * @param src source file path.
         * @param dst destination file path.
         * @return Result.ok(true) on success, or Result.error(GzipError) on failure.
         */
        public static Result<bool, GLib.Error> compressFile (Vala.Io.Path src, Vala.Io.Path dst) {
            if (Objects.isNull (src) || Objects.isNull (dst)) {
                return Result.error<bool, GLib.Error> (
                    new GzipError.INVALID_ARGUMENT ("source and destination must not be null")
                );
            }

            uint8[] ? bytes = Files.readBytes (src);
            if (bytes == null) {
                return Result.error<bool, GLib.Error> (
                    new GzipError.NOT_FOUND ("source file not found or unreadable: %s".printf (src.toString ()))
                );
            }
            if (bytes.length == 0) {
                var compressedEmpty = compress (bytes);
                if (compressedEmpty.isError ()) {
                    return Result.error<bool, GLib.Error> (compressedEmpty.unwrapError ());
                }
                if (!Files.writeBytes (dst, compressedEmpty.unwrap ().get_data ())) {
                    return Result.error<bool, GLib.Error> (
                        new GzipError.IO ("failed to write gzip file: %s".printf (dst.toString ()))
                    );
                }
                return Result.ok<bool, GLib.Error> (true);
            }

            uint8[] ? compressed = convert (
                bytes,
                new GLib.ZlibCompressor (GLib.ZlibCompressorFormat.GZIP, -1)
            );
            if (compressed == null) {
                return Result.error<bool, GLib.Error> (
                    new GzipError.IO ("failed to compress source file: %s".printf (src.toString ()))
                );
            }
            if (!Files.writeBytes (dst, compressed)) {
                return Result.error<bool, GLib.Error> (
                    new GzipError.IO ("failed to write gzip file: %s".printf (dst.toString ()))
                );
            }
            return Result.ok<bool, GLib.Error> (true);
        }

        /**
         * Decompresses a Gzip file into destination file.
         *
         * @param src source gzip file path.
         * @param dst destination plain file path.
         * @return Result.ok(true) on success, or Result.error(GzipError) on failure.
         */
        public static Result<bool, GLib.Error> decompressFile (Vala.Io.Path src, Vala.Io.Path dst) {
            if (Objects.isNull (src) || Objects.isNull (dst)) {
                return Result.error<bool, GLib.Error> (
                    new GzipError.INVALID_ARGUMENT ("source and destination must not be null")
                );
            }

            uint8[] ? bytes = Files.readBytes (src);
            if (bytes == null) {
                return Result.error<bool, GLib.Error> (
                    new GzipError.NOT_FOUND ("source gzip file not found or unreadable: %s".printf (src.toString ()))
                );
            }

            var plain = decompress (bytes);
            if (plain.isError ()) {
                return Result.error<bool, GLib.Error> (plain.unwrapError ());
            }
            if (!Files.writeBytes (dst, plain.unwrap ().get_data ())) {
                return Result.error<bool, GLib.Error> (
                    new GzipError.IO ("failed to write decompressed file: %s".printf (dst.toString ()))
                );
            }
            return Result.ok<bool, GLib.Error> (true);
        }

        /**
         * Compresses bytes with explicit compression level.
         *
         * @param data source bytes.
         * @param level compression level in range [1, 9].
         * @return Result.ok(compressed bytes), or Result.error(GzipError) on failure.
         */
        public static Result<GLib.Bytes, GLib.Error> compressLevel (uint8[] data, int level) {
            if (level < 1 || level > 9) {
                return Result.error<GLib.Bytes, GLib.Error> (
                    new GzipError.INVALID_ARGUMENT ("compression level must be in [1, 9]: %d".printf (level))
                );
            }
            if (data.length == 0) {
                uint8[] ? compressedEmpty = convert (
                    data,
                    new GLib.ZlibCompressor (GLib.ZlibCompressorFormat.GZIP, level)
                );
                if (compressedEmpty == null) {
                    return Result.error<GLib.Bytes, GLib.Error> (
                        new GzipError.IO ("failed to compress empty gzip payload with level=%d".printf (level))
                    );
                }
                if (compressedEmpty.length == 0) {
                    compressedEmpty = gzipEmptyPayload ();
                }
                return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (compressedEmpty));
            }

            uint8[] ? compressed = convert (
                data,
                new GLib.ZlibCompressor (GLib.ZlibCompressorFormat.GZIP, level)
            );
            if (compressed == null) {
                return Result.error<GLib.Bytes, GLib.Error> (
                    new GzipError.IO ("failed to compress gzip payload with level=%d".printf (level))
                );
            }
            return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (compressed));
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

        private static bool isGzipEmptyPayload (uint8[] data) {
            uint8[] payload = gzipEmptyPayload ();
            if (data.length != payload.length) {
                return false;
            }
            for (int i = 0; i < payload.length; i++) {
                if (data[i] != payload[i]) {
                    return false;
                }
            }
            return true;
        }
    }
}
