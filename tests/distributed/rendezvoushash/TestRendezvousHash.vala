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
    var firstNode = hash.getNode ("key-1");
    assert (firstNode.isOk ());
    assert (firstNode.unwrap () == null);

    var addA = hash.addNode ("node-a");
    assert (addA.isOk ());
    assert (addA.unwrap () == true);

    var addB = hash.addNode ("node-b");
    assert (addB.isOk ());
    assert (addB.unwrap () == true);

    var addADuplicate = hash.addNode ("node-a");
    assert (addADuplicate.isOk ());
    assert (addADuplicate.unwrap () == false);

    var containsA = hash.containsNode ("node-a");
    assert (containsA.isOk ());
    assert (containsA.unwrap () == true);
    assert (hash.nodeCount () == 2);

    var nodeResult = hash.getNode ("user:42");
    assert (nodeResult.isOk ());
    string ? node = nodeResult.unwrap ();
    assert (node == "node-a" || node == "node-b");

    var removedB = hash.removeNode ("node-b");
    assert (removedB.isOk ());
    assert (removedB.unwrap () == true);

    removedB = hash.removeNode ("node-b");
    assert (removedB.isOk ());
    assert (removedB.unwrap () == false);
    assert (hash.nodeCount () == 1);
}

void testGetTopNodes () {
    var hash = new RendezvousHash ();
    assert (hash.addNode ("n1").isOk ());
    assert (hash.addNode ("n2").isOk ());
    assert (hash.addNode ("n3").isOk ());

    var top2Result = hash.getTopNodes ("key", 2);
    assert (top2Result.isOk ());
    ArrayList<string> top2 = top2Result.unwrap ();
    assert (top2.size () == 2);
    assert (top2.get (0) != top2.get (1));

    var top10Result = hash.getTopNodes ("key", 10);
    assert (top10Result.isOk ());
    ArrayList<string> top10 = top10Result.unwrap ();
    assert (top10.size () == 3);

    var assignedResult = hash.getNode ("key");
    assert (assignedResult.isOk ());
    string ? assigned = assignedResult.unwrap ();
    assert (assigned == top10.get (0));
}

void testSetWeight () {
    var hash = new RendezvousHash ();
    assert (hash.addNode ("slow").isOk ());
    assert (hash.addNode ("fast").isOk ());

    var weightedFast = hash.setWeight ("fast", 3.0);
    assert (weightedFast.isOk ());
    assert (weightedFast.unwrap () == true);

    var weightedMissing = hash.setWeight ("missing", 2.0);
    assert (weightedMissing.isOk ());
    assert (weightedMissing.unwrap () == false);

    var keys = new ArrayList<string> ();
    for (int i = 0; i < 3000; i++) {
        keys.add ("weight-key-%d".printf (i));
    }

    HashMap<string, int> dist = hash.distribution (keys);
    int slowCount = dist.getOrDefault ("slow", 0);
    int fastCount = dist.getOrDefault ("fast", 0);
    assert (fastCount > slowCount);
}

void testDistribution () {
    var hash = new RendezvousHash ();
    assert (hash.addNode ("n1").isOk ());
    assert (hash.addNode ("n2").isOk ());
    assert (hash.addNode ("n3").isOk ());

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
}

void testRebalanceEstimate () {
    var hash = new RendezvousHash ();
    assert (hash.addNode ("n1").isOk ());
    assert (hash.addNode ("n2").isOk ());
    assert (hash.addNode ("n3").isOk ());

    var keys = new ArrayList<string> ();
    for (int i = 0; i < 200; i++) {
        keys.add ("k-%d".printf (i));
    }

    double ratio = hash.rebalanceEstimate (keys);
    assert (ratio > 0.0);
    assert (ratio < 1.0);

    var empty = new RendezvousHash ();
    assert (empty.rebalanceEstimate (keys) == 0.0);
}

void testClear () {
    var hash = new RendezvousHash ();
    assert (hash.addNode ("n1").isOk ());
    assert (hash.addNode ("n2").isOk ());
    hash.clear ();

    assert (hash.nodeCount () == 0);
    var node = hash.getNode ("key");
    assert (node.isOk ());
    assert (node.unwrap () == null);
    assert (hash.distribution (new ArrayList<string> ()).size () == 0);
}

void testInvalidArguments () {
    var hash = new RendezvousHash ();

    var invalidNode = hash.addNode ("");
    assert (invalidNode.isError ());
    assert (invalidNode.unwrapError () is RendezvousHashError.INVALID_ARGUMENT);
    assert (invalidNode.unwrapError ().message == "nodeId must not be empty");

    var invalidKey = hash.getNode ("");
    assert (invalidKey.isError ());
    assert (invalidKey.unwrapError () is RendezvousHashError.INVALID_ARGUMENT);
    assert (invalidKey.unwrapError ().message == "key must not be empty");

    assert (hash.addNode ("n1").isOk ());

    var invalidTopN = hash.getTopNodes ("k", 0);
    assert (invalidTopN.isError ());
    assert (invalidTopN.unwrapError () is RendezvousHashError.INVALID_ARGUMENT);
    assert (invalidTopN.unwrapError ().message == "n must be positive");

    var invalidWeight = hash.setWeight ("n1", 0.0);
    assert (invalidWeight.isError ());
    assert (invalidWeight.unwrapError () is RendezvousHashError.INVALID_ARGUMENT);
    assert (invalidWeight.unwrapError ().message == "weight must be positive");
}
