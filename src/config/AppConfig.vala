using Vala.Collections;
using Vala.Io;
using Vala.Time;

namespace Vala.Config {
    /**
     * Recoverable AppConfig argument and lookup errors.
     */
    public errordomain AppConfigError {
        INVALID_ARGUMENT,
        REQUIRED_KEY_MISSING,
        LOAD_FAILED
    }

    /**
     * Unified application configuration from file, environment, and CLI.
     *
     * Precedence order is `cli > env > file > fallback`.
     *
     * Example:
     * {{{
     *     var loaded = AppConfig.load ("myapp");
     *     if (loaded.isError ()) {
     *         return;
     *     }
     *
     *     var cfg = loaded.unwrap ()
     *         .withEnvPrefix ("MYAPP_")
     *         .withCliArgs (args);
     *
     *     var port = cfg.getInt ("port", 8080);
     *     if (port.isError ()) {
     *         return;
     *     }
     * }}}
     */
    public class AppConfig : GLib.Object {
        private HashMap<string, string> _fileValues;
        private HashMap<string, string> _cliValues;
        private string _envPrefix;

        /**
         * Creates an empty AppConfig.
         */
        public AppConfig () {
            _fileValues = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            _cliValues = new HashMap<string, string> (GLib.str_hash, GLib.str_equal);
            _envPrefix = "";
        }

        /**
         * Loads config from standard paths using app name.
         *
         * Candidate paths:
         * - `./<appName>.properties`
         * - `./<appName>.conf`
         * - `$HOME/.config/<appName>/config.properties`
         * - `/etc/<appName>/config.properties`
         *
         * @param appName application name.
         * @return Result.ok(loaded AppConfig), or
         *         Result.error(AppConfigError.INVALID_ARGUMENT / LOAD_FAILED).
         */
        public static Result<AppConfig, GLib.Error> load (string appName) {
            string normalized_app_name = appName.strip ();
            if (normalized_app_name.length == 0) {
                return Result.error<AppConfig, GLib.Error> (
                    new AppConfigError.INVALID_ARGUMENT ("appName must not be empty")
                );
            }

            var config = new AppConfig ();
            var candidates = new ArrayList<Vala.Io.Path> ();

            candidates.add (new Vala.Io.Path ("%s.properties".printf (normalized_app_name)));
            candidates.add (new Vala.Io.Path ("%s.conf".printf (normalized_app_name)));

            string ? home = GLib.Environment.get_home_dir ();
            if (home != null && home.length > 0) {
                candidates.add (new Vala.Io.Path ("%s/.config/%s/config.properties".printf (home, normalized_app_name)));
            }
            candidates.add (new Vala.Io.Path ("/etc/%s/config.properties".printf (normalized_app_name)));

            for (int i = 0; i < candidates.size (); i++) {
                Vala.Io.Path ? path = candidates.get (i);
                if (path != null && Files.isFile (path)) {
                    var loaded = config.loadFromFile (path);
                    if (loaded.isError ()) {
                        return Result.error<AppConfig, GLib.Error> (loaded.unwrapError ());
                    }
                    break;
                }
            }

            return Result.ok<AppConfig, GLib.Error> (config);
        }

        /**
         * Loads config from explicit file path.
         *
         * @param path config file path.
         * @return Result.ok(loaded AppConfig), or
         *         Result.error(AppConfigError.INVALID_ARGUMENT / LOAD_FAILED).
         */
        public static Result<AppConfig, GLib.Error> loadFile (Vala.Io.Path path) {
            if (path.toString ().strip ().length == 0 || !Files.isFile (path)) {
                return Result.error<AppConfig, GLib.Error> (
                    new AppConfigError.INVALID_ARGUMENT (
                        "path must reference an existing file: %s".printf (path.toString ())
                    )
                );
            }
            var config = new AppConfig ();
            var loaded = config.loadFromFile (path);
            if (loaded.isError ()) {
                return Result.error<AppConfig, GLib.Error> (loaded.unwrapError ());
            }
            return Result.ok<AppConfig, GLib.Error> (config);
        }

        /**
         * Sets environment variable prefix.
         *
         * @param prefix environment variable prefix such as `MYAPP_`.
         * @return this AppConfig for chaining.
         */
        public AppConfig withEnvPrefix (string prefix) {
            _envPrefix = prefix;
            return this;
        }

        /**
         * Parses CLI args and stores key-value overrides.
         *
         * Supported forms:
         * - `--key=value`
         * - `--key value`
         * - `--flag` (treated as `true`)
         *
         * @param args CLI argument array.
         * @return this AppConfig for chaining.
         */
        public AppConfig withCliArgs (string[] args) {
            _cliValues.clear ();

            for (int i = 0; i < args.length; i++) {
                string token = args[i];
                if (!token.has_prefix ("--")) {
                    continue;
                }

                string body = token.substring (2).strip ();
                if (body.length == 0) {
                    continue;
                }

                string key;
                string value;
                int split = body.index_of_char ('=');
                if (split >= 0) {
                    key = body.substring (0, split).strip ();
                    value = body.substring (split + 1).strip ();
                } else if ((i + 1) < args.length && !args[i + 1].has_prefix ("--")) {
                    key = body;
                    value = args[i + 1];
                    i++;
                } else {
                    key = body;
                    value = "true";
                }

                if (key.length == 0) {
                    continue;
                }
                _cliValues.put (key, value);
            }

            return this;
        }

        /**
         * Returns string value or fallback.
         *
         * @param key config key.
         * @param fallback value to return when key is missing.
         * @return Result.ok(resolved string value), or
         *         Result.error(AppConfigError.INVALID_ARGUMENT) when key is empty.
         */
        public Result<string, GLib.Error> getString (string key, string fallback = "") {
            GLib.Error ? keyError = ensureKey (key);
            if (keyError != null) {
                return Result.error<string, GLib.Error> (keyError);
            }

            string source;
            string ? value = resolveValue (key, out source);
            return Result.ok<string, GLib.Error> (value ?? fallback);
        }

        /**
         * Returns int value or fallback on missing/parse failure.
         *
         * @param key config key.
         * @param fallback fallback int.
         * @return Result.ok(parsed int or fallback), or
         *         Result.error(AppConfigError.INVALID_ARGUMENT) when key is empty.
         */
        public Result<int, GLib.Error> getInt (string key, int fallback = 0) {
            GLib.Error ? keyError = ensureKey (key);
            if (keyError != null) {
                return Result.error<int, GLib.Error> (keyError);
            }

            string source;
            string ? raw = resolveValue (key, out source);
            if (raw == null) {
                return Result.ok<int, GLib.Error> (fallback);
            }

            int parsed;
            if (int.try_parse (raw.strip (), out parsed)) {
                return Result.ok<int, GLib.Error> (parsed);
            }
            return Result.ok<int, GLib.Error> (fallback);
        }

        /**
         * Returns bool value or fallback on missing/parse failure.
         *
         * Accepted true values: `true`, `1`, `yes`, `on`
         * Accepted false values: `false`, `0`, `no`, `off`
         *
         * @param key config key.
         * @param fallback fallback bool.
         * @return Result.ok(parsed bool or fallback), or
         *         Result.error(AppConfigError.INVALID_ARGUMENT) when key is empty.
         */
        public Result<bool, GLib.Error> getBool (string key, bool fallback = false) {
            GLib.Error ? keyError = ensureKey (key);
            if (keyError != null) {
                return Result.error<bool, GLib.Error> (keyError);
            }

            string source;
            string ? raw = resolveValue (key, out source);
            if (raw == null) {
                return Result.ok<bool, GLib.Error> (fallback);
            }

            bool ? parsed = parseBool (raw);
            if (parsed != null) {
                return Result.ok<bool, GLib.Error> ((bool) parsed);
            }
            return Result.ok<bool, GLib.Error> (fallback);
        }

        /**
         * Returns duration value or fallback on missing/parse failure.
         *
         * Accepted units:
         * - `s` seconds
         * - `m` minutes
         * - `h` hours
         * - `d` days
         *
         * Plain integer is treated as seconds.
         *
         * @param key config key.
         * @param fallback fallback duration.
         * @return Result.ok(parsed duration or fallback), or
         *         Result.error(AppConfigError.INVALID_ARGUMENT) when key is empty.
         */
        public Result<Duration, GLib.Error> getDuration (string key, Duration fallback) {
            GLib.Error ? keyError = ensureKey (key);
            if (keyError != null) {
                return Result.error<Duration, GLib.Error> (keyError);
            }

            string source;
            string ? raw = resolveValue (key, out source);
            if (raw == null) {
                return Result.ok<Duration, GLib.Error> (fallback);
            }

            Duration ? parsed = parseDuration (raw);
            return Result.ok<Duration, GLib.Error> (parsed ?? fallback);
        }

        /**
         * Returns required string value.
         *
         * @param key required config key.
         * @return Result.ok(existing value), or
         *         Result.error(AppConfigError.INVALID_ARGUMENT / REQUIRED_KEY_MISSING).
         */
        public Result<string, GLib.Error> require (string key) {
            GLib.Error ? keyError = ensureKey (key);
            if (keyError != null) {
                return Result.error<string, GLib.Error> (keyError);
            }

            string source;
            string ? value = resolveValue (key, out source);
            if (value == null) {
                return Result.error<string, GLib.Error> (
                    new AppConfigError.REQUIRED_KEY_MISSING (
                        "required config key `%s` is missing".printf (key)
                    )
                );
            }
            return Result.ok<string, GLib.Error> (value);
        }

        /**
         * Returns source name of resolved value.
         *
         * Possible values are:
         * - `cli`
         * - `env`
         * - `file`
         * - `default`
         *
         * @param key config key.
         * @return Result.ok(source name), or
         *         Result.error(AppConfigError.INVALID_ARGUMENT) when key is empty.
         */
        public Result<string, GLib.Error> sourceOf (string key) {
            GLib.Error ? keyError = ensureKey (key);
            if (keyError != null) {
                return Result.error<string, GLib.Error> (keyError);
            }

            string source;
            resolveValue (key, out source);
            return Result.ok<string, GLib.Error> (source);
        }

        private Result<bool, GLib.Error> loadFromFile (Vala.Io.Path path) {
            _fileValues.clear ();

            var props = new Properties ();
            if (!props.load (path)) {
                return Result.error<bool, GLib.Error> (
                    new AppConfigError.LOAD_FAILED (
                        "failed to load config file: %s".printf (path.toString ())
                    )
                );
            }

            string[] keys = props.keys ();
            for (int i = 0; i < keys.length; i++) {
                string ? value = props.get (keys[i]);
                if (value != null) {
                    _fileValues.put (keys[i], value);
                }
            }
            return Result.ok<bool, GLib.Error> (true);
        }

        private string ? resolveValue (string key, out string source) {
            string ? cli = _cliValues.get (key);
            if (cli != null) {
                source = "cli";
                return cli;
            }

            string ? env = valueFromEnv (key);
            if (env != null) {
                source = "env";
                return env;
            }

            string ? file = _fileValues.get (key);
            if (file != null) {
                source = "file";
                return file;
            }

            source = "default";
            return null;
        }

        private string ? valueFromEnv (string key) {
            string envKey = toEnvKey (key);
            return GLib.Environment.get_variable (envKey);
        }

        private string toEnvKey (string key) {
            string normalized = key.up ();
            normalized = normalized.replace (".", "_");
            normalized = normalized.replace ("-", "_");
            return _envPrefix + normalized;
        }

        private static Duration ? parseDuration (string raw) {
            string value = raw.strip ().down ();
            if (value.length == 0) {
                return null;
            }

            if (value.has_suffix ("s")) {
                string n = value.substring (0, value.length - 1);
                int64 secs;
                if (int64.try_parse (n, out secs)) {
                    return Duration.ofSeconds (secs);
                }
                return null;
            }

            if (value.has_suffix ("m")) {
                string n = value.substring (0, value.length - 1);
                int64 mins;
                if (int64.try_parse (n, out mins)) {
                    return Duration.ofMinutes (mins);
                }
                return null;
            }

            if (value.has_suffix ("h")) {
                string n = value.substring (0, value.length - 1);
                int64 hours;
                if (int64.try_parse (n, out hours)) {
                    return Duration.ofHours (hours);
                }
                return null;
            }

            if (value.has_suffix ("d")) {
                string n = value.substring (0, value.length - 1);
                int64 days;
                if (int64.try_parse (n, out days)) {
                    return Duration.ofDays (days);
                }
                return null;
            }

            int64 secsPlain;
            if (int64.try_parse (value, out secsPlain)) {
                return Duration.ofSeconds (secsPlain);
            }
            return null;
        }

        private static bool ? parseBool (string raw) {
            string value = raw.strip ().down ();
            switch (value) {
                case "1" :
                case "true" :
                case "yes" :
                case "on" :
                    return true;
                case "0" :
                case "false" :
                case "no" :
                case "off" :
                    return false;
                    default :
                    return null;
            }
        }

        private static GLib.Error ? ensureKey (string key) {
            if (key.strip ().length == 0) {
                return new AppConfigError.INVALID_ARGUMENT ("key must not be empty");
            }
            return null;
        }
    }
}
