using Vala.Io;
using Vala.Lang;

string ? test_program_path = null;
string ? child_output_path = null;

void main (string[] args) {
    if (args.length == 3 && args[1] == "--shutdownhooks-child-single") {
        runChildSingle (args[2]);
        return;
    }
    if (args.length == 3 && args[1] == "--shutdownhooks-child-order") {
        runChildOrder (args[2]);
        return;
    }

    test_program_path = args[0];
    Test.init (ref args);
    Test.add_func ("/lang/shutdownhooks/testConstruct", testConstruct);
    Test.add_func ("/lang/shutdownhooks/testSingleHookRunsAtExit", testSingleHookRunsAtExit);
    Test.add_func ("/lang/shutdownhooks/testHooksRunInReverseOrder", testHooksRunInReverseOrder);
    Test.run ();
}

void testConstruct () {
    ShutdownHooks hooks = new ShutdownHooks ();
    assert (hooks != null);
}

void testSingleHookRunsAtExit () {
    Vala.Io.Path ? tmp = Files.tempFile ("shutdownhooks", ".txt");
    assert (tmp != null);

    bool spawned = runChild ("--shutdownhooks-child-single", tmp.toString ());
    assert (spawned == true);

    string ? text = Files.readAllText (tmp);
    assert (text == "done");

    assert (Files.remove (tmp) == true);
}

void testHooksRunInReverseOrder () {
    Vala.Io.Path ? tmp = Files.tempFile ("shutdownhooks-order", ".txt");
    assert (tmp != null);
    assert (Files.writeText (tmp, "") == true);

    bool spawned = runChild ("--shutdownhooks-child-order", tmp.toString ());
    assert (spawned == true);

    string ? text = Files.readAllText (tmp);
    assert (text == "second-first");

    assert (Files.remove (tmp) == true);
}

bool runChild (string mode, string outputPath) {
    if (test_program_path == null) {
        return false;
    }

    string[] argv = { test_program_path, mode, outputPath, null };
    int waitStatus = 0;
    try {
        GLib.Process.spawn_sync (null, argv, null, SpawnFlags.SEARCH_PATH, null, null, null, out waitStatus);
        return GLib.Process.check_wait_status (waitStatus);
    } catch (GLib.Error e) {
        return false;
    }
}

void runChildSingle (string outputPath) {
    child_output_path = outputPath;
    ShutdownHooks.addHook (writeDoneHook);
}

void runChildOrder (string outputPath) {
    child_output_path = outputPath;
    ShutdownHooks.addHook (appendFirstHook);
    ShutdownHooks.addHook (appendSecondHook);
}

void writeDoneHook () {
    if (child_output_path == null) {
        return;
    }
    Files.writeText (new Vala.Io.Path (child_output_path), "done");
}

void appendFirstHook () {
    if (child_output_path == null) {
        return;
    }
    Files.appendText (new Vala.Io.Path (child_output_path), "first");
}

void appendSecondHook () {
    if (child_output_path == null) {
        return;
    }
    Files.appendText (new Vala.Io.Path (child_output_path), "second-");
}
