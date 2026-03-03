using Vala.Config;
using Vala.Collections;
using Vala.Io;
using Vala.Time;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/config/appconfig/testLoadFile", testLoadFile);
    Test.add_func ("/config/appconfig/testPrecedence", testPrecedence);
    Test.add_func ("/config/appconfig/testTypedGetters", testTypedGetters);
    Test.add_func ("/config/appconfig/testLoadStandardPath", testLoadStandardPath);
    Test.add_func ("/config/appconfig/testInvalidArguments", testInvalidArguments);

    Test.run ();
}

AppConfig mustLoad (string appName) {
    var loaded = AppConfig.load (appName);
    assert (loaded.isOk ());
    return loaded.unwrap ();
}

AppConfig mustLoadFile (Vala.Io.Path path) {
    var loaded = AppConfig.loadFile (path);
    assert (loaded.isOk ());
    return loaded.unwrap ();
}

string mustGetString (AppConfig config, string key, string fallback = "") {
    var value = config.getString (key, fallback);
    assert (value.isOk ());
    return value.unwrap ();
}

int mustGetInt (AppConfig config, string key, int fallback = 0) {
    Result<int, GLib.Error> value = config.getInt (key, fallback);
    assert (value.isOk ());
    return value.unwrap ();
}

bool mustGetBool (AppConfig config, string key, bool fallback = false) {
    Result<bool, GLib.Error> value = config.getBool (key, fallback);
    assert (value.isOk ());
    return value.unwrap ();
}

Duration mustGetDuration (AppConfig config, string key, Duration fallback) {
    var value = config.getDuration (key, fallback);
    assert (value.isOk ());
    return value.unwrap ();
}

string mustRequire (AppConfig config, string key) {
    var value = config.require (key);
    assert (value.isOk ());
    return value.unwrap ();
}

string mustSourceOf (AppConfig config, string key) {
    var value = config.sourceOf (key);
    assert (value.isOk ());
    return value.unwrap ();
}

void testLoadFile () {
    Vala.Io.Path ? file = Files.tempFile ("appconfig", ".properties");
    assert (file != null);

    try {
        assert (Files.writeText (file, "host=127.0.0.1\nport=8080\n") == true);

        AppConfig config = mustLoadFile (file);
        assert (mustGetString (config, "host", "") == "127.0.0.1");
        assert (mustGetInt (config, "port", 0) == 8080);
        assert (mustSourceOf (config, "host") == "file");
        assert (mustSourceOf (config, "missing") == "default");
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
        AppConfig config = mustLoadFile (file)
                            .withEnvPrefix ("MYAPP_")
                            .withCliArgs (cli);

        assert (mustGetString (config, "host", "") == "cli-host");
        assert (mustSourceOf (config, "host") == "cli");

        string[] emptyCli = {};
        config.withCliArgs (emptyCli);
        assert (mustGetString (config, "host", "") == "env-host");
        assert (mustSourceOf (config, "host") == "env");

        GLib.Environment.unset_variable (envKey);
        assert (mustGetString (config, "host", "") == "file-host");
        assert (mustSourceOf (config, "host") == "file");
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

    assert (mustGetInt (config, "workers", 0) == 16);
    assert (mustGetInt (config, " workers ", 0) == 16);
    assert (mustGetBool (config, "enabled", false) == true);
    assert (mustGetBool (config, " enabled ", false) == true);
    assert (mustGetBool (config, "debug", false) == true);

    Duration timeout = mustGetDuration (config, "timeout", Duration.ofSeconds (1));
    assert (timeout.toSeconds () == 120);
    Duration timeoutTrimmed = mustGetDuration (config, " timeout ", Duration.ofSeconds (1));
    assert (timeoutTrimmed.toSeconds () == 120);

    assert (mustGetInt (config, "invalid_int", 7) == 7);
    assert (mustGetBool (config, "invalid_bool", false) == false);

    Duration fallback = Duration.ofSeconds (9);
    assert (mustGetDuration (config, "invalid_duration", fallback).toSeconds () == 9);

    assert (mustRequire (config, "workers") == "16");
    assert (mustRequire (config, " workers ") == "16");
    assert (mustSourceOf (config, " workers ") == "cli");
}

void testLoadStandardPath () {
    int64 now = GLib.get_real_time ();
    string appName = "appconfig-ut-%s".printf (now.to_string ());
    Vala.Io.Path file = new Vala.Io.Path ("%s.properties".printf (appName));

    try {
        assert (Files.writeText (file, "name=std-path\n") == true);
        AppConfig config = mustLoad (appName);
        assert (mustGetString (config, "name", "") == "std-path");
        assert (mustSourceOf (config, "name") == "file");
    } finally {
        Files.remove (file);
    }
}

void testInvalidArguments () {
    var load = AppConfig.load ("");
    assert (load.isError ());
    assert (load.unwrapError () is AppConfigError.INVALID_ARGUMENT);

    var loadWhitespace = AppConfig.load ("   ");
    assert (loadWhitespace.isError ());
    assert (loadWhitespace.unwrapError () is AppConfigError.INVALID_ARGUMENT);

    AppConfig config = new AppConfig ();
    var required = config.require ("missing");
    assert (required.isError ());
    assert (required.unwrapError () is AppConfigError.REQUIRED_KEY_MISSING);

    var key = config.getString ("", "x");
    assert (key.isError ());
    assert (key.unwrapError () is AppConfigError.INVALID_ARGUMENT);

    key = config.getString ("   ", "x");
    assert (key.isError ());
    assert (key.unwrapError () is AppConfigError.INVALID_ARGUMENT);

    string missingFilePath = "/tmp/valacore/ut/appconfig-missing-%s.properties".printf (GLib.Uuid.string_random ());
    var loadFile = AppConfig.loadFile (new Vala.Io.Path (missingFilePath));
    assert (loadFile.isError ());
    assert (loadFile.unwrapError () is AppConfigError.INVALID_ARGUMENT);
}
