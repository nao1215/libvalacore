using Vala.Time;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/time/cron/testEverySchedule", testEverySchedule);
    Test.add_func ("/time/cron/testScheduleWithDelay", testScheduleWithDelay);
    Test.add_func ("/time/cron/testExpressionAndAt", testExpressionAndAt);
    Test.add_func ("/time/cron/testCancel", testCancel);
    Test.add_func ("/time/cron/testEveryInvalidInterval", testEveryInvalidInterval);
    Test.add_func ("/time/cron/testAtInvalidRange", testAtInvalidRange);
    Test.add_func ("/time/cron/testExpressionInvalid", testExpressionInvalid);
    Test.add_func ("/time/cron/testScheduleWithDelayInvalid", testScheduleWithDelayInvalid);

    Test.run ();
}

Cron mustEvery (Duration interval) {
    var created = Cron.every (interval);
    assert (created.isOk ());
    return created.unwrap ();
}

Cron mustAt (int hour, int minute) {
    var created = Cron.at (hour, minute);
    assert (created.isOk ());
    return created.unwrap ();
}

Cron mustExpression (string expr) {
    var created = Cron.of (expr);
    assert (created.isOk ());
    return created.unwrap ();
}

void testEverySchedule () {
    var cron = mustEvery (Duration.ofSeconds (1));
    int count = 0;
    GLib.Mutex mutex = GLib.Mutex ();
    GLib.Cond cond = GLib.Cond ();
    cron.schedule (() => {
        mutex.lock ();
        count++;
        cond.signal ();
        mutex.unlock ();
    });

    int64 deadline = GLib.get_monotonic_time () + (3 * 1000 * 1000);
    mutex.lock ();
    while (count < 1) {
        if (!cond.wait_until (mutex, deadline)) {
            break;
        }
    }
    int total = count;
    mutex.unlock ();
    cron.cancel ();
    assert (total >= 1);
}

void testScheduleWithDelay () {
    var cron = mustEvery (Duration.ofSeconds (1));
    int count = 0;
    GLib.Mutex mutex = GLib.Mutex ();
    GLib.Cond cond = GLib.Cond ();
    var scheduled = cron.scheduleWithDelay (Duration.ofSeconds (2), () => {
        mutex.lock ();
        count++;
        cond.signal ();
        mutex.unlock ();
    });
    assert (scheduled.isOk ());

    int64 early_deadline = GLib.get_monotonic_time () + (1200 * 1000);
    mutex.lock ();
    while (count == 0) {
        if (!cond.wait_until (mutex, early_deadline)) {
            break;
        }
    }
    int before = count;
    mutex.unlock ();
    assert (before == 0);

    int64 run_deadline = GLib.get_monotonic_time () + (2500 * 1000);
    mutex.lock ();
    while (count < 1) {
        if (!cond.wait_until (mutex, run_deadline)) {
            break;
        }
    }
    int after = count;
    mutex.unlock ();
    cron.cancel ();
    assert (after >= 1);
}

void testExpressionAndAt () {
    var expr = mustExpression ("*/5 * * * *");
    Vala.Time.DateTime exprNext = expr.nextFireTime ();
    assert (exprNext.toUnixTimestamp () > Vala.Time.DateTime.now ().toUnixTimestamp ());

    var daily = mustAt (23, 59);
    Vala.Time.DateTime dailyNext = daily.nextFireTime ();
    assert (dailyNext.hour () == 23);
    assert (dailyNext.minute () == 59);
}

void testCancel () {
    var cron = mustEvery (Duration.ofSeconds (1));
    cron.schedule (() => {});
    assert (cron.isRunning () == true);

    cron.cancel ();
    assert (cron.isRunning () == false);
}

void testEveryInvalidInterval () {
    var created = Cron.every (Duration.ofSeconds (0));
    assert (created.isError ());
    assert (created.unwrapError () is CronError.INVALID_ARGUMENT);
}

void testAtInvalidRange () {
    var created = Cron.at (24, 0);
    assert (created.isError ());
    assert (created.unwrapError () is CronError.INVALID_ARGUMENT);
}

void testExpressionInvalid () {
    var created = Cron.of ("invalid expression");
    assert (created.isError ());
    assert (created.unwrapError () is CronError.INVALID_EXPRESSION);
}

void testScheduleWithDelayInvalid () {
    var cron = mustEvery (Duration.ofSeconds (1));
    var scheduled = cron.scheduleWithDelay (Duration.ofSeconds (-1), () => {});
    assert (scheduled.isError ());
    assert (scheduled.unwrapError () is CronError.INVALID_ARGUMENT);
    cron.cancel ();
}
