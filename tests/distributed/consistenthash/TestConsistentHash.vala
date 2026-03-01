using Vala.Collections;
using Vala.Distributed;

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/distributed/consistenthash/testBasic", testBasic);
    Test.add_func ("/distributed/consistenthash/testGetNodes", testGetNodes);
    Test.add_func ("/distributed/consistenthash/testWithVirtualNodes", testWithVirtualNodes);
    Test.add_func ("/distributed/consistenthash/testDistribution", testDistribution);
    Test.add_func ("/distributed/consistenthash/testRebalanceEstimate", testRebalanceEstimate);
    Test.add_func ("/distributed/consistenthash/testRemoveAndClear", testRemoveAndClear);
    Test.add_func ("/distributed/consistenthash/testInvalidArguments", testInvalidArguments);

    Test.run ();
}

void testBasic () {
    var ring = new ConsistentHash ();
    try {
        assert (ring.getNode ("k") == null);
        assert (ring.addNode ("node-a") == true);
        assert (ring.addNode ("node-b") == true);
        assert (ring.addNode ("node-a") == false);
        assert (ring.containsNode ("node-a") == true);
        assert (ring.nodeCount () == 2);
        assert (ring.virtualNodeCount () == 200);

        string ? node = ring.getNode ("user:42");
        assert (node == "node-a" || node == "node-b");
    } catch (ConsistentHashError e) {
        assert_not_reached ();
    }
}

void testGetNodes () {
    var ring = new ConsistentHash ();
    try {
        ring.addNode ("n1");
        ring.addNode ("n2");
        ring.addNode ("n3");

        ArrayList<string> nodes = ring.getNodes ("key", 2);
        assert (nodes.size () == 2);
        assert (nodes.get (0) != nodes.get (1));

        ArrayList<string> allNodes = ring.getNodes ("key", 10);
        assert (allNodes.size () == 3);
    } catch (ConsistentHashError e) {
        assert_not_reached ();
    }
}

void testWithVirtualNodes () {
    var ring = new ConsistentHash ();
    try {
        ring.addNode ("n1");
        ring.addNode ("n2");
        assert (ring.virtualNodeCount () == 200);

        ring.withVirtualNodes (10);
        assert (ring.virtualNodeCount () == 20);
    } catch (ConsistentHashError e) {
        assert_not_reached ();
    }
}

void testDistribution () {
    var ring = new ConsistentHash ();
    try {
        ring.addNode ("n1");
        ring.addNode ("n2");

        var keys = new ArrayList<string> ();
        for (int i = 0; i < 100; i++) {
            keys.add ("key-%d".printf (i));
        }

        HashMap<string, int> dist = ring.distribution (keys);
        assert (dist.size () == 2);

        int total = dist.getOrDefault ("n1", 0) + dist.getOrDefault ("n2", 0);
        assert (total == 100);
    } catch (ConsistentHashError e) {
        assert_not_reached ();
    }
}

void testRebalanceEstimate () {
    var ring = new ConsistentHash ();
    try {
        ring.addNode ("n1");
        ring.addNode ("n2");
        ring.addNode ("n3");

        var keys = new ArrayList<string> ();
        for (int i = 0; i < 200; i++) {
            keys.add ("sample-%d".printf (i));
        }

        double ratio = ring.rebalanceEstimate (keys);
        assert (ratio > 0.0);
        assert (ratio < 1.0);
    } catch (ConsistentHashError e) {
        assert_not_reached ();
    }
}

void testRemoveAndClear () {
    var ring = new ConsistentHash ();
    try {
        ring.addNode ("n1");
        ring.addNode ("n2");
        assert (ring.removeNode ("n1") == true);
        assert (ring.removeNode ("n1") == false);
        assert (ring.containsNode ("n1") == false);
        assert (ring.nodeCount () == 1);

        ring.clear ();
        assert (ring.nodeCount () == 0);
        assert (ring.virtualNodeCount () == 0);
        assert (ring.getNode ("k") == null);
    } catch (ConsistentHashError e) {
        assert_not_reached ();
    }
}

void testInvalidArguments () {
    var ring = new ConsistentHash ();

    bool replicasThrown = false;
    try {
        ring.withVirtualNodes (0);
    } catch (ConsistentHashError e) {
        replicasThrown = true;
        assert (e is ConsistentHashError.INVALID_ARGUMENT);
    }
    assert (replicasThrown);

    bool nodeThrown = false;
    try {
        ring.addNode ("");
    } catch (ConsistentHashError e) {
        nodeThrown = true;
        assert (e is ConsistentHashError.INVALID_ARGUMENT);
    }
    assert (nodeThrown);

    bool keyThrown = false;
    try {
        ring.getNode ("");
    } catch (ConsistentHashError e) {
        keyThrown = true;
        assert (e is ConsistentHashError.INVALID_ARGUMENT);
    }
    assert (keyThrown);

    bool countThrown = false;
    try {
        ring.addNode ("n1");
    } catch (ConsistentHashError e) {
        assert_not_reached ();
    }
    try {
        ring.getNodes ("k", 0);
    } catch (ConsistentHashError e) {
        countThrown = true;
        assert (e is ConsistentHashError.INVALID_ARGUMENT);
    }
    assert (countThrown);
}
