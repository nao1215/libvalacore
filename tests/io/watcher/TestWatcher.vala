using Vala.Io;
using Vala.Time;

delegate bool ConditionFunc ();

delegate FileWatcher WatchFactory () throws WatcherError;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/io/watcher/testWatchCreateDelete", testWatchCreateDelete);
    Test.add_func ("/io/watcher/testWatchRecursive", testWatchRecursive);
    Test.add_func ("/io/watcher/testWatchGlob", testWatchGlob);
    Test.add_func ("/io/watcher/testOnRenamed", testOnRenamed);
    Test.add_func ("/io/watcher/testDebounce", testDebounce);
    Test.add_func ("/io/watcher/testWatchMissingPath", testWatchMissingPath);
    Test.add_func ("/io/watcher/testWatchRecursiveOnFile", testWatchRecursiveOnFile);
    Test.run ();
}

string rootFor (string name) {
    return "/tmp/valacore/ut/watcher_" + name;
}

void cleanup (string root) {
    Posix.system ("rm -rf " + root);
}

bool waitUntil (owned ConditionFunc cond, int timeoutMillis) {
    int waited = 0;
    while (waited < timeoutMillis) {
        while (GLib.MainContext.default ().pending ()) {
            GLib.MainContext.default ().iteration (false);
        }
        if (cond ()) {
            return true;
        }
        Posix.usleep (10000);
        waited += 10;
    }
    return false;
}

FileWatcher mustWatchWith (owned WatchFactory fn) {
    FileWatcher ? watcher = null;
    try {
        watcher = fn ();
    } catch (WatcherError e) {
        assert_not_reached ();
    }
    if (watcher == null) {
        assert_not_reached ();
    }
    return watcher;
}

FileWatcher mustWatch (Vala.Io.Path path) {
    return mustWatchWith (() => {
        return Watcher.watch (path);
    });
}

FileWatcher mustWatchRecursive (Vala.Io.Path root) {
    return mustWatchWith (() => {
        return Watcher.watchRecursive (root);
    });
}

FileWatcher mustWatchGlob (Vala.Io.Path root, string glob) {
    return mustWatchWith (() => {
        return Watcher.watchGlob (root, glob);
    });
}

void testWatchCreateDelete () {
    string root = rootFor ("basic");
    cleanup (root);
    Files.makeDirs (new Vala.Io.Path (root));

    int created = 0;
    int deleted = 0;
    var watcher = mustWatch (new Vala.Io.Path (root))
                   .onCreated ((e) => {
        if (e.path.basename () == "a.txt") {
            created++;
        }
    })
                   .onDeleted ((e) => {
        if (e.path.basename () == "a.txt") {
            deleted++;
        }
    });
    Posix.usleep (100000);

    Files.appendText (new Vala.Io.Path (root + "/a.txt"), "a");
    assert (waitUntil (() => {
        return created > 0;
    }, 1500));

    Files.remove (new Vala.Io.Path (root + "/a.txt"));
    assert (waitUntil (() => {
        return deleted > 0;
    }, 1500));

    watcher.close ();
    cleanup (root);
}

void testWatchRecursive () {
    string root = rootFor ("recursive");
    cleanup (root);
    Files.makeDirs (new Vala.Io.Path (root + "/sub"));

    int created = 0;
    var watcher = mustWatchRecursive (new Vala.Io.Path (root))
                   .onCreated ((e) => {
        if (e.path.basename () == "nested.txt") {
            created++;
        }
    });
    Posix.usleep (100000);

    Files.appendText (new Vala.Io.Path (root + "/sub/nested.txt"), "x");
    assert (waitUntil (() => {
        return created > 0;
    }, 1500));

    watcher.close ();
    cleanup (root);
}

void testWatchGlob () {
    string root = rootFor ("glob");
    cleanup (root);
    Files.makeDirs (new Vala.Io.Path (root));

    int matched = 0;
    var watcher = mustWatchGlob (new Vala.Io.Path (root), "*.vala")
                   .onCreated ((e) => {
        matched++;
    });
    Posix.usleep (100000);

    Files.appendText (new Vala.Io.Path (root + "/ok.vala"), "x");
    Files.appendText (new Vala.Io.Path (root + "/skip.txt"), "x");

    assert (waitUntil (() => {
        return matched == 1;
    }, 1500));

    Posix.usleep (200000);
    while (GLib.MainContext.default ().pending ()) {
        GLib.MainContext.default ().iteration (false);
    }
    assert (matched == 1);

    watcher.close ();
    cleanup (root);
}

void testOnRenamed () {
    string root = rootFor ("rename");
    cleanup (root);
    Files.makeDirs (new Vala.Io.Path (root));
    Files.writeText (new Vala.Io.Path (root + "/old.txt"), "x");

    bool renamed = false;
    var watcher = mustWatch (new Vala.Io.Path (root + "/old.txt"))
                   .onRenamed ((from, to) => {
        if (from.path.basename () == "old.txt" && to.path.basename () == "new.txt") {
            renamed = true;
        }
    });
    Posix.usleep (100000);

    assert (Posix.system ("mv " + root + "/old.txt " + root + "/new.txt") == 0);
    assert (waitUntil (() => {
        return renamed;
    }, 1500));

    watcher.close ();
    cleanup (root);
}

void testDebounce () {
    string root = rootFor ("debounce");
    cleanup (root);
    Files.makeDirs (new Vala.Io.Path (root));

    int modified = 0;
    var watcher = mustWatch (new Vala.Io.Path (root))
                   .onModified ((e) => {
        if (e.path.basename () == "d.txt") {
            modified++;
        }
    })
                   .debounce (Duration.ofSeconds (1));
    Posix.usleep (100000);

    Files.writeText (new Vala.Io.Path (root + "/d.txt"), "1");
    Posix.usleep (50000);
    Files.writeText (new Vala.Io.Path (root + "/d.txt"), "2");

    assert (waitUntil (() => {
        return modified > 0;
    }, 1500));

    Posix.usleep (200000);
    while (GLib.MainContext.default ().pending ()) {
        GLib.MainContext.default ().iteration (false);
    }
    assert (modified == 1);

    watcher.close ();
    cleanup (root);
}

void testWatchMissingPath () {
    string missing = GLib.Path.build_filename (Environment.get_tmp_dir (), "missing-watcher-" + GLib.Uuid.string_random ());
    bool thrown = false;
    try {
        Watcher.watch (new Vala.Io.Path (missing));
    } catch (WatcherError e) {
        thrown = true;
        assert (e is WatcherError.PATH_NOT_FOUND);
    }
    assert (thrown);
}

void testWatchRecursiveOnFile () {
    string root = rootFor ("recursive_file");
    cleanup (root);
    Files.makeDirs (new Vala.Io.Path (root));
    Files.writeText (new Vala.Io.Path (root + "/single.txt"), "x");

    bool thrown = false;
    try {
        Watcher.watchRecursive (new Vala.Io.Path (root + "/single.txt"));
    } catch (WatcherError e) {
        thrown = true;
        assert (e is WatcherError.INVALID_ARGUMENT);
    }

    assert (thrown);
    cleanup (root);
}
