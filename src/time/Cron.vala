using Vala.Collections;
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

        private Cron (Mode mode, int64 intervalMillis, int hour, int minute) {
            _mode = mode;
            _interval_millis = intervalMillis;
            _daily_hour = hour;
            _daily_minute = minute;
            initRuntimeState ();
        }

        /**
         * Creates scheduler from cron expression.
         *
         * Supported forms:
         * - "star-slash-N * * * *" style interval (every N minutes)
         * - "M H * * *" (every day at H:M)
         *
         * @param expression cron expression.
         * @return Result.ok(scheduler), or
         *         Result.error(CronError.INVALID_EXPRESSION) when expression format is unsupported.
         */
        public static Result<Cron, GLib.Error> of (string expression) {
            string normalized = normalizeSpaces (expression);
            string[] parts = normalized.split (" ");
            if (parts.length != 5) {
                return invalidExpressionResult (expression);
            }

            if (parts[0].has_prefix ("*/") &&
                parts[1] == "*" &&
                parts[2] == "*" &&
                parts[3] == "*" &&
                parts[4] == "*") {
                var minutes = parsePositiveInt (parts[0].substring (2), "minutes");
                if (minutes.isError ()) {
                    return Result.error<Cron, GLib.Error> (minutes.unwrapError ());
                }
                return Result.ok<Cron, GLib.Error> (
                    new Cron (Mode.INTERVAL, (int64) minutes.unwrap () * 60 * 1000, 0, 0)
                );
            }

            if (parts[2] == "*" && parts[3] == "*" && parts[4] == "*") {
                var minute = parseBoundedInt (parts[0], 0, 59, "minute");
                if (minute.isError ()) {
                    return Result.error<Cron, GLib.Error> (minute.unwrapError ());
                }

                var hour = parseBoundedInt (parts[1], 0, 23, "hour");
                if (hour.isError ()) {
                    return Result.error<Cron, GLib.Error> (hour.unwrapError ());
                }

                return Result.ok<Cron, GLib.Error> (
                    new Cron (Mode.DAILY, 0, hour.unwrap (), minute.unwrap ())
                );
            }

            return invalidExpressionResult (expression);
        }

        /**
         * Creates fixed-interval scheduler.
         *
         * @param interval repeat interval.
         * @return Result.ok(scheduler), or
         *         Result.error(CronError.INVALID_ARGUMENT) when interval is not positive.
         */
        public static Result<Cron, GLib.Error> every (Duration interval) {
            int64 interval_millis = interval.toMillis ();
            if (interval_millis <= 0) {
                return Result.error<Cron, GLib.Error> (
                    new CronError.INVALID_ARGUMENT ("interval must be positive")
                );
            }

            return Result.ok<Cron, GLib.Error> (
                new Cron (Mode.INTERVAL, interval_millis, 0, 0)
            );
        }

        /**
         * Creates daily scheduler at specific hour and minute.
         *
         * @param hour hour in [0, 23].
         * @param minute minute in [0, 59].
         * @return Result.ok(scheduler), or
         *         Result.error(CronError.INVALID_ARGUMENT) when hour/minute is out of range.
         */
        public static Result<Cron, GLib.Error> at (int hour, int minute) {
            GLib.Error ? validation_error = validateHourMinute (hour, minute);
            if (validation_error != null) {
                return Result.error<Cron, GLib.Error> (validation_error);
            }

            return Result.ok<Cron, GLib.Error> (
                new Cron (Mode.DAILY, 0, hour, minute)
            );
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
         * @return Result.ok(this scheduler), or
         *         Result.error(CronError.INVALID_ARGUMENT) when delay is negative.
         */
        public Result<Cron, GLib.Error> scheduleWithDelay (Duration initialDelay, owned CronTask task) {
            int64 delay = initialDelay.toMillis ();
            if (delay < 0) {
                return Result.error<Cron, GLib.Error> (
                    new CronError.INVALID_ARGUMENT ("initialDelay must be non-negative")
                );
            }
            startInternal (delay, (owned) task);
            return Result.ok<Cron, GLib.Error> (this);
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

        private static Result<Cron, GLib.Error> invalidExpressionResult (string expression) {
            return Result.error<Cron, GLib.Error> (
                new CronError.INVALID_EXPRESSION (
                    "unsupported cron expression: %s".printf (expression)
                )
            );
        }

        private static Result<int ?, GLib.Error> parsePositiveInt (string text, string label) {
            return parseBoundedInt (text, 1, int.MAX, label);
        }

        private static Result<int ?, GLib.Error> parseBoundedInt (string text,
                                                                  int min,
                                                                  int max,
                                                                  string label) {
            if (!GLib.Regex.match_simple ("^-?[0-9]+$", text)) {
                return Result.error<int ?, GLib.Error> (
                    new CronError.INVALID_EXPRESSION ("invalid %s: %s".printf (label, text))
                );
            }

            int value = int.parse (text);
            if (value < min || value > max) {
                return Result.error<int ?, GLib.Error> (
                    new CronError.INVALID_EXPRESSION (
                        "%s must be in range [%d, %d]".printf (label, min, max)
                    )
                );
            }
            return Result.ok<int ?, GLib.Error> (value);
        }

        private static GLib.Error ? validateHourMinute (int hour, int minute) {
            if (hour < 0 || hour > 23) {
                return new CronError.INVALID_ARGUMENT ("hour must be in range [0, 23]");
            }
            if (minute < 0 || minute > 59) {
                return new CronError.INVALID_ARGUMENT ("minute must be in range [0, 59]");
            }
            return null;
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
