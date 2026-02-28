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

void testGetLogger () {
    Logger a = Logger.getLogger ("same-name");
    Logger b = Logger.getLogger ("same-name");
    assert (a == b);
}

void testLevelFilter () {
    Logger logger = Logger.getLogger ("level-filter");
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
    Logger logger = Logger.getLogger ("capture");
    logger.setLevel (LogLevel.DEBUG);

    CaptureHandler handler = new CaptureHandler ();
    logger.addHandler (handler);

    logger.info ("hello");

    assert (handler.level == LogLevel.INFO);
    assert (handler.loggerName == "capture");
    assert (handler.message == "hello");
}
