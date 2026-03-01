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
    Cron ? cron = null;
    try {
        cron = Cron.every (interval);
    } catch (CronError e) {
        assert_not_reached ();
    }
    if (cron == null) {
        assert_not_reached ();
    }
    return cron;
}

Cron mustAt (int hour, int minute) {
    Cron ? cron = null;
    try {
        cron = Cron.at (hour, minute);
    } catch (CronError e) {
        assert_not_reached ();
    }
    if (cron == null) {
        assert_not_reached ();
    }
    return cron;
}

Cron mustExpression (string expr) {
    Cron ? cron = null;
    try {
        cron = new Cron (expr);
    } catch (CronError e) {
        assert_not_reached ();
    }
    if (cron == null) {
        assert_not_reached ();
    }
    return cron;
}

void testEverySchedule () {
    var cron = mustEvery (Duration.ofSeconds (1));
    int count = 0;
    GLib.Mutex mutex = GLib.Mutex ();
    cron.schedule (() => {
        mutex.lock ();
        count++;
        mutex.unlock ();
    });

    Posix.usleep (2300000);
    cron.cancel ();
    mutex.lock ();
    int total = count;
    mutex.unlock ();
    assert (total >= 1);
}

void testScheduleWithDelay () {
    var cron = mustEvery (Duration.ofSeconds (1));
    int count = 0;
    GLib.Mutex mutex = GLib.Mutex ();
    try {
        cron.scheduleWithDelay (Duration.ofSeconds (2), () => {
            mutex.lock ();
            count++;
            mutex.unlock ();
        });
    } catch (CronError e) {
        assert_not_reached ();
    }

    Posix.usleep (1200000);
    mutex.lock ();
    int before = count;
    mutex.unlock ();
    assert (before == 0);

    Posix.usleep (1700000);
    cron.cancel ();
    mutex.lock ();
    int after = count;
    mutex.unlock ();
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
    bool thrown = false;
    try {
        Cron.every (Duration.ofSeconds (0));
    } catch (CronError e) {
        thrown = true;
        assert (e is CronError.INVALID_ARGUMENT);
    }
    assert (thrown);
}

void testAtInvalidRange () {
    bool thrown = false;
    try {
        Cron.at (24, 0);
    } catch (CronError e) {
        thrown = true;
        assert (e is CronError.INVALID_ARGUMENT);
    }
    assert (thrown);
}

void testExpressionInvalid () {
    bool thrown = false;
    try {
        new Cron ("invalid expression");
    } catch (CronError e) {
        thrown = true;
        assert (e is CronError.INVALID_EXPRESSION);
    }
    assert (thrown);
}

void testScheduleWithDelayInvalid () {
    var cron = mustEvery (Duration.ofSeconds (1));
    bool thrown = false;
    try {
        cron.scheduleWithDelay (Duration.ofSeconds (-1), () => {});
    } catch (CronError e) {
        thrown = true;
        assert (e is CronError.INVALID_ARGUMENT);
    }
    cron.cancel ();
    assert (thrown);
}
