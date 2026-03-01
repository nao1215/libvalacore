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
         * Parses the response body as JSON.
         *
         * @return parsed JSON value or null on parse error.
         */
        public Vala.Encoding.JsonValue ? json () {
            return Vala.Encoding.Json.parse (bodyText ());
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
        private uint8[] ? _body_bytes;
        private int _timeout_ms;
        private bool _follow_redirects;

        internal HttpRequestBuilder (string method, string url) {
            _method = method;
            _url = url;
            _headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            _body_text = null;
            _body_bytes = null;
            _timeout_ms = 30000;
            _follow_redirects = true;
        }

        /**
         * Adds a request header.
         *
         * @param name header name.
         * @param value header value.
         * @return this builder for chaining.
         */
        public HttpRequestBuilder header (string name, string value) {
            if (Http.hasUnsafeHeaderChars (name) || Http.hasUnsafeHeaderChars (value)) {
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
                    if (Http.hasUnsafeHeaderChars (key) || Http.hasUnsafeHeaderChars (val)) {
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
            if (Http.hasUnsafeHeaderChars (user) || Http.hasUnsafeHeaderChars (password)) {
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
            if (Http.hasUnsafeHeaderChars (token)) {
                return this;
            }
            _headers.put ("Authorization", "Bearer " + token);
            return this;
        }

        /**
         * Sets the request timeout in milliseconds.
         *
         * If ms <= 0, the timeout floor of 1000 ms is applied.
         * Pass a positive value to use a custom timeout.
         *
         * @param ms timeout in milliseconds.
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
            _body_bytes = null;
            return this;
        }

        /**
         * Sets the request body to JSON text.
         *
         * Content-Type is set to application/json automatically.
         *
         * @param value JSON value to serialize.
         * @return this builder for chaining.
         */
        public HttpRequestBuilder json (Vala.Encoding.JsonValue value) {
            _headers.put ("Content-Type", "application/json; charset=utf-8");
            _body_text = Vala.Encoding.Json.stringify (value);
            _body_bytes = null;
            return this;
        }

        /**
         * Sets the request body to URL-encoded form data.
         *
         * Content-Type is set to application/x-www-form-urlencoded.
         *
         * @param fields key-value form fields.
         * @return this builder for chaining.
         */
        public HttpRequestBuilder formData (HashMap<string, string> fields) {
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
            _headers.put ("Content-Type", "application/x-www-form-urlencoded");
            _body_text = sb.str;
            _body_bytes = null;
            return this;
        }

        /**
         * Sets the request body to raw bytes.
         *
         * @param bytes body bytes.
         * @return this builder for chaining.
         */
        public HttpRequestBuilder bytes (uint8[] bytes) {
            _body_bytes = bytes;
            _body_text = null;
            return this;
        }

        /**
         * Enables or disables redirect following.
         *
         * By default redirects are followed up to 10 hops.
         *
         * @param follow true to follow redirects.
         * @return this builder for chaining.
         */
        public HttpRequestBuilder followRedirects (bool follow) {
            _follow_redirects = follow;
            return this;
        }

        /**
         * Sends the constructed request and returns the response.
         *
         * @return HTTP response, or null on network error.
         */
        public HttpResponse ? send () {
            return Http.executeRequest (_method,
                                        _url,
                                        _headers,
                                        _body_text,
                                        _body_bytes,
                                        _timeout_ms,
                                        _follow_redirects,
                                        10);
        }
    }

    /**
     * Base URL HTTP client with reusable defaults.
     */
    public class HttpClient : GLib.Object {
        private string _base_url;
        private HashMap<string, string> _default_headers;
        private int _default_timeout_ms;
        private Retry ? _retry;

        internal HttpClient (string baseUrl) {
            _base_url = baseUrl;
            _default_headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            _default_timeout_ms = 30000;
            _retry = null;
        }

        /**
         * Adds a default header for all requests.
         *
         * @param name header name.
         * @param value header value.
         * @return this client.
         */
        public HttpClient defaultHeader (string name, string value) {
            if (Http.hasUnsafeHeaderChars (name) || Http.hasUnsafeHeaderChars (value)) {
                return this;
            }
            _default_headers.put (name, value);
            return this;
        }

        /**
         * Sets the default timeout for this client.
         *
         * @param timeout timeout duration.
         * @return this client.
         */
        public HttpClient defaultTimeout (Vala.Time.Duration timeout) {
            int64 millis = timeout.toMillis ();
            if (millis <= 0) {
                _default_timeout_ms = 1000;
            } else if (millis > int.MAX) {
                _default_timeout_ms = int.MAX;
            } else {
                _default_timeout_ms = (int) millis;
            }
            return this;
        }

        /**
         * Sets retry strategy used by this client.
         *
         * @param retry retry policy.
         * @return this client.
         */
        public HttpClient withRetry (Retry retry) {
            _retry = retry;
            return this;
        }

        /**
         * Sends GET request with baseUrl + path.
         *
         * @param path request path.
         * @return response or null.
         */
        public new HttpResponse ? get (string path) {
            return execute ("GET", path, null, null, null);
        }

        /**
         * Sends POST request with JSON body.
         *
         * @param path request path.
         * @param body JSON body.
         * @return response or null.
         */
        public HttpResponse ? postJson (string path, Vala.Encoding.JsonValue body) {
            var headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            headers.put ("Content-Type", "application/json; charset=utf-8");
            return execute ("POST", path, headers, Vala.Encoding.Json.stringify (body), null);
        }

        private HttpResponse ? execute (string method,
                                        string path,
                                        HashMap<string, string> ? headers,
                                        string ? body_text,
                                        uint8[] ? body_bytes) {
            string url = Http.resolveClientUrl (_base_url, path);
            var mergedHeaders = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            GLib.List<unowned string> defaultKeys = _default_headers.keys ();
            foreach (unowned string key in defaultKeys) {
                string ? val = _default_headers.get (key);
                if (val != null) {
                    mergedHeaders.put (key, val);
                }
            }
            if (headers != null) {
                GLib.List<unowned string> keys = headers.keys ();
                foreach (unowned string key in keys) {
                    string ? val = headers.get (key);
                    if (val != null) {
                        mergedHeaders.put (key, val);
                    }
                }
            }

            if (_retry != null) {
                return _retry.retryResult<HttpResponse> (() => {
                    return Http.executeRequest (method,
                                                url,
                                                mergedHeaders,
                                                body_text,
                                                body_bytes,
                                                _default_timeout_ms,
                                                true,
                                                10);
                });
            }
            return Http.executeRequest (method,
                                        url,
                                        mergedHeaders,
                                        body_text,
                                        body_bytes,
                                        _default_timeout_ms,
                                        true,
                                        10);
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
         * Creates an HttpClient bound to a base URL.
         *
         * @param baseUrl base URL (for example, api.example.com over HTTPS).
         * @return HttpClient instance.
         */
        public static HttpClient client (string baseUrl) {
            return new HttpClient (baseUrl);
        }

        /**
         * Sends an HTTP GET request.
         *
         * @param url target URL.
         * @return HTTP response or null on error.
         */
        public static new HttpResponse ? get (string url) {
            return executeRequest ("GET", url, null, null, null, DEFAULT_TIMEOUT_MS, true, 10);
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
            return executeRequest ("POST", url, headers, body, null, DEFAULT_TIMEOUT_MS, true, 10);
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
            return executeRequest ("POST", url, headers, jsonBody, null, DEFAULT_TIMEOUT_MS, true, 10);
        }

        /**
         * Sends an HTTP POST request with a JSON value.
         *
         * @param url target URL.
         * @param jsonBody JSON body.
         * @return HTTP response or null on error.
         */
        public static HttpResponse ? postJsonValue (string url, Vala.Encoding.JsonValue jsonBody) {
            return postJson (url, Vala.Encoding.Json.stringify (jsonBody));
        }

        /**
         * Sends an HTTP POST request with a binary body.
         *
         * @param url target URL.
         * @param body request body bytes.
         * @return HTTP response or null on error.
         */
        public static HttpResponse ? postBytes (string url, uint8[] body) {
            var headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            headers.put ("Content-Type", "application/octet-stream");
            return executeRequest ("POST", url, headers, null, body, DEFAULT_TIMEOUT_MS, true, 10);
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
            return executeRequest ("PUT", url, headers, jsonBody, null, DEFAULT_TIMEOUT_MS, true, 10);
        }

        /**
         * Sends an HTTP PUT request with a JSON value.
         *
         * @param url target URL.
         * @param jsonBody JSON body.
         * @return HTTP response or null on error.
         */
        public static HttpResponse ? putJsonValue (string url, Vala.Encoding.JsonValue jsonBody) {
            return putJson (url, Vala.Encoding.Json.stringify (jsonBody));
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
            return executeRequest ("PATCH", url, headers, jsonBody, null, DEFAULT_TIMEOUT_MS, true, 10);
        }

        /**
         * Sends an HTTP PATCH request with a JSON value.
         *
         * @param url target URL.
         * @param jsonBody JSON body.
         * @return HTTP response or null on error.
         */
        public static HttpResponse ? patchJsonValue (string url, Vala.Encoding.JsonValue jsonBody) {
            return patchJson (url, Vala.Encoding.Json.stringify (jsonBody));
        }

        /**
         * Sends an HTTP DELETE request.
         *
         * @param url target URL.
         * @return HTTP response or null on error.
         */
        public static HttpResponse ? @delete (string url) {
            return executeRequest ("DELETE", url, null, null, null, DEFAULT_TIMEOUT_MS, true, 10);
        }

        /**
         * Sends an HTTP HEAD request.
         *
         * @param url target URL.
         * @return HTTP response or null on error.
         */
        public static HttpResponse ? head (string url) {
            return executeRequest ("HEAD", url, null, null, null, DEFAULT_TIMEOUT_MS, true, 10);
        }

        /**
         * Sends a GET request and parses the response body as JSON.
         *
         * @param url target URL.
         * @return parsed JSON value or null on error.
         */
        public static Vala.Encoding.JsonValue ? getJson (string url) {
            HttpResponse ? resp = get (url);
            if (resp == null) {
                return null;
            }
            return Vala.Encoding.Json.parse (resp.bodyText ());
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
            return executeRequest ("POST", url, headers, sb.str, null, DEFAULT_TIMEOUT_MS, true, 10);
        }

        /**
         * Downloads a file from a URL and saves it to disk.
         *
         * @param url source URL.
         * @param dest destination file path.
         * @return true on success.
         */
        public static bool download (string url, Vala.Io.Path dest) {
            try {
                string host;
                uint16 port;
                string path;
                bool useTls;
                if (!parseUrl (url, out host, out port, out path, out useTls)) {
                    return false;
                }

                var client = new GLib.SocketClient ();
                client.timeout = (uint) ((DEFAULT_TIMEOUT_MS + 999) / 1000);
                if (useTls) {
                    client.set_tls (true);
                }

                var conn = client.connect_to_host (host, port, null);
                if (conn == null) {
                    return false;
                }

                var reqBuilder = new GLib.StringBuilder ();
                reqBuilder.append ("GET %s HTTP/1.1\r\n".printf (path));
                reqBuilder.append ("Host: %s\r\n".printf (host));
                reqBuilder.append ("Connection: close\r\n");
                reqBuilder.append ("\r\n");

                var os = conn.get_output_stream ();
                size_t reqWritten = 0;
                os.write_all (reqBuilder.str.data, out reqWritten);
                os.flush ();

                var dis = new GLib.DataInputStream (conn.get_input_stream ());
                dis.set_newline_type (GLib.DataStreamNewlineType.CR_LF);
                string ? statusLine = dis.read_line ();
                if (statusLine == null) {
                    conn.close ();
                    return false;
                }
                int statusCode = parseStatusCode (statusLine);
                if (statusCode < 200 || statusCode >= 300) {
                    conn.close ();
                    return false;
                }

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

                GLib.File outFile = GLib.File.new_for_path (dest.toString ());
                var outStream = outFile.replace (null,
                                                 false,
                                                 GLib.FileCreateFlags.REPLACE_DESTINATION,
                                                 null);
                if (chunked) {
                    copyChunkedToStream (dis, outStream);
                } else if (contentLen > 0) {
                    copyFixedLengthToStream (dis, outStream, contentLen);
                } else if (contentLen == -1) {
                    copyUntilEofToStream (dis, outStream);
                }
                outStream.close ();
                conn.close ();
                return true;
            } catch (GLib.Error e) {
                stderr.printf ("Http.download failed for %s: %s\n", url, e.message);
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
        internal static HttpResponse ? executeRequest (string method,
                                                       string url,
                                                       HashMap<string, string> ? reqHeaders,
                                                       string ? body_text,
                                                       uint8[] ? body_bytes,
                                                       int timeout_ms,
                                                       bool follow_redirects = true,
                                                       int max_redirects = 10) {
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

                int body_len = 0;
                if (body_bytes != null) {
                    body_len = body_bytes.length;
                } else if (body_text != null) {
                    body_len = body_text.length;
                }
                if (body_len > 0) {
                    reqBuilder.append ("Content-Length: %d\r\n".printf (body_len));
                }
                reqBuilder.append ("\r\n");

                var os = conn.get_output_stream ();
                size_t written = 0;
                os.write_all (reqBuilder.str.data, out written);
                if (body_bytes != null && body_bytes.length > 0) {
                    size_t body_written = 0;
                    os.write_all (body_bytes, out body_written);
                } else if (body_text != null && body_text.length > 0) {
                    uint8[] text_bytes = body_text.data;
                    size_t body_written = 0;
                    os.write_all (text_bytes[0 : body_len], out body_written);
                }
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
                if (method != "HEAD" && method != "head") {
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

                if (follow_redirects && max_redirects > 0
                    && statusCode >= 300 && statusCode < 400) {
                    string ? location = headerValueIgnoreCase (respHeaders, "location");
                    if (location != null && location.length > 0) {
                        string nextUrl = resolveRedirectUrl (url, location);
                        if (nextUrl.length > 0) {
                            bool switchToGet = (statusCode == 301 || statusCode == 302 || statusCode == 303)
                                               && !(method == "GET" || method == "HEAD");
                            string nextMethod = switchToGet ? "GET" : method;
                            string ? nextBodyText = switchToGet ? null : body_text;
                            uint8[] ? nextBodyBytes = switchToGet ? null : body_bytes;
                            HashMap<string, string> ? nextHeaders = sanitizeRedirectHeaders (
                                url,
                                nextUrl,
                                reqHeaders,
                                switchToGet,
                                nextBodyText,
                                nextBodyBytes
                            );
                            conn.close ();
                            return executeRequest (nextMethod,
                                                   nextUrl,
                                                   nextHeaders,
                                                   nextBodyText,
                                                   nextBodyBytes,
                                                   timeout_ms,
                                                   follow_redirects,
                                                   max_redirects - 1);
                        }
                    }
                }

                conn.close ();
                return new HttpResponse (statusCode, respHeaders, (owned) bodyData);
            } catch (GLib.Error e) {
                stderr.printf ("Http.executeRequest failed for %s %s: %s\n",
                               method,
                               url,
                               e.message);
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
                    path = "/" + rest.substring (queryIdx);
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

        internal static string resolveClientUrl (string baseUrl, string path) {
            string p = path.strip ();
            if (p.has_prefix ("http://") || p.has_prefix ("https://")) {
                return p;
            }
            if (p.length == 0) {
                return baseUrl;
            }
            if (baseUrl.has_suffix ("/") && p.has_prefix ("/")) {
                return baseUrl + p.substring (1);
            }
            if (!baseUrl.has_suffix ("/") && !p.has_prefix ("/")) {
                return baseUrl + "/" + p;
            }
            return baseUrl + p;
        }

        private static string ? headerValueIgnoreCase (HashMap<string, string> headers, string name) {
            string target = name.down ();
            GLib.List<unowned string> keys = headers.keys ();
            foreach (unowned string key in keys) {
                if (key.down () == target) {
                    return headers.get (key);
                }
            }
            return null;
        }

        private static string resolveRedirectUrl (string currentUrl, string location) {
            string loc = location.strip ();
            if (loc.has_prefix ("http://") || loc.has_prefix ("https://")) {
                return loc;
            }

            string host;
            uint16 port;
            string path;
            bool useTls;
            if (!parseUrl (currentUrl, out host, out port, out path, out useTls)) {
                return "";
            }

            string scheme = useTls ? "https://" : "http://";
            string schemeName = useTls ? "https" : "http";
            bool defaultPort = (useTls && port == 443) || (!useTls && port == 80);
            string authority = defaultPort ? host : "%s:%u".printf (host, port);

            if (loc.has_prefix ("//")) {
                return schemeName + ":" + loc;
            }
            if (loc.has_prefix ("/")) {
                return scheme + authority + loc;
            }
            if (loc.has_prefix ("?")) {
                int qIdx = path.index_of ("?");
                string basePath = qIdx >= 0 ? path.substring (0, qIdx) : path;
                if (basePath.length == 0) {
                    basePath = "/";
                }
                return scheme + authority + basePath + loc;
            }

            string baseDir = path;
            int q = baseDir.index_of ("?");
            if (q >= 0) {
                baseDir = baseDir.substring (0, q);
            }
            int lastSlash = baseDir.last_index_of ("/");
            if (lastSlash >= 0) {
                baseDir = baseDir.substring (0, lastSlash + 1);
            } else {
                baseDir = "/";
            }
            return scheme + authority + baseDir + loc;
        }

        private static HashMap<string, string> ? sanitizeRedirectHeaders (string currentUrl,
                                                                          string nextUrl,
                                                                          HashMap<string, string> ? reqHeaders,
                                                                          bool switchToGet,
                                                                          string ? nextBodyText,
                                                                          uint8[] ? nextBodyBytes) {
            if (reqHeaders == null) {
                return null;
            }

            var nextHeaders = copyHeaders (reqHeaders);
            if (crossesOrigin (currentUrl, nextUrl)) {
                removeHeaderIgnoreCase (nextHeaders, "Authorization");
                removeHeaderIgnoreCase (nextHeaders, "Cookie");
                removeHeaderIgnoreCase (nextHeaders, "Proxy-Authorization");
            }

            if (switchToGet || (nextBodyText == null && nextBodyBytes == null)) {
                removeHeaderIgnoreCase (nextHeaders, "Content-Length");
                removeHeaderIgnoreCase (nextHeaders, "Content-Type");
                removeHeaderIgnoreCase (nextHeaders, "Transfer-Encoding");
            }
            return nextHeaders;
        }

        private static HashMap<string, string> copyHeaders (HashMap<string, string> src) {
            var copy = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            GLib.List<unowned string> keys = src.keys ();
            foreach (unowned string key in keys) {
                string ? value = src.get (key);
                if (value != null) {
                    copy.put (key, value);
                }
            }
            return copy;
        }

        private static void removeHeaderIgnoreCase (HashMap<string, string> headers, string name) {
            string target = name.down ();
            GLib.List<unowned string> keys = headers.keys ();
            string[] removeKeys = {};
            foreach (unowned string key in keys) {
                if (key.down () == target) {
                    removeKeys += key;
                }
            }
            for (int i = 0; i < removeKeys.length; i++) {
                headers.remove (removeKeys[i]);
            }
        }

        private static bool crossesOrigin (string currentUrl, string nextUrl) {
            string currentOrigin;
            string nextOrigin;
            if (!extractOrigin (currentUrl, out currentOrigin)) {
                return false;
            }
            if (!extractOrigin (nextUrl, out nextOrigin)) {
                return false;
            }
            return currentOrigin != nextOrigin;
        }

        private static bool extractOrigin (string url, out string origin) {
            origin = "";
            string host;
            uint16 port;
            string path;
            bool useTls;
            if (!parseUrl (url, out host, out port, out path, out useTls)) {
                return false;
            }
            string scheme = useTls ? "https" : "http";
            origin = "%s://%s:%u".printf (scheme, host.down (), port);
            return true;
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
                read = dis.read (buf[offset : length]);
                if (read == 0) {
                    throw new GLib.IOError.FAILED ("unexpected EOF while reading fixed-size body");
                }
                offset += (int) read;
            }
            return buf;
        }

        private static void copyFixedLengthToStream (GLib.DataInputStream dis,
                                                     GLib.OutputStream outStream,
                                                     int64 length) throws GLib.IOError {
            int64 remaining = length;
            uint8[] buf = new uint8[8192];
            while (remaining > 0) {
                int requestLen = (int) ((remaining > buf.length) ? buf.length : remaining);
                size_t read = dis.read (buf[0 : requestLen]);
                if (read == 0) {
                    throw new GLib.IOError.FAILED ("unexpected EOF while downloading fixed-size body");
                }
                size_t written = 0;
                outStream.write_all (buf[0 : read], out written);
                remaining -= (int64) read;
            }
        }

        private static void copyChunkedToStream (GLib.DataInputStream dis,
                                                 GLib.OutputStream outStream)
        throws GLib.IOError {
            while (true) {
                string ? sizeLine = dis.read_line ();
                if (sizeLine == null) {
                    throw new GLib.IOError.FAILED ("unexpected EOF while reading chunk size");
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
                    throw new GLib.IOError.FAILED ("invalid chunk size");
                }
                if (chunkSize == 0) {
                    while (true) {
                        string ? trailer = dis.read_line ();
                        if (trailer == null) {
                            throw new GLib.IOError.FAILED ("unexpected EOF while reading chunk trailer");
                        }
                        if (trailer.length == 0) {
                            return;
                        }
                    }
                }
                if (chunkSize < 0) {
                    throw new GLib.IOError.FAILED ("chunk size out of range");
                }

                copyFixedLengthToStream (dis, outStream, chunkSize);
                string ? chunkTerminator = dis.read_line ();
                if (chunkTerminator == null || chunkTerminator.length != 0) {
                    throw new GLib.IOError.FAILED ("invalid chunk terminator");
                }
            }
        }

        private static uint8[] readChunked (GLib.DataInputStream dis) throws GLib.IOError {
            var result = new GLib.ByteArray ();
            while (true) {
                string ? sizeLine = dis.read_line ();
                if (sizeLine == null) {
                    throw new GLib.IOError.FAILED ("unexpected EOF while reading chunk size");
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
                    throw new GLib.IOError.FAILED ("invalid chunk size");
                }
                if (chunkSize == 0) {
                    while (true) {
                        string ? trailer = dis.read_line ();
                        if (trailer == null) {
                            throw new GLib.IOError.FAILED ("unexpected EOF while reading chunk trailer");
                        }
                        if (trailer.length == 0) {
                            break;
                        }
                    }
                    break;
                }
                if (chunkSize < 0 || chunkSize > int.MAX) {
                    throw new GLib.IOError.FAILED ("chunk size out of range");
                }
                uint8[] chunk = readExact (dis, (int) chunkSize);
                result.append (chunk);
                string ? chunkTerminator = dis.read_line ();
                if (chunkTerminator == null || chunkTerminator.length != 0) {
                    throw new GLib.IOError.FAILED ("invalid chunk terminator");
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
                if (result > (int64.MAX >> 4)) {
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
                read = dis.read (buf);
                if (read == 0) {
                    break;
                }
                result.append (buf[0 : read]);
            }
            return result.data;
        }

        private static void copyUntilEofToStream (GLib.DataInputStream dis,
                                                  GLib.OutputStream outStream)
        throws GLib.IOError {
            uint8[] buf = new uint8[8192];
            while (true) {
                size_t read = dis.read (buf);
                if (read == 0) {
                    break;
                }
                size_t written = 0;
                outStream.write_all (buf[0 : read], out written);
            }
        }

        internal static bool hasUnsafeHeaderChars (string value) {
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
