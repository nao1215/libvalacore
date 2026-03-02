using Vala.Collections;

namespace Vala.Net {
    /**
     * Recoverable URL parse errors.
     */
    public errordomain NetUrlError {
        INVALID_ARGUMENT,
        PARSE
    }

    /**
     * Immutable URL value object.
     */
    public class Url : GLib.Object {
        private GLib.Uri _uri;

        private Url.from_uri (GLib.Uri uri) {
            _uri = uri;
        }

        /**
         * Parses URL text.
         *
         * @param url URL text.
         * @return Result.ok(parsed URL object), or
         *         Result.error(NetUrlError.INVALID_ARGUMENT/PARSE) on invalid input.
         */
        public static Result<Url, GLib.Error> parse (string url) {
            if (url == "") {
                return Result.error<Url, GLib.Error> (
                    new NetUrlError.INVALID_ARGUMENT ("url must not be empty")
                );
            }
            try {
                GLib.Uri uri = GLib.Uri.parse (url, GLib.UriFlags.NONE);
                return Result.ok<Url, GLib.Error> (new Url.from_uri (uri));
            } catch (GLib.UriError e) {
                return Result.error<Url, GLib.Error> (
                    new NetUrlError.PARSE ("failed to parse URL: %s".printf (url))
                );
            }
        }

        /**
         * Returns URL scheme.
         *
         * @return scheme value.
         */
        public string scheme () {
            return _uri.get_scheme ();
        }

        /**
         * Returns host.
         *
         * @return host value or empty string.
         */
        public string host () {
            string ? host = _uri.get_host ();
            return host ?? "";
        }

        /**
         * Returns port number.
         *
         * Returns -1 if the port is not explicitly specified.
         *
         * @return port number.
         */
        public int port () {
            return _uri.get_port ();
        }

        /**
         * Returns path.
         *
         * @return path value.
         */
        public string path () {
            return _uri.get_path ();
        }

        /**
         * Returns query string.
         *
         * @return query value or empty string.
         */
        public string query () {
            string ? query = _uri.get_query ();
            return query ?? "";
        }

        /**
         * Returns fragment text.
         *
         * @return fragment value or empty string.
         */
        public string fragment () {
            string ? fragment = _uri.get_fragment ();
            return fragment ?? "";
        }

        /**
         * Returns normalized URL text.
         *
         * @return URL text.
         */
        public string toString () {
            return _uri.to_string ();
        }
    }
}
