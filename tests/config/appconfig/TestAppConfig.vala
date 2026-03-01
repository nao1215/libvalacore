using Vala.Config;
using Vala.Io;
using Vala.Time;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/config/appconfig/testLoadFile", testLoadFile);
    Test.add_func ("/config/appconfig/testPrecedence", testPrecedence);
    Test.add_func ("/config/appconfig/testTypedGetters", testTypedGetters);
    Test.add_func ("/config/appconfig/testLoadStandardPath", testLoadStandardPath);

    Test.run ();
}

void testLoadFile () {
    Vala.Io.Path ? file = Files.tempFile ("appconfig", ".properties");
    assert (file != null);

    try {
        assert (Files.writeText (file, "host=127.0.0.1\nport=8080\n") == true);

        AppConfig config = AppConfig.loadFile (file);
        assert (config.getString ("host", "") == "127.0.0.1");
        assert (config.getInt ("port", 0) == 8080);
        assert (config.sourceOf ("host") == "file");
        assert (config.sourceOf ("missing") == "default");
    } finally {
        if (file != null) {
            Files.remove (file);
        }
    }
}

void testPrecedence () {
    Vala.Io.Path ? file = Files.tempFile ("appconfig-priority", ".properties");
    assert (file != null);

    string envKey = "MYAPP_HOST";
    GLib.Environment.set_variable (envKey, "env-host", true);

    try {
        assert (Files.writeText (file, "host=file-host\n") == true);

        string[] cli = { "--host=cli-host" };
        AppConfig config = AppConfig.loadFile (file)
                            .withEnvPrefix ("MYAPP_")
                            .withCliArgs (cli);

        assert (config.getString ("host", "") == "cli-host");
        assert (config.sourceOf ("host") == "cli");

        string[] emptyCli = {};
        config.withCliArgs (emptyCli);
        assert (config.getString ("host", "") == "env-host");
        assert (config.sourceOf ("host") == "env");

        GLib.Environment.unset_variable (envKey);
        assert (config.getString ("host", "") == "file-host");
        assert (config.sourceOf ("host") == "file");
    } finally {
        GLib.Environment.unset_variable (envKey);
        if (file != null) {
            Files.remove (file);
        }
    }
}

void testTypedGetters () {
    AppConfig config = new AppConfig ();

    string[] cli = {
        "--workers=16",
        "--enabled=true",
        "--debug",
        "--timeout=2m",
        "--invalid_int=abc",
        "--invalid_bool=maybe",
        "--invalid_duration=xxx"
    };
    config.withCliArgs (cli);

    assert (config.getInt ("workers", 0) == 16);
    assert (config.getBool ("enabled", false) == true);
    assert (config.getBool ("debug", false) == true);

    Duration timeout = config.getDuration ("timeout", Duration.ofSeconds (1));
    assert (timeout.toSeconds () == 120);

    assert (config.getInt ("invalid_int", 7) == 7);
    assert (config.getBool ("invalid_bool", false) == false);

    Duration fallback = Duration.ofSeconds (9);
    assert (config.getDuration ("invalid_duration", fallback).toSeconds () == 9);

    assert (config.require ("workers") == "16");
}

void testLoadStandardPath () {
    int64 now = GLib.get_real_time ();
    string appName = "appconfig-ut-%s".printf (now.to_string ());
    Vala.Io.Path file = new Vala.Io.Path ("%s.properties".printf (appName));

    try {
        assert (Files.writeText (file, "name=std-path\n") == true);
        AppConfig config = AppConfig.load (appName);
        assert (config.getString ("name", "") == "std-path");
        assert (config.sourceOf ("name") == "file");
    } finally {
        Files.remove (file);
    }
}
