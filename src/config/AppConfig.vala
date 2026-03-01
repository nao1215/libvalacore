using Vala.Collections;
using Vala.Io;
using Vala.Time;

namespace Vala.Config {
    /**
     * Recoverable AppConfig argument and lookup errors.
     */
    public errordomain AppConfigError {
        INVALID_ARGUMENT,
        REQUIRED_KEY_MISSING
    }

    /**
     * Unified application configuration from file, environment, and CLI.
     *
     * Precedence order is `cli > env > file > fallback`.
     *
     * Example:
     * {{{
     *     var cfg = AppConfig.load ("myapp")
     *         .withEnvPrefix ("MYAPP_")
     *         .withCliArgs (args);
     *
     *     int port = cfg.getInt ("port", 8080);
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
         * @return loaded AppConfig.
         * @throws AppConfigError.INVALID_ARGUMENT when appName is empty.
         */
        public static AppConfig load (string appName) throws AppConfigError {
            if (appName.length == 0) {
                throw new AppConfigError.INVALID_ARGUMENT ("appName must not be empty");
            }

            var config = new AppConfig ();
            var candidates = new ArrayList<Vala.Io.Path> ();

            candidates.add (new Vala.Io.Path ("%s.properties".printf (appName)));
            candidates.add (new Vala.Io.Path ("%s.conf".printf (appName)));

            string ? home = GLib.Environment.get_home_dir ();
            if (home != null && home.length > 0) {
                candidates.add (new Vala.Io.Path ("%s/.config/%s/config.properties".printf (home, appName)));
            }
            candidates.add (new Vala.Io.Path ("/etc/%s/config.properties".printf (appName)));

            for (int i = 0; i < candidates.size (); i++) {
                Vala.Io.Path ? path = candidates.get (i);
                if (path != null && Files.isFile (path)) {
                    config.loadFromFile (path);
                    break;
                }
            }

            return config;
        }

        /**
         * Loads config from explicit file path.
         *
         * @param path config file path.
         * @return loaded AppConfig.
         * @throws AppConfigError.INVALID_ARGUMENT when path is empty or not a file.
         */
        public static AppConfig loadFile (Vala.Io.Path path) throws AppConfigError {
            if (path.toString ().strip ().length == 0 || !Files.isFile (path)) {
                throw new AppConfigError.INVALID_ARGUMENT (
                          "path must reference an existing file: %s".printf (path.toString ())
                );
            }
            var config = new AppConfig ();
            config.loadFromFile (path);
            return config;
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
         * @return resolved string value.
         * @throws AppConfigError.INVALID_ARGUMENT when key is empty.
         */
        public string getString (string key,
                                 string fallback = "") throws AppConfigError {
            ensureKey (key);

            string source;
            string ? value = resolveValue (key, out source);
            return value ?? fallback;
        }

        /**
         * Returns int value or fallback on missing/parse failure.
         *
         * @param key config key.
         * @param fallback fallback int.
         * @return parsed int or fallback.
         * @throws AppConfigError.INVALID_ARGUMENT when key is empty.
         */
        public int getInt (string key,
                           int fallback = 0) throws AppConfigError {
            ensureKey (key);

            string source;
            string ? raw = resolveValue (key, out source);
            if (raw == null) {
                return fallback;
            }

            int parsed;
            if (int.try_parse (raw.strip (), out parsed)) {
                return parsed;
            }
            return fallback;
        }

        /**
         * Returns bool value or fallback on missing/parse failure.
         *
         * Accepted true values: `true`, `1`, `yes`, `on`
         * Accepted false values: `false`, `0`, `no`, `off`
         *
         * @param key config key.
         * @param fallback fallback bool.
         * @return parsed bool or fallback.
         * @throws AppConfigError.INVALID_ARGUMENT when key is empty.
         */
        public bool getBool (string key,
                             bool fallback = false) throws AppConfigError {
            ensureKey (key);

            string source;
            string ? raw = resolveValue (key, out source);
            if (raw == null) {
                return fallback;
            }

            bool ? parsed = parseBool (raw);
            return parsed ?? fallback;
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
         * @return parsed duration or fallback.
         * @throws AppConfigError.INVALID_ARGUMENT when key is empty.
         */
        public Duration getDuration (string key,
                                     Duration fallback) throws AppConfigError {
            ensureKey (key);

            string source;
            string ? raw = resolveValue (key, out source);
            if (raw == null) {
                return fallback;
            }

            Duration ? parsed = parseDuration (raw);
            return parsed ?? fallback;
        }

        /**
         * Returns required string value.
         *
         * @param key required config key.
         * @return existing value.
         * @throws AppConfigError.INVALID_ARGUMENT when key is empty.
         * @throws AppConfigError.REQUIRED_KEY_MISSING when key has no value.
         */
        public string require (string key) throws AppConfigError {
            ensureKey (key);

            string source;
            string ? value = resolveValue (key, out source);
            if (value == null) {
                throw new AppConfigError.REQUIRED_KEY_MISSING (
                          "required config key `%s` is missing".printf (key)
                );
            }
            return value;
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
         * @return source name.
         * @throws AppConfigError.INVALID_ARGUMENT when key is empty.
         */
        public string sourceOf (string key) throws AppConfigError {
            ensureKey (key);

            string source;
            resolveValue (key, out source);
            return source;
        }

        private void loadFromFile (Vala.Io.Path path) {
            _fileValues.clear ();

            var props = new Properties ();
            if (!props.load (path)) {
                return;
            }

            string[] keys = props.keys ();
            for (int i = 0; i < keys.length; i++) {
                string ? value = props.get (keys[i]);
                if (value != null) {
                    _fileValues.put (keys[i], value);
                }
            }
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
                case "0":
                case "false":
                case "no":
                case "off":
                    return false;
                default:
                    return null;
            }
        }

        private static void ensureKey (string key) throws AppConfigError {
            if (key.strip ().length == 0) {
                throw new AppConfigError.INVALID_ARGUMENT ("key must not be empty");
            }
        }
    }
}
