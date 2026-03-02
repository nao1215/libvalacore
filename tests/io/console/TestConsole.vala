using Vala.Io;
using Vala.Collections;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/io/console/testConstruct", testConstruct);
    Test.add_func ("/io/console/testIsTTY", testIsTTY);
    Test.add_func ("/io/console/testReadPasswordWhenNotTTY", testReadPasswordWhenNotTTY);
    Test.run ();
}

void testConstruct () {
    Console console = new Console ();
    assert (console != null);
}

void testIsTTY () {
    assert (Console.isTTY () == Posix.isatty (Posix.STDIN_FILENO));
}

void testReadPasswordWhenNotTTY () {
    if (Console.isTTY ()) {
        Test.skip ("stdin is a tty in this environment");
        return;
    }

    Result<string, GLib.Error> password = Console.readPassword ();
    assert (password.isError ());
    assert (password.unwrapError () is ConsoleError.NOT_TTY);
    assert (password.unwrapError ().message == "stdin is not a tty");
}
