using Vala.Collections;

namespace Vala.Net {
    /**
     * Represents an HTTP response.
     *
     * Provides access to the status code, headers, and body of the
     * response returned by an HTTP request.
     *
     * Example:
     * {{{
     *     var resp = Http.get ("http://localhost:8080/hello");
     *     if (resp.isSuccess ()) {
     *         print (resp.bodyText ());
     *     }
     * }}}
     */
    public class HttpResponse : GLib.Object {
        private int _status_code;
        private HashMap<string, string> _headers;
        private uint8[] _body;

        internal HttpResponse (int status, HashMap<string, string> headers, owned uint8[] body) {
            _status_code = status;
            _headers = headers;
            _body = (owned) body;
        }

        /**
         * Returns the HTTP status code.
         *
         * @return status code (e.g. 200, 404, 500).
         */
        public int statusCode () {
            return _status_code;
        }

        /**
         * Returns true if the status code is 2xx (success).
         *
         * @return true for success status.
         */
        public bool isSuccess () {
            return _status_code >= 200 && _status_code < 300;
        }

        /**
         * Returns true if the status code is 3xx (redirect).
         *
         * @return true for redirect status.
         */
        public bool isRedirect () {
            return _status_code >= 300 && _status_code < 400;
        }

        /**
         * Returns true if the status code is 4xx (client error).
         *
         * @return true for client error status.
         */
        public bool isClientError () {
            return _status_code >= 400 && _status_code < 500;
        }

        /**
         * Returns true if the status code is 5xx (server error).
         *
         * @return true for server error status.
         */
        public bool isServerError () {
            return _status_code >= 500 && _status_code < 600;
        }

        /**
         * Returns the response body as a UTF-8 string.
         *
         * @return body text.
         */
        public string bodyText () {
            if (_body == null || _body.length == 0) {
                return "";
            }
            // Create a null-terminated copy for safe string conversion.
            // The internal byte array may not be null-terminated.
            uint8[] buf = new uint8[_body.length + 1];
            GLib.Memory.copy (buf, _body, _body.length);
            buf[_body.length] = 0;
            return ((string) buf).dup ();
        }

        /**
         * Returns the response body as raw bytes.
         *
         * @return body bytes.
         */
        public uint8[] bodyBytes () {
            return _body;
        }

        /**
         * Returns the value of a response header.
         *
         * @param name header name (case-insensitive lookup).
         * @return header value or null if not present.
         */
        public string ? header (string name) {
            if (_headers == null) {
                return null;
            }
            string lower = name.down ();
            GLib.List<unowned string> keys = _headers.keys ();
            foreach (unowned string key in keys) {
                if (key.down () == lower) {
                    return _headers.get (key);
                }
            }
            return null;
        }

        /**
         * Returns all response headers as a HashMap.
         *
         * @return headers map.
         */
        public HashMap<string, string> headers () {
            return _headers;
        }

        /**
         * Returns the Content-Length header value.
         *
         * @return content length or -1 if not set.
         */
        public int64 contentLength () {
            string ? val = header ("content-length");
            if (val == null) {
                return -1;
            }
            int64 result;
            if (int64.try_parse (val, out result)) {
                return result;
            }
            return -1;
        }

        /**
         * Returns the Content-Type header value.
         *
         * @return content type or null if not set.
         */
        public string ? contentType () {
            return header ("content-type");
        }
    }

    /**
     * Builder for constructing HTTP requests with custom settings.
     *
     * Example:
     * {{{
     *     var resp = Http.request ("POST", "http://localhost:8080/data")
     *         .header ("Authorization", "Bearer token123")
     *         .body ("payload")
     *         .timeoutMillis (5000)
     *         .send ();
     * }}}
     */
    public class HttpRequestBuilder : GLib.Object {
        private string _method;
        private string _url;
        private HashMap<string, string> _headers;
        private string ? _body_text;
        private int _timeout_ms;

        internal HttpRequestBuilder (string method, string url) {
            _method = method;
            _url = url;
            _headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            _body_text = null;
            _timeout_ms = 30000;
        }

        /**
         * Adds a request header.
         *
         * @param name header name.
         * @param value header value.
         * @return this builder for chaining.
         */
        public HttpRequestBuilder header (string name, string value) {
            if (hasUnsafeHeaderChars (name) || hasUnsafeHeaderChars (value)) {
                return this;
            }
            _headers.put (name, value);
            return this;
        }

        /**
         * Adds multiple request headers at once.
         *
         * @param map headers to add.
         * @return this builder for chaining.
         */
        public HttpRequestBuilder headers (HashMap<string, string> map) {
            GLib.List<unowned string> keys = map.keys ();
            foreach (unowned string key in keys) {
                string ? val = map.get (key);
                if (val != null) {
                    if (hasUnsafeHeaderChars (key) || hasUnsafeHeaderChars (val)) {
                        continue;
                    }
                    _headers.put (key, val);
                }
            }
            return this;
        }

        /**
         * Adds a query parameter to the URL.
         *
         * @param key query parameter name.
         * @param value query parameter value.
         * @return this builder for chaining.
         */
        public HttpRequestBuilder query (string key, string value) {
            string encoded_key = GLib.Uri.escape_string (key, null, true);
            string encoded_val = GLib.Uri.escape_string (value, null, true);
            string param = encoded_key + "=" + encoded_val;
            if (_url.contains ("?")) {
                _url += "&" + param;
            } else {
                _url += "?" + param;
            }
            return this;
        }

        /**
         * Sets Basic Authentication header.
         *
         * @param user username.
         * @param password password.
         * @return this builder for chaining.
         */
        public HttpRequestBuilder basicAuth (string user, string password) {
            if (hasUnsafeHeaderChars (user) || hasUnsafeHeaderChars (password)) {
                return this;
            }
            string credentials = user + ":" + password;
            string encoded = GLib.Base64.encode (credentials.data);
            _headers.put ("Authorization", "Basic " + encoded);
            return this;
        }

        /**
         * Sets Bearer token authentication header.
         *
         * @param token bearer token.
         * @return this builder for chaining.
         */
        public HttpRequestBuilder bearerToken (string token) {
            if (hasUnsafeHeaderChars (token)) {
                return this;
            }
            _headers.put ("Authorization", "Bearer " + token);
            return this;
        }

        /**
         * Sets the request timeout in milliseconds.
         *
         * @param ms timeout in milliseconds (default: 30000).
         * @return this builder for chaining.
         */
        public HttpRequestBuilder timeoutMillis (int ms) {
            if (ms <= 0) {
                _timeout_ms = 1000;
            } else {
                _timeout_ms = ms;
            }
            return this;
        }

        /**
         * Sets the request body as a string.
         *
         * @param text body content.
         * @return this builder for chaining.
         */
        public HttpRequestBuilder body (string text) {
            _body_text = text;
            return this;
        }

        /**
         * Sends the constructed request and returns the response.
         *
         * @return HTTP response, or null on network error.
         */
        public HttpResponse ? send () {
            return Http.executeRequest (_method, _url, _headers, _body_text, _timeout_ms);
        }

        private static bool hasUnsafeHeaderChars (string value) {
            for (int i = 0; i < value.length; i++) {
                char c = value[i];
                if (c == '\r' || c == '\n' || (uint) c < 0x20 || c == 0x7f) {
                    return true;
                }
            }
            return false;
        }
    }

    /**
     * Static utility methods for HTTP requests.
     *
     * Provides both shortcut one-liner methods and a request builder
     * for more complex scenarios. Uses GIO SocketClient with raw
     * HTTP/1.1 protocol internally. No external HTTP library required.
     *
     * Example:
     * {{{
     *     // Simple GET
     *     var resp = Http.get ("http://localhost:8080/hello");
     *
     *     // POST with body
     *     var resp = Http.post ("http://localhost:8080/data", "hello");
     *
     *     // Builder pattern
     *     var resp = Http.request ("PUT", "http://localhost:8080/item")
     *         .bearerToken ("my-token")
     *         .body ("update data")
     *         .send ();
     * }}}
     */
    public class Http : GLib.Object {
        private static int DEFAULT_TIMEOUT_MS = 30000;

        /**
         * Sends an HTTP GET request.
         *
         * @param url target URL.
         * @return HTTP response or null on error.
         */
        public static new HttpResponse ? get (string url) {
            return executeRequest ("GET", url, null, null, DEFAULT_TIMEOUT_MS);
        }

        /**
         * Sends an HTTP POST request with a text body.
         *
         * @param url target URL.
         * @param body request body text.
         * @return HTTP response or null on error.
         */
        public static HttpResponse ? post (string url, string body) {
            var headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            headers.put ("Content-Type", "text/plain; charset=utf-8");
            return executeRequest ("POST", url, headers, body, DEFAULT_TIMEOUT_MS);
        }

        /**
         * Sends an HTTP POST request with a JSON body.
         *
         * Sets Content-Type to application/json automatically.
         *
         * @param url target URL.
         * @param jsonBody JSON body string.
         * @return HTTP response or null on error.
         */
        public static HttpResponse ? postJson (string url, string jsonBody) {
            var headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            headers.put ("Content-Type", "application/json; charset=utf-8");
            return executeRequest ("POST", url, headers, jsonBody, DEFAULT_TIMEOUT_MS);
        }

        /**
         * Sends an HTTP PUT request with a JSON body.
         *
         * @param url target URL.
         * @param jsonBody JSON body string.
         * @return HTTP response or null on error.
         */
        public static HttpResponse ? putJson (string url, string jsonBody) {
            var headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            headers.put ("Content-Type", "application/json; charset=utf-8");
            return executeRequest ("PUT", url, headers, jsonBody, DEFAULT_TIMEOUT_MS);
        }

        /**
         * Sends an HTTP PATCH request with a JSON body.
         *
         * @param url target URL.
         * @param jsonBody JSON body string.
         * @return HTTP response or null on error.
         */
        public static HttpResponse ? patchJson (string url, string jsonBody) {
            var headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            headers.put ("Content-Type", "application/json; charset=utf-8");
            return executeRequest ("PATCH", url, headers, jsonBody, DEFAULT_TIMEOUT_MS);
        }

        /**
         * Sends an HTTP DELETE request.
         *
         * @param url target URL.
         * @return HTTP response or null on error.
         */
        public static HttpResponse ? @delete (string url) {
            return executeRequest ("DELETE", url, null, null, DEFAULT_TIMEOUT_MS);
        }

        /**
         * Sends an HTTP HEAD request.
         *
         * @param url target URL.
         * @return HTTP response or null on error.
         */
        public static HttpResponse ? head (string url) {
            return executeRequest ("HEAD", url, null, null, DEFAULT_TIMEOUT_MS);
        }

        /**
         * Sends a GET request and returns the response body as text.
         *
         * @param url target URL.
         * @return body text or null on error.
         */
        public static string ? getText (string url) {
            HttpResponse ? resp = get (url);
            if (resp == null) {
                return null;
            }
            return resp.bodyText ();
        }

        /**
         * Sends a GET request and returns the response body as bytes.
         *
         * @param url target URL.
         * @return body bytes or null on error.
         */
        public static uint8[] ? getBytes (string url) {
            HttpResponse ? resp = get (url);
            if (resp == null) {
                return null;
            }
            return resp.bodyBytes ();
        }

        /**
         * Sends an HTTP POST request with form-encoded body.
         *
         * @param url target URL.
         * @param fields form fields as key-value pairs.
         * @return HTTP response or null on error.
         */
        public static HttpResponse ? postForm (string url, HashMap<string, string> fields) {
            var sb = new GLib.StringBuilder ();
            bool first = true;
            GLib.List<unowned string> keys = fields.keys ();
            foreach (unowned string key in keys) {
                string ? val = fields.get (key);
                if (val == null) {
                    continue;
                }
                if (!first) {
                    sb.append ("&");
                }
                sb.append (GLib.Uri.escape_string (key, null, true));
                sb.append ("=");
                sb.append (GLib.Uri.escape_string (val, null, true));
                first = false;
            }

            var headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            headers.put ("Content-Type", "application/x-www-form-urlencoded");
            return executeRequest ("POST", url, headers, sb.str, DEFAULT_TIMEOUT_MS);
        }

        /**
         * Downloads a file from a URL and saves it to disk.
         *
         * @param url source URL.
         * @param dest destination file path.
         * @return true on success.
         */
        public static bool download (string url, Vala.Io.Path dest) {
            HttpResponse ? resp = get (url);
            if (resp == null || !resp.isSuccess ()) {
                return false;
            }
            uint8[] data = resp.bodyBytes ();
            if (data == null) {
                return false;
            }
            try {
                GLib.FileUtils.set_data (dest.toString (), data);
                return true;
            } catch (GLib.FileError e) {
                return false;
            }
        }

        /**
         * Creates a request builder for custom HTTP requests.
         *
         * @param method HTTP method (GET, POST, PUT, DELETE, etc.).
         * @param url target URL.
         * @return request builder.
         */
        public static HttpRequestBuilder request (string method, string url) {
            return new HttpRequestBuilder (method, url);
        }

        /**
         * Executes an HTTP request using raw GIO socket connection.
         *
         * Builds an HTTP/1.1 request, connects via GSocketClient,
         * and parses the response status line, headers, and body.
         */
        internal static HttpResponse ? executeRequest (string method, string url,
                                                       HashMap<string, string> ? reqHeaders,
                                                       string ? body, int timeout_ms) {
            string host;
            uint16 port;
            string path;
            bool useTls;
            if (!parseUrl (url, out host, out port, out path, out useTls)) {
                return null;
            }

            try {
                var client = new GLib.SocketClient ();
                int effectiveTimeoutMs = timeout_ms;
                if (effectiveTimeoutMs <= 0) {
                    effectiveTimeoutMs = DEFAULT_TIMEOUT_MS;
                }
                client.timeout = (uint) ((effectiveTimeoutMs + 999) / 1000);
                if (useTls) {
                    client.set_tls (true);
                }

                var conn = client.connect_to_host (host, port, null);
                if (conn == null) {
                    return null;
                }

                var reqBuilder = new GLib.StringBuilder ();
                reqBuilder.append ("%s %s HTTP/1.1\r\n".printf (method, path));
                reqBuilder.append ("Host: %s\r\n".printf (host));
                reqBuilder.append ("Connection: close\r\n");

                if (reqHeaders != null) {
                    GLib.List<unowned string> keys = reqHeaders.keys ();
                    foreach (unowned string key in keys) {
                        string ? val = reqHeaders.get (key);
                        if (val != null) {
                            if (hasUnsafeHeaderChars (key) || hasUnsafeHeaderChars (val)) {
                                conn.close ();
                                return null;
                            }
                            reqBuilder.append ("%s: %s\r\n".printf (key, val));
                        }
                    }
                }

                if (body != null && body.length > 0) {
                    reqBuilder.append ("Content-Length: %d\r\n".printf (body.length));
                    reqBuilder.append ("\r\n");
                    reqBuilder.append (body);
                } else {
                    reqBuilder.append ("\r\n");
                }

                var os = conn.get_output_stream ();
                size_t written = 0;
                os.write_all (reqBuilder.str.data, out written);
                os.flush ();

                var dis = new GLib.DataInputStream (conn.get_input_stream ());
                dis.set_newline_type (GLib.DataStreamNewlineType.CR_LF);

                string ? statusLine = dis.read_line ();
                if (statusLine == null) {
                    conn.close ();
                    return null;
                }
                int statusCode = parseStatusCode (statusLine);
                if (statusCode < 0) {
                    conn.close ();
                    return null;
                }

                var respHeaders = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
                int64 contentLen = -1;
                bool chunked = false;

                while (true) {
                    string ? line = dis.read_line ();
                    if (line == null || line.length == 0) {
                        break;
                    }
                    int colonIdx = line.index_of (":");
                    if (colonIdx <= 0) {
                        continue;
                    }
                    string hName = line.substring (0, colonIdx).strip ();
                    string hValue = line.substring (colonIdx + 1).strip ();
                    respHeaders.put (hName, hValue);

                    if (hName.down () == "content-length") {
                        int64 cl;
                        if (int64.try_parse (hValue, out cl)) {
                            contentLen = cl;
                        }
                    }
                    if (hName.down () == "transfer-encoding" && hValue.down ().contains ("chunked")) {
                        chunked = true;
                    }
                }

                uint8[] bodyData = {};
                if (method != "HEAD") {
                    if (chunked) {
                        bodyData = readChunked (dis);
                    } else if (contentLen > int.MAX) {
                        conn.close ();
                        return null;
                    } else if (contentLen > 0) {
                        bodyData = readExact (dis, (int) contentLen);
                    } else if (contentLen == -1) {
                        bodyData = readUntilEof (dis);
                    }
                }

                conn.close ();
                return new HttpResponse (statusCode, respHeaders, (owned) bodyData);
            } catch (GLib.Error e) {
                return null;
            }
        }

        private static bool parseUrl (string url, out string host, out uint16 port,
                                      out string path, out bool useTls) {
            host = "";
            port = 80;
            path = "/";
            useTls = false;

            string rest;
            if (url.has_prefix ("https://")) {
                useTls = true;
                port = 443;
                rest = url.substring (8);
            } else if (url.has_prefix ("http://")) {
                rest = url.substring (7);
            } else {
                return false;
            }

            int slashIdx = rest.index_of ("/");
            string hostPort;
            if (slashIdx >= 0) {
                hostPort = rest.substring (0, slashIdx);
                path = rest.substring (slashIdx);
            } else {
                int queryIdx = rest.index_of ("?");
                if (queryIdx >= 0) {
                    hostPort = rest.substring (0, queryIdx);
                    path = rest.substring (queryIdx);
                } else {
                    hostPort = rest;
                    path = "/";
                }
            }

            if (path.length == 0) {
                path = "/";
            }

            int colonIdx = hostPort.index_of (":");
            if (colonIdx >= 0) {
                host = hostPort.substring (0, colonIdx);
                string portStr = hostPort.substring (colonIdx + 1);
                int64 p;
                if (!int64.try_parse (portStr, out p) || p <= 0 || p >= 65536) {
                    return false;
                }
                port = (uint16) p;
            } else {
                host = hostPort;
            }

            return host.length > 0;
        }

        private static int parseStatusCode (string statusLine) {
            // "HTTP/1.1 200 OK" or "HTTP/1.0 404 Not Found"
            if (!statusLine.has_prefix ("HTTP/")) {
                return -1;
            }
            int spaceIdx = statusLine.index_of (" ");
            if (spaceIdx < 0) {
                return -1;
            }
            string afterVersion = statusLine.substring (spaceIdx + 1).strip ();
            string codeStr;
            int space2 = afterVersion.index_of (" ");
            if (space2 >= 0) {
                codeStr = afterVersion.substring (0, space2);
            } else {
                codeStr = afterVersion;
            }
            int64 code;
            if (int64.try_parse (codeStr, out code)) {
                return (int) code;
            }
            return -1;
        }

        private static uint8[] readExact (GLib.DataInputStream dis, int length) throws GLib.IOError {
            uint8[] buf = new uint8[length];
            int offset = 0;
            while (offset < length) {
                size_t read = 0;
                try {
                    read = dis.read (buf[offset : length]);
                } catch (GLib.IOError e) {
                    throw e;
                }
                if (read == 0) {
                    throw new GLib.IOError.FAILED ("unexpected EOF while reading fixed-size body");
                }
                offset += (int) read;
            }
            return buf;
        }

        private static uint8[] readChunked (GLib.DataInputStream dis) throws GLib.IOError {
            var result = new GLib.ByteArray ();
            while (true) {
                string ? sizeLine = null;
                try {
                    sizeLine = dis.read_line ();
                } catch (GLib.IOError e) {
                    break;
                }
                if (sizeLine == null) {
                    break;
                }
                sizeLine = sizeLine.strip ();
                if (sizeLine.length == 0) {
                    continue;
                }
                string sizeToken = sizeLine;
                int extIdx = sizeToken.index_of (";");
                if (extIdx >= 0) {
                    sizeToken = sizeToken.substring (0, extIdx).strip ();
                }
                int64 chunkSize = 0;
                if (!parseHexInt (sizeToken, out chunkSize)) {
                    break;
                }
                if (chunkSize == 0) {
                    try {
                        dis.read_line ();
                    } catch (GLib.IOError e) {
                        // ignore trailing CRLF read error
                    }
                    break;
                }
                if (chunkSize < 0 || chunkSize > int.MAX) {
                    break;
                }
                uint8[] chunk = readExact (dis, (int) chunkSize);
                result.append (chunk);
                try {
                    dis.read_line ();
                } catch (GLib.IOError e) {
                    break;
                }
            }
            return result.data;
        }

        private static bool parseHexInt (string hex, out int64 result) {
            result = 0;
            string h = hex.strip ().down ();
            if (h.length == 0) {
                return false;
            }
            for (int i = 0; i < h.length; i++) {
                char c = h[i];
                int64 digit;
                if (c >= '0' && c <= '9') {
                    digit = c - '0';
                } else if (c >= 'a' && c <= 'f') {
                    digit = 10 + c - 'a';
                } else {
                    return false;
                }
                result = (result << 4) | digit;
            }
            return true;
        }

        private static uint8[] readUntilEof (GLib.DataInputStream dis) throws GLib.IOError {
            var result = new GLib.ByteArray ();
            uint8[] buf = new uint8[4096];
            while (true) {
                size_t read = 0;
                try {
                    read = dis.read (buf);
                } catch (GLib.IOError e) {
                    break;
                }
                if (read == 0) {
                    break;
                }
                result.append (buf[0 : read]);
            }
            return result.data;
        }

        private static bool hasUnsafeHeaderChars (string value) {
            for (int i = 0; i < value.length; i++) {
                char c = value[i];
                if (c == '\r' || c == '\n' || (uint) c < 0x20 || c == 0x7f) {
                    return true;
                }
            }
            return false;
        }
    }
}
