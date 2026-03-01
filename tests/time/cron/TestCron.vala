using Vala.Time;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/time/cron/testEverySchedule", testEverySchedule);
    Test.add_func ("/time/cron/testScheduleWithDelay", testScheduleWithDelay);
    Test.add_func ("/time/cron/testExpressionAndAt", testExpressionAndAt);
    Test.add_func ("/time/cron/testCancel", testCancel);

    Test.run ();
}

void testEverySchedule () {
    var cron = Cron.every (Duration.ofSeconds (1));
    int count = 0;
    cron.schedule (() => {
        count++;
    });

    Posix.usleep (2300000);
    cron.cancel ();
    assert (count >= 2);
}

void testScheduleWithDelay () {
    var cron = Cron.every (Duration.ofSeconds (1));
    int count = 0;
    cron.scheduleWithDelay (Duration.ofSeconds (2), () => {
        count++;
    });

    Posix.usleep (1200000);
    assert (count == 0);

    Posix.usleep (1700000);
    cron.cancel ();
    assert (count >= 1);
}

void testExpressionAndAt () {
    var expr = new Cron ("*/5 * * * *");
    Vala.Time.DateTime exprNext = expr.nextFireTime ();
    assert (exprNext.toUnixTimestamp () > Vala.Time.DateTime.now ().toUnixTimestamp ());

    var daily = Cron.at (23, 59);
    Vala.Time.DateTime dailyNext = daily.nextFireTime ();
    assert (dailyNext.hour () == 23);
    assert (dailyNext.minute () == 59);
}

void testCancel () {
    var cron = Cron.every (Duration.ofSeconds (1));
    cron.schedule (() => {});
    assert (cron.isRunning () == true);

    cron.cancel ();
    assert (cron.isRunning () == false);
}
