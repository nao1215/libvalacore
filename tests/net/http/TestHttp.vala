using Vala.Net;
using Vala.Collections;
using Vala.Io;

// Simple mock HTTP server using GSocketListener.
// Listens on a random port and responds with canned responses.
class MockHttpServer : GLib.Object {
    private GLib.SocketListener _listener;
    private GLib.Cancellable _cancellable;
    private uint16 _port;
    private string _response_body;
    private int _response_status;
    private string _response_content_type;
    private string ? _last_request;
    private bool _chunked;

    public MockHttpServer () {
        _listener = new GLib.SocketListener ();
        _cancellable = new GLib.Cancellable ();
        _response_body = "";
        _response_status = 200;
        _response_content_type = "text/plain";
        _last_request = null;
        _chunked = false;

        try {
            _port = (uint16) _listener.add_any_inet_port (null);
        } catch (GLib.Error e) {
            error ("Failed to bind mock server: %s", e.message);
        }
    }

    public uint16 port () {
        return _port;
    }

    public string baseUrl () {
        return "http://127.0.0.1:%u".printf (_port);
    }

    public void setResponse (int status, string contentType, string body) {
        _response_status = status;
        _response_content_type = contentType;
        _response_body = body;
        _chunked = false;
    }

    public void setChunkedResponse (int status, string contentType, string body) {
        _response_status = status;
        _response_content_type = contentType;
        _response_body = body;
        _chunked = true;
    }

    public string ? lastRequest () {
        return _last_request;
    }

    // Accept one request, send the canned response, and close.
    public void serveOne () {
        try {
            var conn = _listener.accept (null, _cancellable);
            var dis = new GLib.DataInputStream (conn.get_input_stream ());
            dis.set_newline_type (GLib.DataStreamNewlineType.CR_LF);

            // Read request line + headers
            var reqBuf = new GLib.StringBuilder ();
            while (true) {
                string ? line = dis.read_line ();
                if (line == null || line.length == 0) {
                    break;
                }
                reqBuf.append (line);
                reqBuf.append ("\n");
            }
            _last_request = reqBuf.str;

            // Read body if Content-Length present
            string req = reqBuf.str;
            int clIdx = req.index_of ("Content-Length:");
            if (clIdx >= 0) {
                string after = req.substring (clIdx + 15).strip ();
                int nl = after.index_of ("\n");
                if (nl >= 0) {
                    after = after.substring (0, nl).strip ();
                }
                int64 cl;
                if (int64.try_parse (after, out cl) && cl > 0) {
                    uint8[] bodyBuf = new uint8[(int) cl];
                    size_t read;
                    dis.read_all (bodyBuf, out read);
                    _last_request += (string) bodyBuf;
                }
            }

            // Build response
            var os = conn.get_output_stream ();
            var resp = new GLib.StringBuilder ();

            if (_chunked) {
                resp.append ("HTTP/1.1 %d OK\r\n".printf (_response_status));
                resp.append ("Content-Type: %s\r\n".printf (_response_content_type));
                resp.append ("Transfer-Encoding: chunked\r\n");
                resp.append ("Connection: close\r\n");
                resp.append ("\r\n");
                // Write body as a single chunk
                resp.append ("%x\r\n".printf (_response_body.length));
                resp.append (_response_body);
                resp.append ("\r\n");
                resp.append ("0\r\n\r\n");
            } else {
                resp.append ("HTTP/1.1 %d OK\r\n".printf (_response_status));
                resp.append ("Content-Type: %s\r\n".printf (_response_content_type));
                resp.append ("Content-Length: %d\r\n".printf (_response_body.length));
                resp.append ("X-Custom: test-value\r\n");
                resp.append ("Connection: close\r\n");
                resp.append ("\r\n");
                resp.append (_response_body);
            }

            os.write (resp.str.data);
            os.flush ();
            conn.close ();
        } catch (GLib.Error e) {
            warning ("Mock server error: %s", e.message);
        }
    }

    public void stop () {
        _cancellable.cancel ();
        _listener.close ();
    }
}

// Serve one request in a background thread, returns the thread.
Thread<void> serveAsync (MockHttpServer server) {
    return new Thread<void> ("mock-server", () => {
        server.serveOne ();
    });
}

void main (string[] args) {
    Test.init (ref args);

    // HttpResponse unit tests (no server needed)
    Test.add_func ("/net/http/testResponseSuccess", testResponseSuccess);
    Test.add_func ("/net/http/testResponseRedirect", testResponseRedirect);
    Test.add_func ("/net/http/testResponseClientError", testResponseClientError);
    Test.add_func ("/net/http/testResponseServerError", testResponseServerError);
    Test.add_func ("/net/http/testResponseBodyText", testResponseBodyText);
    Test.add_func ("/net/http/testResponseBodyBytes", testResponseBodyBytes);
    Test.add_func ("/net/http/testResponseHeaders", testResponseHeaders);
    Test.add_func ("/net/http/testResponseContentLength", testResponseContentLength);
    Test.add_func ("/net/http/testResponseContentType", testResponseContentType);
    Test.add_func ("/net/http/testResponseEmptyBody", testResponseEmptyBody);

    // HttpRequestBuilder unit tests (no server needed)
    Test.add_func ("/net/http/testRequestBuilder", testRequestBuilder);
    Test.add_func ("/net/http/testRequestBuilderBasicAuth", testRequestBuilderBasicAuth);
    Test.add_func ("/net/http/testRequestBuilderBearerToken", testRequestBuilderBearerToken);

    // Mock server integration tests
    Test.add_func ("/net/http/testGet", testGet);
    Test.add_func ("/net/http/testPost", testPost);
    Test.add_func ("/net/http/testPostJson", testPostJson);
    Test.add_func ("/net/http/testPutJson", testPutJson);
    Test.add_func ("/net/http/testPatchJson", testPatchJson);
    Test.add_func ("/net/http/testDelete", testDeleteMethod);
    Test.add_func ("/net/http/testHead", testHead);
    Test.add_func ("/net/http/testGetText", testGetText);
    Test.add_func ("/net/http/testGetBytes", testGetBytes);
    Test.add_func ("/net/http/testPostForm", testPostForm);
    Test.add_func ("/net/http/testDownload", testDownload);
    Test.add_func ("/net/http/testChunkedResponse", testChunkedResponse);
    Test.add_func ("/net/http/testRequestBuilderSend", testRequestBuilderSend);
    Test.add_func ("/net/http/testRequestBuilderQuery", testRequestBuilderQuery);
    Test.add_func ("/net/http/testQueryOnlyUrlPath", testQueryOnlyUrlPath);
    Test.add_func ("/net/http/testRequestBuilderHeaders", testRequestBuilderHeaders);
    Test.add_func ("/net/http/testStatus404", testStatus404);
    Test.add_func ("/net/http/testStatus500", testStatus500);
    Test.add_func ("/net/http/testInvalidUrl", testInvalidUrl);
    Test.add_func ("/net/http/testConnectionRefused", testConnectionRefused);
    Test.add_func ("/net/http/testDownloadInvalid", testDownloadInvalid);

    Test.run ();
}

string rootFor (string name) {
    return "/tmp/valacore/ut/http_" + name;
}

void cleanup (string path) {
    Posix.system ("rm -rf " + path);
}

// --- HttpResponse unit tests ---

void testResponseSuccess () {
    var headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    var resp = new HttpResponse (200, headers, "OK".data);
    assert (resp.statusCode () == 200);
    assert (resp.isSuccess ());
    assert (!resp.isRedirect ());
    assert (!resp.isClientError ());
    assert (!resp.isServerError ());
}

void testResponseRedirect () {
    var headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    var resp = new HttpResponse (301, headers, {});
    assert (resp.isRedirect ());
    assert (!resp.isSuccess ());
}

void testResponseClientError () {
    var headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    var resp = new HttpResponse (404, headers, {});
    assert (resp.isClientError ());
    assert (!resp.isSuccess ());
}

void testResponseServerError () {
    var headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    var resp = new HttpResponse (500, headers, {});
    assert (resp.isServerError ());
    assert (!resp.isSuccess ());
}

void testResponseBodyText () {
    var headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    string content = "Hello, World!";
    var resp = new HttpResponse (200, headers, content.data);
    assert (resp.bodyText () == content);
}

void testResponseBodyBytes () {
    var headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    uint8[] data = { 0x48, 0x69 };
    var resp = new HttpResponse (200, headers, (owned) data);
    uint8[] result = resp.bodyBytes ();
    assert (result.length == 2);
    assert (result[0] == 0x48);
    assert (result[1] == 0x69);
}

void testResponseHeaders () {
    var headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    headers.put ("Content-Type", "text/html");
    headers.put ("X-Custom", "value");
    var resp = new HttpResponse (200, headers, {});

    assert (resp.header ("Content-Type") == "text/html");
    assert (resp.header ("content-type") == "text/html");
    assert (resp.header ("X-Custom") == "value");
    assert (resp.header ("missing") == null);

    HashMap<string, string> all = resp.headers ();
    assert (all.size () == 2);
}

void testResponseContentLength () {
    var headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    headers.put ("Content-Length", "42");
    var resp = new HttpResponse (200, headers, {});
    assert (resp.contentLength () == 42);

    var headers2 = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    var resp2 = new HttpResponse (200, headers2, {});
    assert (resp2.contentLength () == -1);
}

void testResponseContentType () {
    var headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    headers.put ("Content-Type", "application/json");
    var resp = new HttpResponse (200, headers, {});
    assert (resp.contentType () == "application/json");

    var headers2 = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    var resp2 = new HttpResponse (200, headers2, {});
    assert (resp2.contentType () == null);
}

void testResponseEmptyBody () {
    var headers = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    var resp = new HttpResponse (204, headers, {});
    assert (resp.bodyText () == "");
    assert (resp.bodyBytes ().length == 0);
}

// --- HttpRequestBuilder unit tests ---

void testRequestBuilder () {
    var builder = Http.request ("GET", "https://example.com")
                   .header ("Accept", "text/html")
                   .timeoutMillis (5000);
    assert (builder != null);
}

void testRequestBuilderBasicAuth () {
    var builder = Http.request ("GET", "https://example.com")
                   .basicAuth ("user", "pass");
    assert (builder != null);
}

void testRequestBuilderBearerToken () {
    var builder = Http.request ("GET", "https://example.com")
                   .bearerToken ("my-token-123");
    assert (builder != null);
}

// --- Mock server integration tests ---

void testGet () {
    var server = new MockHttpServer ();
    server.setResponse (200, "text/plain", "hello world");
    var t = serveAsync (server);

    var resp = Http.get (server.baseUrl () + "/test");
    t.join ();
    server.stop ();

    assert (resp != null);
    assert (resp.statusCode () == 200);
    assert (resp.isSuccess ());
    assert (resp.bodyText () == "hello world");
    assert (resp.header ("X-Custom") == "test-value");

    string ? req = server.lastRequest ();
    assert (req != null);
    assert (req.contains ("GET /test HTTP/1.1"));
}

void testPost () {
    var server = new MockHttpServer ();
    server.setResponse (201, "text/plain", "created");
    var t = serveAsync (server);

    var resp = Http.post (server.baseUrl () + "/items", "new item");
    t.join ();
    server.stop ();

    assert (resp != null);
    assert (resp.statusCode () == 201);
    assert (resp.bodyText () == "created");

    string ? req = server.lastRequest ();
    assert (req != null);
    assert (req.contains ("POST /items HTTP/1.1"));
    assert (req.contains ("new item"));
}

void testPostJson () {
    var server = new MockHttpServer ();
    server.setResponse (200, "application/json", "{\"ok\":true}");
    var t = serveAsync (server);

    var resp = Http.postJson (server.baseUrl () + "/api", "{\"key\":\"val\"}");
    t.join ();
    server.stop ();

    assert (resp != null);
    assert (resp.isSuccess ());
    assert (resp.bodyText () == "{\"ok\":true}");

    string ? req = server.lastRequest ();
    assert (req != null);
    assert (req.contains ("Content-Type: application/json"));
    assert (req.contains ("{\"key\":\"val\"}"));
}

void testPutJson () {
    var server = new MockHttpServer ();
    server.setResponse (200, "application/json", "{\"updated\":true}");
    var t = serveAsync (server);

    var resp = Http.putJson (server.baseUrl () + "/api/1", "{\"name\":\"new\"}");
    t.join ();
    server.stop ();

    assert (resp != null);
    assert (resp.isSuccess ());

    string ? req = server.lastRequest ();
    assert (req != null);
    assert (req.contains ("PUT /api/1 HTTP/1.1"));
}

void testPatchJson () {
    var server = new MockHttpServer ();
    server.setResponse (200, "application/json", "{\"patched\":true}");
    var t = serveAsync (server);

    var resp = Http.patchJson (server.baseUrl () + "/api/1", "{\"field\":\"val\"}");
    t.join ();
    server.stop ();

    assert (resp != null);
    assert (resp.isSuccess ());

    string ? req = server.lastRequest ();
    assert (req != null);
    assert (req.contains ("PATCH /api/1 HTTP/1.1"));
}

void testDeleteMethod () {
    var server = new MockHttpServer ();
    server.setResponse (204, "text/plain", "");
    var t = serveAsync (server);

    var resp = Http.@delete (server.baseUrl () + "/api/1");
    t.join ();
    server.stop ();

    assert (resp != null);
    assert (resp.statusCode () == 204);

    string ? req = server.lastRequest ();
    assert (req != null);
    assert (req.contains ("DELETE /api/1 HTTP/1.1"));
}

void testHead () {
    var server = new MockHttpServer ();
    server.setResponse (200, "text/plain", "ignored body");
    var t = serveAsync (server);

    var resp = Http.head (server.baseUrl () + "/ping");
    t.join ();
    server.stop ();

    assert (resp != null);
    assert (resp.statusCode () == 200);
    // HEAD should not read body
    assert (resp.bodyBytes ().length == 0);
}

void testGetText () {
    var server = new MockHttpServer ();
    server.setResponse (200, "text/plain", "plain text");
    var t = serveAsync (server);

    string ? text = Http.getText (server.baseUrl () + "/text");
    t.join ();
    server.stop ();

    assert (text == "plain text");
}

void testGetBytes () {
    var server = new MockHttpServer ();
    server.setResponse (200, "application/octet-stream", "binary");
    var t = serveAsync (server);

    uint8[] ? bytes = Http.getBytes (server.baseUrl () + "/bin");
    t.join ();
    server.stop ();

    assert (bytes != null);
    assert (bytes.length == 6);
}

void testPostForm () {
    var server = new MockHttpServer ();
    server.setResponse (200, "text/plain", "ok");
    var t = serveAsync (server);

    var fields = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    fields.put ("key", "value");
    fields.put ("name", "hello world");

    var resp = Http.postForm (server.baseUrl () + "/form", fields);
    t.join ();
    server.stop ();

    assert (resp != null);
    assert (resp.isSuccess ());

    string ? req = server.lastRequest ();
    assert (req != null);
    assert (req.contains ("Content-Type: application/x-www-form-urlencoded"));
}

void testDownload () {
    string root = rootFor ("dl");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    var server = new MockHttpServer ();
    server.setResponse (200, "application/octet-stream", "file-content");
    var t = serveAsync (server);

    bool ok = Http.download (server.baseUrl () + "/file.bin",
                             new Vala.Io.Path (root + "/out.bin"));
    t.join ();
    server.stop ();

    assert (ok);
    assert (Files.exists (new Vala.Io.Path (root + "/out.bin")));

    string ? content = Files.readAllText (new Vala.Io.Path (root + "/out.bin"));
    assert (content == "file-content");

    cleanup (root);
}

void testChunkedResponse () {
    var server = new MockHttpServer ();
    server.setChunkedResponse (200, "text/plain", "chunked-data");
    var t = serveAsync (server);

    var resp = Http.get (server.baseUrl () + "/chunked");
    t.join ();
    server.stop ();

    assert (resp != null);
    assert (resp.isSuccess ());
    assert (resp.bodyText () == "chunked-data");
}

void testRequestBuilderSend () {
    var server = new MockHttpServer ();
    server.setResponse (200, "text/plain", "builder-ok");
    var t = serveAsync (server);

    var resp = Http.request ("GET", server.baseUrl () + "/builder")
                .header ("Accept", "text/plain")
                .timeoutMillis (5000)
                .send ();
    t.join ();
    server.stop ();

    assert (resp != null);
    assert (resp.isSuccess ());
    assert (resp.bodyText () == "builder-ok");

    string ? req = server.lastRequest ();
    assert (req != null);
    assert (req.contains ("Accept: text/plain"));
}

void testRequestBuilderQuery () {
    var server = new MockHttpServer ();
    server.setResponse (200, "text/plain", "query-ok");
    var t = serveAsync (server);

    var resp = Http.request ("GET", server.baseUrl () + "/search")
                .query ("q", "hello world")
                .query ("page", "1")
                .send ();
    t.join ();
    server.stop ();

    assert (resp != null);
    assert (resp.isSuccess ());

    string ? req = server.lastRequest ();
    assert (req != null);
    assert (req.contains ("q=hello"));
    assert (req.contains ("page=1"));
}

void testQueryOnlyUrlPath () {
    var server = new MockHttpServer ();
    server.setResponse (200, "text/plain", "query-only-ok");
    var t = serveAsync (server);

    var resp = Http.get (server.baseUrl () + "?x=1");
    t.join ();
    server.stop ();

    assert (resp != null);
    assert (resp.isSuccess ());

    string ? req = server.lastRequest ();
    assert (req != null);
    assert (req.contains ("GET /?x=1 HTTP/1.1"));
}

void testRequestBuilderHeaders () {
    var server = new MockHttpServer ();
    server.setResponse (200, "text/plain", "headers-ok");
    var t = serveAsync (server);

    var extra = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
    extra.put ("X-First", "one");
    extra.put ("X-Second", "two");

    var resp = Http.request ("GET", server.baseUrl () + "/multi")
                .headers (extra)
                .send ();
    t.join ();
    server.stop ();

    assert (resp != null);
    assert (resp.isSuccess ());

    string ? req = server.lastRequest ();
    assert (req != null);
    assert (req.contains ("X-First: one"));
    assert (req.contains ("X-Second: two"));
}

void testStatus404 () {
    var server = new MockHttpServer ();
    server.setResponse (404, "text/plain", "not found");
    var t = serveAsync (server);

    var resp = Http.get (server.baseUrl () + "/missing");
    t.join ();
    server.stop ();

    assert (resp != null);
    assert (resp.statusCode () == 404);
    assert (resp.isClientError ());
    assert (!resp.isSuccess ());
}

void testStatus500 () {
    var server = new MockHttpServer ();
    server.setResponse (500, "text/plain", "error");
    var t = serveAsync (server);

    var resp = Http.get (server.baseUrl () + "/fail");
    t.join ();
    server.stop ();

    assert (resp != null);
    assert (resp.statusCode () == 500);
    assert (resp.isServerError ());
}

void testInvalidUrl () {
    var resp = Http.get ("not-a-url");
    assert (resp == null);

    var resp2 = Http.get ("ftp://example.com");
    assert (resp2 == null);
}

void testConnectionRefused () {
    // Port 1 should not have anything listening
    var resp = Http.get ("http://127.0.0.1:1/test");
    assert (resp == null);
}

void testDownloadInvalid () {
    string root = rootFor ("download");
    cleanup (root);
    assert (Files.makeDirs (new Vala.Io.Path (root)));

    bool result = Http.download ("http://invalid-host-that-does-not-exist.local/file",
                                 new Vala.Io.Path (root + "/out.bin"));
    assert (!result);
    cleanup (root);
}
