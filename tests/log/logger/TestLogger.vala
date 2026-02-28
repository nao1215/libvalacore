using Vala.Log;

private class CounterHandler : GLib.Object, LogHandler {
    public int count = 0;

    public void handle (LogLevel level, string loggerName, string message) {
        count++;
    }
}

private class CaptureHandler : GLib.Object, LogHandler {
    public LogLevel level = LogLevel.ERROR;
    public string loggerName = "";
    public string message = "";

    public void handle (LogLevel level, string loggerName, string message) {
        this.level = level;
        this.loggerName = loggerName;
        this.message = message;
    }
}

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/log/logger/testGetLogger", testGetLogger);
    Test.add_func ("/log/logger/testLevelFilter", testLevelFilter);
    Test.add_func ("/log/logger/testAddHandler", testAddHandler);
    Test.run ();
}

string uniqueLoggerName (string prefix) {
    return "%s-%lld".printf (prefix, GLib.get_monotonic_time ());
}

void testGetLogger () {
    string loggerName = uniqueLoggerName ("same-name");
    Logger a = Logger.getLogger (loggerName);
    Logger b = Logger.getLogger (loggerName);
    assert (a == b);
}

void testLevelFilter () {
    Logger logger = Logger.getLogger (uniqueLoggerName ("level-filter"));
    logger.setLevel (LogLevel.WARN);

    CounterHandler handler = new CounterHandler ();
    logger.addHandler (handler);

    logger.debug ("debug");
    logger.info ("info");
    logger.warn ("warn");
    logger.error ("error");

    assert (handler.count == 2);
}

void testAddHandler () {
    string loggerName = uniqueLoggerName ("capture");
    Logger logger = Logger.getLogger (loggerName);
    logger.setLevel (LogLevel.DEBUG);

    CaptureHandler handler = new CaptureHandler ();
    logger.addHandler (handler);

    logger.info ("hello");

    assert (handler.level == LogLevel.INFO);
    assert (handler.loggerName == loggerName);
    assert (handler.message == "hello");
}
