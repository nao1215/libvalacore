namespace Vala.Time {
    /**
     * Scheduled task callback.
     */
    public delegate void CronTask ();

    /**
     * Recoverable Cron configuration errors.
     */
    public errordomain CronError {
        INVALID_ARGUMENT,
        INVALID_EXPRESSION
    }

    /**
     * Simple cron scheduler with interval, daily time, and limited cron expression support.
     */
    public class Cron : GLib.Object {
        private enum Mode {
            INTERVAL,
            DAILY
        }

        private Mode _mode;
        private int64 _interval_millis;
        private int _daily_hour;
        private int _daily_minute;

        private GLib.Mutex _mutex;
        private bool _running;
        private int64 _next_fire_millis;
        private GLib.Thread<void *> ? _worker;

        /**
         * Creates scheduler from cron expression.
         *
         * Supported forms:
         * - "star-slash-N * * * *" style interval (every N minutes)
         * - "M H * * *" (every day at H:M)
         *
         * @param expression cron expression.
         */
        public Cron (string expression) throws CronError {
            parseExpression (expression);
            initRuntimeState ();
        }

        private Cron.fromInterval (int64 intervalMillis) throws CronError {
            if (intervalMillis <= 0) {
                throw new CronError.INVALID_ARGUMENT ("interval must be positive");
            }
            _mode = Mode.INTERVAL;
            _interval_millis = intervalMillis;
            _daily_hour = 0;
            _daily_minute = 0;
            initRuntimeState ();
        }

        private Cron.fromDailyAt (int hour, int minute) throws CronError {
            validateHourMinute (hour, minute);

            _mode = Mode.DAILY;
            _daily_hour = hour;
            _daily_minute = minute;
            _interval_millis = 0;
            initRuntimeState ();
        }

        /**
         * Creates fixed-interval scheduler.
         *
         * @param interval repeat interval.
         * @return Cron scheduler.
         */
        public static Cron every (Duration interval) throws CronError {
            return new Cron.fromInterval (interval.toMillis ());
        }

        /**
         * Creates daily scheduler at specific hour and minute.
         *
         * @param hour hour in [0, 23].
         * @param minute minute in [0, 59].
         * @return Cron scheduler.
         */
        public static Cron at (int hour, int minute) throws CronError {
            return new Cron.fromDailyAt (hour, minute);
        }

        /**
         * Starts scheduled execution.
         *
         * @param task callback function.
         */
        public void schedule (owned CronTask task) {
            startInternal (0, (owned) task);
        }

        /**
         * Starts scheduled execution with initial delay.
         *
         * @param initialDelay delay before first schedule evaluation.
         * @param task callback function.
         */
        public void scheduleWithDelay (Duration initialDelay, owned CronTask task) throws CronError {
            int64 delay = initialDelay.toMillis ();
            if (delay < 0) {
                throw new CronError.INVALID_ARGUMENT ("initialDelay must be non-negative");
            }
            startInternal (delay, (owned) task);
        }

        /**
         * Stops scheduled execution.
         */
        public void cancel () {
            GLib.Thread<void *> ? worker = null;

            _mutex.lock ();
            _running = false;
            worker = _worker;
            _worker = null;
            _mutex.unlock ();

            if (worker != null) {
                worker.join ();
            }
        }

        /**
         * Returns whether scheduler is running.
         *
         * @return true when running.
         */
        public bool isRunning () {
            _mutex.lock ();
            bool running = _running;
            _mutex.unlock ();
            return running;
        }

        /**
         * Returns next fire time.
         *
         * @return next fire time in local timezone.
         */
        public DateTime nextFireTime () {
            int64 nextMillis = 0;

            _mutex.lock ();
            if (_running && _next_fire_millis > 0) {
                nextMillis = _next_fire_millis;
            }
            _mutex.unlock ();

            if (nextMillis <= 0) {
                nextMillis = computeNextFireMillis ();
            }
            return DateTime.fromUnixTimestamp (nextMillis / 1000);
        }

        private void startInternal (int64 initialDelayMillis, owned CronTask task) {
            cancel ();

            _mutex.lock ();
            _running = true;
            _next_fire_millis = 0;
            _worker = new GLib.Thread<void *> ("cron-worker", () => {
                runLoop ((owned) task, initialDelayMillis);
                return null;
            });
            _mutex.unlock ();
        }

        private void runLoop (owned CronTask task, int64 initialDelayMillis) {
            if (initialDelayMillis > 0) {
                int64 delayTarget = currentTimeMillis () + initialDelayMillis;
                setNextFireMillis (delayTarget);
                if (!waitUntil (delayTarget)) {
                    return;
                }
                if (!isRunning ()) {
                    return;
                }
                task ();
            }

            while (isRunning ()) {
                int64 fireTarget = computeNextFireMillis ();
                setNextFireMillis (fireTarget);
                if (!waitUntil (fireTarget)) {
                    return;
                }
                if (!isRunning ()) {
                    return;
                }
                task ();
            }
        }

        private bool waitUntil (int64 targetMillis) {
            while (true) {
                if (!isRunning ()) {
                    return false;
                }

                int64 now = currentTimeMillis ();
                int64 remain = targetMillis - now;
                if (remain <= 0) {
                    return true;
                }

                int64 chunk = remain < 50 ? remain : 50;
                Thread.usleep ((ulong) (chunk * 1000));
            }
        }

        private int64 computeNextFireMillis () {
            int64 now = currentTimeMillis ();
            if (_mode == Mode.INTERVAL) {
                return now + _interval_millis;
            }
            return nextDailyFireMillis (now, _daily_hour, _daily_minute);
        }

        private static int64 nextDailyFireMillis (int64 nowMillis, int hour, int minute) {
            int64 nowSec = nowMillis / 1000;
            var now = new GLib.DateTime.from_unix_local (nowSec);
            GLib.DateTime ? target = new GLib.DateTime.local (
                now.get_year (),
                now.get_month (),
                now.get_day_of_month (),
                hour,
                minute,
                0.0
            );
            if (target == null) {
                return nowMillis + (24 * 60 * 60 * 1000);
            }

            if (target.compare (now) <= 0) {
                target = target.add_days (1);
            }
            return target.to_unix () * 1000;
        }

        private void parseExpression (string expression) throws CronError {
            string normalized = normalizeSpaces (expression);
            string[] parts = normalized.split (" ");
            if (parts.length != 5) {
                throw new CronError.INVALID_EXPRESSION (
                          "unsupported cron expression: %s".printf (expression)
                );
            }

            if (parts[0].has_prefix ("*/") &&
                parts[1] == "*" &&
                parts[2] == "*" &&
                parts[3] == "*" &&
                parts[4] == "*") {
                int minutes = parsePositiveInt (parts[0].substring (2), "minutes");
                _mode = Mode.INTERVAL;
                _interval_millis = (int64) minutes * 60 * 1000;
                _daily_hour = 0;
                _daily_minute = 0;
                return;
            }

            if (parts[2] == "*" && parts[3] == "*" && parts[4] == "*") {
                int minute = parseBoundedInt (parts[0], 0, 59, "minute");
                int hour = parseBoundedInt (parts[1], 0, 23, "hour");
                _mode = Mode.DAILY;
                _daily_hour = hour;
                _daily_minute = minute;
                _interval_millis = 0;
                return;
            }

            throw new CronError.INVALID_EXPRESSION (
                      "unsupported cron expression: %s".printf (expression)
            );
        }

        private void initRuntimeState () {
            _running = false;
            _next_fire_millis = 0;
            _worker = null;
        }

        private static string normalizeSpaces (string text) {
            string out = text.strip ();
            while (out.index_of ("  ") >= 0) {
                out = out.replace ("  ", " ");
            }
            return out;
        }

        private static int parsePositiveInt (string text, string label) throws CronError {
            int value = parseBoundedInt (text, 1, int.MAX, label);
            return value;
        }

        private static int parseBoundedInt (string text, int min, int max, string label) throws CronError {
            if (!GLib.Regex.match_simple ("^-?[0-9]+$", text)) {
                throw new CronError.INVALID_EXPRESSION ("invalid %s: %s".printf (label, text));
            }

            int value = int.parse (text);
            if (value < min || value > max) {
                throw new CronError.INVALID_EXPRESSION (
                          "%s must be in range [%d, %d]".printf (label, min, max)
                );
            }
            return value;
        }

        private static void validateHourMinute (int hour, int minute) throws CronError {
            if (hour < 0 || hour > 23) {
                throw new CronError.INVALID_ARGUMENT ("hour must be in range [0, 23]");
            }
            if (minute < 0 || minute > 59) {
                throw new CronError.INVALID_ARGUMENT ("minute must be in range [0, 59]");
            }
        }

        private static int64 currentTimeMillis () {
            return GLib.get_real_time () / 1000;
        }

        private void setNextFireMillis (int64 value) {
            _mutex.lock ();
            _next_fire_millis = value;
            _mutex.unlock ();
        }
    }
}
