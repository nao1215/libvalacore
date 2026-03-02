using Vala.Io;
using Vala.Lang;
using Vala.Collections;

namespace Vala.Compress {
    /**
     * Error domain for zlib operations.
     */
    public errordomain ZlibError {
        INVALID_ARGUMENT,
        NOT_FOUND,
        IO,
        PARSE
    }

    /**
     * Static utility methods for Zlib compression and decompression.
     */
    public class Zlib : GLib.Object {
        /**
         * Compresses bytes with Zlib format.
         *
         * @param data source bytes.
         * @return Result.ok(compressed bytes), or Result.error(ZlibError.IO) on conversion failure.
         */
        public static Result<GLib.Bytes, GLib.Error> compress (uint8[] data) {
            if (data.length == 0) {
                return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (new uint8[0]));
            }
            uint8[] ? compressed = convert (
                data,
                new GLib.ZlibCompressor (GLib.ZlibCompressorFormat.ZLIB, -1)
            );
            if (compressed == null) {
                return Result.error<GLib.Bytes, GLib.Error> (
                    new ZlibError.IO ("failed to compress zlib payload")
                );
            }
            return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (compressed));
        }

        /**
         * Decompresses Zlib bytes.
         *
         * @param data compressed bytes.
         * @return Result.ok(decompressed bytes), or Result.error(ZlibError.PARSE) on invalid input.
         */
        public static Result<GLib.Bytes, GLib.Error> decompress (uint8[] data) {
            if (data.length == 0) {
                return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (new uint8[0]));
            }
            uint8[] ? plain = convert (
                data,
                new GLib.ZlibDecompressor (GLib.ZlibCompressorFormat.ZLIB)
            );
            if (plain == null) {
                return Result.error<GLib.Bytes, GLib.Error> (
                    new ZlibError.PARSE ("invalid zlib payload")
                );
            }
            return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (plain));
        }

        /**
         * Compresses a source file and writes it to destination.
         *
         * @param src source file path.
         * @param dst destination file path.
         * @return Result.ok(true) on success, or Result.error(ZlibError) on failure.
         */
        public static Result<bool ?, GLib.Error> compressFile (Vala.Io.Path src, Vala.Io.Path dst) {
            if (Objects.isNull (src) || Objects.isNull (dst)) {
                return Result.error<bool ?, GLib.Error> (
                    new ZlibError.INVALID_ARGUMENT ("source and destination must not be null")
                );
            }

            uint8[] ? bytes = Files.readBytes (src);
            if (bytes == null) {
                return Result.error<bool ?, GLib.Error> (
                    new ZlibError.NOT_FOUND ("source file not found or unreadable: %s".printf (src.toString ()))
                );
            }

            uint8[] ? compressed = convert (
                bytes,
                new GLib.ZlibCompressor (GLib.ZlibCompressorFormat.ZLIB, -1)
            );
            if (compressed == null) {
                return Result.error<bool ?, GLib.Error> (
                    new ZlibError.IO ("failed to compress source file: %s".printf (src.toString ()))
                );
            }
            if (!Files.writeBytes (dst, compressed)) {
                return Result.error<bool ?, GLib.Error> (
                    new ZlibError.IO ("failed to write compressed file: %s".printf (dst.toString ()))
                );
            }
            return Result.ok<bool ?, GLib.Error> (true);
        }

        /**
         * Decompresses a source zlib file and writes it to destination.
         *
         * @param src source compressed file path.
         * @param dst destination plain file path.
         * @return Result.ok(true) on success, or Result.error(ZlibError) on failure.
         */
        public static Result<bool ?, GLib.Error> decompressFile (Vala.Io.Path src, Vala.Io.Path dst) {
            if (Objects.isNull (src) || Objects.isNull (dst)) {
                return Result.error<bool ?, GLib.Error> (
                    new ZlibError.INVALID_ARGUMENT ("source and destination must not be null")
                );
            }

            uint8[] ? bytes = Files.readBytes (src);
            if (bytes == null) {
                return Result.error<bool ?, GLib.Error> (
                    new ZlibError.NOT_FOUND ("source file not found or unreadable: %s".printf (src.toString ()))
                );
            }

            var plain = decompress (bytes);
            if (plain.isError ()) {
                return Result.error<bool ?, GLib.Error> (plain.unwrapError ());
            }
            if (!Files.writeBytes (dst, plain.unwrap ().get_data ())) {
                return Result.error<bool ?, GLib.Error> (
                    new ZlibError.IO ("failed to write decompressed file: %s".printf (dst.toString ()))
                );
            }
            return Result.ok<bool ?, GLib.Error> (true);
        }

        /**
         * Compresses bytes with explicit compression level.
         *
         * @param data source bytes.
         * @param level compression level in range [1, 9].
         * @return Result.ok(compressed bytes), or Result.error(ZlibError) on failure.
         */
        public static Result<GLib.Bytes, GLib.Error> compressLevel (uint8[] data, int level) {
            if (level < 1 || level > 9) {
                return Result.error<GLib.Bytes, GLib.Error> (
                    new ZlibError.INVALID_ARGUMENT ("compression level must be in [1, 9]: %d".printf (level))
                );
            }
            if (data.length == 0) {
                return Result.ok<GLib.Bytes, GLib.Error> (new GLib.Bytes (new uint8[0]));
            }

            uint8[] ? compressed = convert (
                data,
                new GLib.ZlibCompressor (GLib.ZlibCompressorFormat.ZLIB, level)
            );
            if (compressed == null) {
                return Result.error<GLib.Bytes, GLib.Error> (
                    new ZlibError.IO ("failed to compress zlib payload with level=%d".printf (level))
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
                return new uint8[0];
            }
            return output.steal ();
        }

        private static unowned uint8[] tailBytes (uint8[] data, int offset) {
            if (offset >= data.length) {
                return data[data.length : data.length];
            }
            return data[offset : data.length];
        }
    }
}
