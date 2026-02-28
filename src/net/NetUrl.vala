namespace Vala.Net {
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
         * @return parsed URL object or null.
         */
        public static Url? parse (string url) {
            try {
                GLib.Uri uri = GLib.Uri.parse (url, GLib.UriFlags.NONE);
                return new Url.from_uri (uri);
            } catch (GLib.UriError e) {
                return null;
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
            string? host = _uri.get_host ();
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
            string? query = _uri.get_query ();
            return query ?? "";
        }

        /**
         * Returns fragment text.
         *
         * @return fragment value or empty string.
         */
        public string fragment () {
            string? fragment = _uri.get_fragment ();
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
