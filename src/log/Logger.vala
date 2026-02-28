namespace Vala.Log {
    /**
     * Log handler interface.
     */
    public interface LogHandler : GLib.Object {
        /**
         * Handles a log event.
         *
         * @param level log level.
         * @param loggerName logger name.
         * @param message log message.
         */
        public abstract void handle (LogLevel level, string loggerName, string message);
    }

    /**
     * Named logger with level filtering and pluggable handlers.
     */
    public class Logger : GLib.Object {
        private static GLib.HashTable<string, Logger> ? _registry = null;

        private string _name;
        private LogLevel _level = LogLevel.INFO;
        private LogHandler[] _handlers;

        private Logger (string name) {
            _name = name;
            _handlers = {};
        }

        /**
         * Gets or creates a named logger.
         *
         * @param name logger name.
         * @return logger instance.
         */
        public static Logger getLogger (string name) {
            string key = name;
            if (key.length == 0) {
                key = "root";
            }

            if (_registry == null) {
                _registry = new GLib.HashTable<string, Logger> (str_hash, str_equal);
            }

            Logger ? existing = _registry.lookup (key);
            if (existing != null) {
                return existing;
            }

            Logger created = new Logger (key);
            _registry.insert (key, created);
            return created;
        }

        /**
         * Sets minimum output level.
         *
         * @param level minimum log level.
         */
        public void setLevel (LogLevel level) {
            _level = level;
        }

        /**
         * Adds output handler.
         *
         * @param handler handler callback.
         */
        public void addHandler (LogHandler handler) {
            _handlers += handler;
        }

        /**
         * Logs debug message.
         *
         * @param msg log message.
         */
        public void debug (string msg) {
            log (LogLevel.DEBUG, msg);
        }

        /**
         * Logs info message.
         *
         * @param msg log message.
         */
        public void info (string msg) {
            log (LogLevel.INFO, msg);
        }

        /**
         * Logs warning message.
         *
         * @param msg log message.
         */
        public void warn (string msg) {
            log (LogLevel.WARN, msg);
        }

        /**
         * Logs error message.
         *
         * @param msg log message.
         */
        public void error (string msg) {
            log (LogLevel.ERROR, msg);
        }

        private void log (LogLevel level, string msg) {
            if ((int) level < (int) _level) {
                return;
            }
            stdout.printf ("[%s] [%s] %s\n", levelToString (level), _name, msg);
            foreach (LogHandler handler in _handlers) {
                handler.handle (level, _name, msg);
            }
        }

        private static string levelToString (LogLevel level) {
            switch (level) {
                case LogLevel.DEBUG :
                    return "DEBUG";
                case LogLevel.INFO :
                    return "INFO";
                case LogLevel.WARN:
                    return "WARN";
                case LogLevel.ERROR:
                    return "ERROR";
                default:
                    return "UNKNOWN";
            }
        }
    }
}
