using Vala.Collections;
using Vala.Io;
using Vala.Time;

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/io/filetree/testWalkAndDepth", testWalkAndDepth);
    Test.add_func ("/io/filetree/testFindMethods", testFindMethods);
    Test.add_func ("/io/filetree/testFindBySizeAndModifiedAfter", testFindBySizeAndModifiedAfter);
    Test.add_func ("/io/filetree/testCopyTree", testCopyTree);
    Test.add_func ("/io/filetree/testCopyTreeWithFilter", testCopyTreeWithFilter);
    Test.add_func ("/io/filetree/testSync", testSync);
    Test.add_func ("/io/filetree/testDeleteTree", testDeleteTree);
    Test.add_func ("/io/filetree/testTotalSizeAndCountFiles", testTotalSizeAndCountFiles);
    Test.add_func ("/io/filetree/testFlatten", testFlatten);
    Test.run ();
}

string pathFor (string name) {
    return "%s/valacore/ut/filetree_%s_%s".printf (Environment.get_tmp_dir (), name, GLib.Uuid.string_random ());
}

void cleanup (string path) {
    FileTree.deleteTree (new Vala.Io.Path (path));
}

void createSampleTree (string root) {
    cleanup (root);
    Files.makeDirs (new Vala.Io.Path (root + "/a/b"));
    Files.makeDirs (new Vala.Io.Path (root + "/c"));
    Files.writeText (new Vala.Io.Path (root + "/root.txt"), "r");
    Files.writeText (new Vala.Io.Path (root + "/a/a1.log"), "alpha");
    Files.writeText (new Vala.Io.Path (root + "/a/b/nested.txt"), "nested");
    Files.writeText (new Vala.Io.Path (root + "/c/data.bin"), "1234567890");
}

bool containsPath (ArrayList<Vala.Io.Path> paths, string value) {
    for (int i = 0; i < paths.size (); i++) {
        Vala.Io.Path ? p = paths.get (i);
        if (p != null && p.toString () == value) {
            return true;
        }
    }
    return false;
}

void testWalkAndDepth () {
    string root = pathFor ("walk");
    createSampleTree (root);
    try {
        var all = FileTree.walk (new Vala.Io.Path (root));
        assert (all.size () == 4);
        assert (containsPath (all, root + "/root.txt"));
        assert (containsPath (all, root + "/a/a1.log"));
        assert (containsPath (all, root + "/a/b/nested.txt"));
        assert (containsPath (all, root + "/c/data.bin"));

        var depth1 = FileTree.walkWithDepth (new Vala.Io.Path (root), 1);
        assert (depth1.size () == 1);
        assert (containsPath (depth1, root + "/root.txt"));

        var depth2 = FileTree.walkWithDepth (new Vala.Io.Path (root), 2);
        assert (depth2.size () == 3);
        assert (containsPath (depth2, root + "/root.txt"));
        assert (containsPath (depth2, root + "/a/a1.log"));
        assert (containsPath (depth2, root + "/c/data.bin"));
    } finally {
        cleanup (root);
    }
}

void testFindMethods () {
    string root = pathFor ("find");
    createSampleTree (root);
    try {
        var txt = FileTree.find (new Vala.Io.Path (root), "*.txt");
        assert (txt.size () == 2);
        assert (containsPath (txt, root + "/root.txt"));
        assert (containsPath (txt, root + "/a/b/nested.txt"));

        var regex = FileTree.findByRegex (new Vala.Io.Path (root), ".*a1\\.log$");
        assert (regex.size () == 1);
        assert (containsPath (regex, root + "/a/a1.log"));

        var badRegex = FileTree.findByRegex (new Vala.Io.Path (root), "[");
        assert (badRegex.size () == 0);
    } finally {
        cleanup (root);
    }
}

void testFindBySizeAndModifiedAfter () {
    string root = pathFor ("size_and_mtime");
    createSampleTree (root);
    try {
        var sized = FileTree.findBySize (new Vala.Io.Path (root), 5, 6);
        assert (sized.size () == 2);
        assert (containsPath (sized, root + "/a/a1.log"));
        assert (containsPath (sized, root + "/a/b/nested.txt"));

        var marker = Vala.Time.DateTime.now ();
        string newFile = root + "/new.txt";

        bool found = false;
        int64 deadline = GLib.get_monotonic_time () + 2 * 1000 * 1000;
        while (GLib.get_monotonic_time () < deadline) {
            assert (Files.writeText (new Vala.Io.Path (newFile), "newer"));
            var modified = FileTree.findModifiedAfter (new Vala.Io.Path (root), marker);
            if (containsPath (modified, newFile)) {
                found = true;
                break;
            }
            Posix.usleep (20000);
        }

        assert (found);
    } finally {
        cleanup (root);
    }
}

void testCopyTree () {
    string src = pathFor ("copy_src");
    string dst = pathFor ("copy_dst");
    createSampleTree (src);
    cleanup (dst);
    try {
        assert (FileTree.copyTree (new Vala.Io.Path (src), new Vala.Io.Path (dst)));
        assert (Files.exists (new Vala.Io.Path (dst + "/root.txt")));
        assert (Files.exists (new Vala.Io.Path (dst + "/a/a1.log")));
        assert (Files.exists (new Vala.Io.Path (dst + "/a/b/nested.txt")));
        assert (Files.exists (new Vala.Io.Path (dst + "/c/data.bin")));
        assert (Files.readAllText (new Vala.Io.Path (dst + "/a/b/nested.txt")) == "nested");
    } finally {
        cleanup (src);
        cleanup (dst);
    }
}

void testCopyTreeWithFilter () {
    string src = pathFor ("copy_filter_src");
    string dst = pathFor ("copy_filter_dst");
    createSampleTree (src);
    cleanup (dst);
    try {
        bool ok = FileTree.copyTreeWithFilter (new Vala.Io.Path (src), new Vala.Io.Path (dst), (p) => {
            return p.toString ().has_suffix (".txt") || Files.isDir (p);
        });
        assert (ok);

        assert (Files.exists (new Vala.Io.Path (dst + "/root.txt")));
        assert (Files.exists (new Vala.Io.Path (dst + "/a/b/nested.txt")));
        assert (Files.exists (new Vala.Io.Path (dst + "/a/a1.log")) == false);
        assert (Files.exists (new Vala.Io.Path (dst + "/c/data.bin")) == false);
    } finally {
        cleanup (src);
        cleanup (dst);
    }
}

void testSync () {
    string src = pathFor ("sync_src");
    string dst = pathFor ("sync_dst");
    cleanup (src);
    cleanup (dst);
    try {
        Files.makeDirs (new Vala.Io.Path (src + "/nested"));
        Files.writeText (new Vala.Io.Path (src + "/a.txt"), "new-value");
        Files.writeText (new Vala.Io.Path (src + "/nested/b.txt"), "bbb");

        Files.makeDirs (new Vala.Io.Path (dst + "/nested"));
        Files.writeText (new Vala.Io.Path (dst + "/a.txt"), "old");
        Files.writeText (new Vala.Io.Path (dst + "/extra.txt"), "keep-me");

        assert (FileTree.sync (new Vala.Io.Path (src), new Vala.Io.Path (dst)));
        assert (Files.readAllText (new Vala.Io.Path (dst + "/a.txt")) == "new-value");
        assert (Files.readAllText (new Vala.Io.Path (dst + "/nested/b.txt")) == "bbb");
        assert (Files.exists (new Vala.Io.Path (dst + "/extra.txt")));
    } finally {
        cleanup (src);
        cleanup (dst);
    }
}

void testDeleteTree () {
    string root = pathFor ("delete");
    createSampleTree (root);
    try {
        assert (Files.exists (new Vala.Io.Path (root)));
        assert (FileTree.deleteTree (new Vala.Io.Path (root)));
        assert (Files.exists (new Vala.Io.Path (root)) == false);
    } finally {
        cleanup (root);
    }
}

void testTotalSizeAndCountFiles () {
    string root = pathFor ("totals");
    createSampleTree (root);
    try {
        assert (FileTree.countFiles (new Vala.Io.Path (root)) == 4);
        assert (FileTree.totalSize (new Vala.Io.Path (root)) == 22);
    } finally {
        cleanup (root);
    }
}

void testFlatten () {
    string src = pathFor ("flatten_src");
    string dst = pathFor ("flatten_dst");
    cleanup (src);
    cleanup (dst);
    try {
        Files.makeDirs (new Vala.Io.Path (src + "/x"));
        Files.makeDirs (new Vala.Io.Path (src + "/y"));
        Files.writeText (new Vala.Io.Path (src + "/x/same.txt"), "x");
        Files.writeText (new Vala.Io.Path (src + "/y/same.txt"), "y");
        Files.writeText (new Vala.Io.Path (src + "/y/other.log"), "z");

        assert (FileTree.flatten (new Vala.Io.Path (src), new Vala.Io.Path (dst)));
        assert (Files.exists (new Vala.Io.Path (dst + "/same.txt")));
        assert (Files.exists (new Vala.Io.Path (dst + "/same-1.txt")));
        assert (Files.exists (new Vala.Io.Path (dst + "/other.log")));
        assert (FileTree.countFiles (new Vala.Io.Path (dst)) == 3);
    } finally {
        cleanup (src);
        cleanup (dst);
    }
}
