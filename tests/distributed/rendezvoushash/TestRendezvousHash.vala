using Vala.Collections;
using Vala.Distributed;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/distributed/rendezvoushash/testBasic", testBasic);
    Test.add_func ("/distributed/rendezvoushash/testGetTopNodes", testGetTopNodes);
    Test.add_func ("/distributed/rendezvoushash/testSetWeight", testSetWeight);
    Test.add_func ("/distributed/rendezvoushash/testDistribution", testDistribution);
    Test.add_func ("/distributed/rendezvoushash/testRebalanceEstimate", testRebalanceEstimate);
    Test.add_func ("/distributed/rendezvoushash/testClear", testClear);
    Test.add_func ("/distributed/rendezvoushash/testInvalidArguments", testInvalidArguments);

    Test.run ();
}

void testBasic () {
    var hash = new RendezvousHash ();
    try {
        assert (hash.getNode ("key-1") == null);

        assert (hash.addNode ("node-a") == true);
        assert (hash.addNode ("node-b") == true);
        assert (hash.addNode ("node-a") == false);
        assert (hash.containsNode ("node-a") == true);
        assert (hash.nodeCount () == 2);

        string ? node = hash.getNode ("user:42");
        assert (node == "node-a" || node == "node-b");

        assert (hash.removeNode ("node-b") == true);
        assert (hash.removeNode ("node-b") == false);
        assert (hash.nodeCount () == 1);
    } catch (RendezvousHashError e) {
        assert_not_reached ();
    }
}

void testGetTopNodes () {
    var hash = new RendezvousHash ();
    try {
        hash.addNode ("n1");
        hash.addNode ("n2");
        hash.addNode ("n3");

        ArrayList<string> top2 = hash.getTopNodes ("key", 2);
        assert (top2.size () == 2);
        assert (top2.get (0) != top2.get (1));

        ArrayList<string> top10 = hash.getTopNodes ("key", 10);
        assert (top10.size () == 3);

        string ? assigned = hash.getNode ("key");
        assert (assigned == top10.get (0));
    } catch (RendezvousHashError e) {
        assert_not_reached ();
    }
}

void testSetWeight () {
    var hash = new RendezvousHash ();
    try {
        hash.addNode ("slow");
        hash.addNode ("fast");
        assert (hash.setWeight ("fast", 3.0) == true);
        assert (hash.setWeight ("missing", 2.0) == false);

        var keys = new ArrayList<string> ();
        for (int i = 0; i < 3000; i++) {
            keys.add ("weight-key-%d".printf (i));
        }

        HashMap<string, int> dist = hash.distribution (keys);
        int slowCount = dist.getOrDefault ("slow", 0);
        int fastCount = dist.getOrDefault ("fast", 0);
        assert (fastCount > slowCount);
    } catch (RendezvousHashError e) {
        assert_not_reached ();
    }
}

void testDistribution () {
    var hash = new RendezvousHash ();
    try {
        hash.addNode ("n1");
        hash.addNode ("n2");
        hash.addNode ("n3");

        var keys = new ArrayList<string> ();
        for (int i = 0; i < 200; i++) {
            keys.add ("sample-%d".printf (i));
        }

        HashMap<string, int> dist = hash.distribution (keys);
        assert (dist.size () == 3);
        int total = dist.getOrDefault ("n1", 0) +
                    dist.getOrDefault ("n2", 0) +
                    dist.getOrDefault ("n3", 0);
        assert (total == 200);
    } catch (RendezvousHashError e) {
        assert_not_reached ();
    }
}

void testRebalanceEstimate () {
    var hash = new RendezvousHash ();
    try {
        hash.addNode ("n1");
        hash.addNode ("n2");
        hash.addNode ("n3");

        var keys = new ArrayList<string> ();
        for (int i = 0; i < 200; i++) {
            keys.add ("k-%d".printf (i));
        }

        double ratio = hash.rebalanceEstimate (keys);
        assert (ratio > 0.0);
        assert (ratio < 1.0);

        var empty = new RendezvousHash ();
        assert (empty.rebalanceEstimate (keys) == 0.0);
    } catch (RendezvousHashError e) {
        assert_not_reached ();
    }
}

void testClear () {
    var hash = new RendezvousHash ();
    try {
        hash.addNode ("n1");
        hash.addNode ("n2");
        hash.clear ();

        assert (hash.nodeCount () == 0);
        assert (hash.getNode ("key") == null);
        assert (hash.distribution (new ArrayList<string> ()).size () == 0);
    } catch (RendezvousHashError e) {
        assert_not_reached ();
    }
}

void testInvalidArguments () {
    var hash = new RendezvousHash ();

    bool nodeThrown = false;
    try {
        hash.addNode ("");
    } catch (RendezvousHashError e) {
        nodeThrown = true;
        assert (e is RendezvousHashError.INVALID_ARGUMENT);
    }
    assert (nodeThrown);

    bool keyThrown = false;
    try {
        hash.getNode ("");
    } catch (RendezvousHashError e) {
        keyThrown = true;
        assert (e is RendezvousHashError.INVALID_ARGUMENT);
    }
    assert (keyThrown);

    bool nThrown = false;
    try {
        hash.addNode ("n1");
    } catch (RendezvousHashError e) {
        assert_not_reached ();
    }
    try {
        hash.getTopNodes ("k", 0);
    } catch (RendezvousHashError e) {
        nThrown = true;
        assert (e is RendezvousHashError.INVALID_ARGUMENT);
    }
    assert (nThrown);

    bool weightThrown = false;
    try {
        hash.setWeight ("n1", 0.0);
    } catch (RendezvousHashError e) {
        weightThrown = true;
        assert (e is RendezvousHashError.INVALID_ARGUMENT);
    }
    assert (weightThrown);
}
