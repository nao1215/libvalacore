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
    var firstNode = ring.getNode ("k");
    assert (firstNode.isOk ());
    assert (firstNode.unwrap () == null);

    var addA = ring.addNode ("node-a");
    assert (addA.isOk ());
    assert (addA.unwrap () == true);

    var addB = ring.addNode ("node-b");
    assert (addB.isOk ());
    assert (addB.unwrap () == true);

    var addADuplicate = ring.addNode ("node-a");
    assert (addADuplicate.isOk ());
    assert (addADuplicate.unwrap () == false);

    var containsA = ring.containsNode ("node-a");
    assert (containsA.isOk ());
    assert (containsA.unwrap () == true);

    assert (ring.nodeCount () == 2);
    assert (ring.virtualNodeCount () == 200);

    var nodeResult = ring.getNode ("user:42");
    assert (nodeResult.isOk ());
    string ? node = nodeResult.unwrap ();
    assert (node == "node-a" || node == "node-b");
}

void testGetNodes () {
    var ring = new ConsistentHash ();
    assert (ring.addNode ("n1").isOk ());
    assert (ring.addNode ("n2").isOk ());
    assert (ring.addNode ("n3").isOk ());

    var nodesResult = ring.getNodes ("key", 2);
    assert (nodesResult.isOk ());
    ArrayList<string> nodes = nodesResult.unwrap ();
    assert (nodes.size () == 2);
    assert (nodes.get (0) != nodes.get (1));

    var allNodesResult = ring.getNodes ("key", 10);
    assert (allNodesResult.isOk ());
    ArrayList<string> allNodes = allNodesResult.unwrap ();
    assert (allNodes.size () == 3);
}

void testWithVirtualNodes () {
    var ring = new ConsistentHash ();
    assert (ring.addNode ("n1").isOk ());
    assert (ring.addNode ("n2").isOk ());
    assert (ring.virtualNodeCount () == 200);

    var configured = ring.withVirtualNodes (10);
    assert (configured.isOk ());
    assert (ring.virtualNodeCount () == 20);
}

void testDistribution () {
    var ring = new ConsistentHash ();
    assert (ring.addNode ("n1").isOk ());
    assert (ring.addNode ("n2").isOk ());

    var keys = new ArrayList<string> ();
    for (int i = 0; i < 100; i++) {
        keys.add ("key-%d".printf (i));
    }

    HashMap<string, int> dist = ring.distribution (keys);
    assert (dist.size () == 2);

    int total = dist.getOrDefault ("n1", 0) + dist.getOrDefault ("n2", 0);
    assert (total == 100);
}

void testRebalanceEstimate () {
    var ring = new ConsistentHash ();
    assert (ring.addNode ("n1").isOk ());
    assert (ring.addNode ("n2").isOk ());
    assert (ring.addNode ("n3").isOk ());

    var keys = new ArrayList<string> ();
    for (int i = 0; i < 200; i++) {
        keys.add ("sample-%d".printf (i));
    }

    double ratio = ring.rebalanceEstimate (keys);
    assert (ratio > 0.0);
    assert (ratio < 1.0);
}

void testRemoveAndClear () {
    var ring = new ConsistentHash ();
    assert (ring.addNode ("n1").isOk ());
    assert (ring.addNode ("n2").isOk ());

    var removedN1 = ring.removeNode ("n1");
    assert (removedN1.isOk ());
    assert (removedN1.unwrap () == true);

    removedN1 = ring.removeNode ("n1");
    assert (removedN1.isOk ());
    assert (removedN1.unwrap () == false);

    var containsN1 = ring.containsNode ("n1");
    assert (containsN1.isOk ());
    assert (containsN1.unwrap () == false);
    assert (ring.nodeCount () == 1);

    ring.clear ();
    assert (ring.nodeCount () == 0);
    assert (ring.virtualNodeCount () == 0);

    var nodeAfterClear = ring.getNode ("k");
    assert (nodeAfterClear.isOk ());
    assert (nodeAfterClear.unwrap () == null);
}

void testInvalidArguments () {
    var ring = new ConsistentHash ();

    var invalidReplicas = ring.withVirtualNodes (0);
    assert (invalidReplicas.isError ());
    assert (invalidReplicas.unwrapError () is ConsistentHashError.INVALID_ARGUMENT);
    assert (invalidReplicas.unwrapError ().message == "replicas must be positive");

    var invalidNode = ring.addNode ("");
    assert (invalidNode.isError ());
    assert (invalidNode.unwrapError () is ConsistentHashError.INVALID_ARGUMENT);
    assert (invalidNode.unwrapError ().message == "nodeId must not be empty");

    var invalidKey = ring.getNode ("");
    assert (invalidKey.isError ());
    assert (invalidKey.unwrapError () is ConsistentHashError.INVALID_ARGUMENT);
    assert (invalidKey.unwrapError ().message == "key must not be empty");

    assert (ring.addNode ("n1").isOk ());
    var invalidCount = ring.getNodes ("k", 0);
    assert (invalidCount.isError ());
    assert (invalidCount.unwrapError () is ConsistentHashError.INVALID_ARGUMENT);
    assert (invalidCount.unwrapError ().message == "count must be positive");
}
