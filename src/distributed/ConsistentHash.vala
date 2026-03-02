using Vala.Collections;

namespace Vala.Distributed {
    /**
     * Recoverable ConsistentHash argument errors.
     */
    public errordomain ConsistentHashError {
        INVALID_ARGUMENT
    }

    internal class ConsistentHashEntry : GLib.Object {
        public uint hashValue { get; private set; }
        public string nodeId { get; private set; }

        public ConsistentHashEntry (uint hashValue, string nodeId) {
            this.hashValue = hashValue;
            this.nodeId = nodeId;
        }
    }

    /**
     * Consistent hash ring with virtual nodes.
     *
     * ConsistentHash minimizes key remapping when nodes are added or removed.
     * It is suitable for cache sharding and distributed routing.
     *
     * Example:
     * {{{
     *     var ring = new ConsistentHash ();
     *     ring.addNode ("node-a");
     *     ring.addNode ("node-b");
     *
     *     string? node = ring.getNode ("user:42");
     * }}}
     */
    public class ConsistentHash : GLib.Object {
        private int _replicas;
        private HashSet<string> _nodes;
        private ArrayList<ConsistentHashEntry> _ring;

        /**
         * Creates an empty hash ring.
         *
         * Default virtual node count is 100 per physical node.
         */
        public ConsistentHash () {
            _replicas = 100;
            _nodes = new HashSet<string> (GLib.str_hash, GLib.str_equal);
            _ring = new ArrayList<ConsistentHashEntry> ();
        }

        /**
         * Sets virtual node count per physical node.
         *
         * @param replicas virtual node count (must be > 0).
         * @return Result.ok(this ring) for chaining, or
         *         Result.error(ConsistentHashError.INVALID_ARGUMENT) when replicas is not positive.
         */
        public Result<ConsistentHash, GLib.Error> withVirtualNodes (int replicas) {
            if (replicas <= 0) {
                return Result.error<ConsistentHash, GLib.Error> (
                    new ConsistentHashError.INVALID_ARGUMENT ("replicas must be positive")
                );
            }

            _replicas = replicas;
            rebuildRing ();
            return Result.ok<ConsistentHash, GLib.Error> (this);
        }

        /**
         * Adds physical node to ring.
         *
         * @param nodeId node identifier.
         * @return Result.ok(true/false) for add outcome, or
         *         Result.error(ConsistentHashError.INVALID_ARGUMENT) when nodeId is empty.
         */
        public Result<bool, GLib.Error> addNode (string nodeId) {
            GLib.Error ? nodeError = validateNodeId (nodeId);
            if (nodeError != null) {
                return Result.error<bool, GLib.Error> (nodeError);
            }

            bool added = _nodes.add (nodeId);
            if (added) {
                rebuildRing ();
            }
            return Result.ok<bool, GLib.Error> (added);
        }

        /**
         * Removes physical node from ring.
         *
         * @param nodeId node identifier.
         * @return Result.ok(true/false) for remove outcome, or
         *         Result.error(ConsistentHashError.INVALID_ARGUMENT) when nodeId is empty.
         */
        public Result<bool, GLib.Error> removeNode (string nodeId) {
            GLib.Error ? nodeError = validateNodeId (nodeId);
            if (nodeError != null) {
                return Result.error<bool, GLib.Error> (nodeError);
            }

            bool removed = _nodes.remove (nodeId);
            if (removed) {
                rebuildRing ();
            }
            return Result.ok<bool, GLib.Error> (removed);
        }

        /**
         * Returns whether node exists.
         *
         * @param nodeId node identifier.
         * @return Result.ok(true/false) for existence, or
         *         Result.error(ConsistentHashError.INVALID_ARGUMENT) when nodeId is empty.
         */
        public Result<bool, GLib.Error> containsNode (string nodeId) {
            GLib.Error ? nodeError = validateNodeId (nodeId);
            if (nodeError != null) {
                return Result.error<bool, GLib.Error> (nodeError);
            }
            return Result.ok<bool, GLib.Error> (_nodes.contains (nodeId));
        }

        /**
         * Returns assigned node for key.
         *
         * @param key lookup key.
         * @return Result.ok(assigned node or null when ring is empty), or
         *         Result.error(ConsistentHashError.INVALID_ARGUMENT) when key is empty.
         */
        public Result<string ?, GLib.Error> getNode (string key) {
            GLib.Error ? keyError = validateKey (key);
            if (keyError != null) {
                return Result.error<string ?, GLib.Error> (keyError);
            }
            return Result.ok<string ?, GLib.Error> (locateNodeInRing (_ring, key));
        }

        /**
         * Returns up to count distinct nodes for replicas.
         *
         * @param key lookup key.
         * @param count max number of nodes to return.
         * @return Result.ok(list of distinct nodes), or
         *         Result.error(ConsistentHashError.INVALID_ARGUMENT) when key is empty or count is not positive.
         */
        public Result<ArrayList<string>, GLib.Error> getNodes (string key,
                                                               int count) {
            GLib.Error ? keyError = validateKey (key);
            if (keyError != null) {
                return Result.error<ArrayList<string>, GLib.Error> (keyError);
            }
            if (count <= 0) {
                return Result.error<ArrayList<string>, GLib.Error> (
                    new ConsistentHashError.INVALID_ARGUMENT ("count must be positive")
                );
            }

            var result = new ArrayList<string> ();
            if (_ring.size () == 0) {
                return Result.ok<ArrayList<string>, GLib.Error> (result);
            }

            var seen = new HashSet<string> (GLib.str_hash, GLib.str_equal);
            uint target = hashOf (key);
            int start = findIndex (_ring, target);
            int limit = (int) _ring.size ();
            int maxNodes = count < nodeCount () ? count : nodeCount ();

            for (int i = 0; i < limit && result.size () < maxNodes; i++) {
                int index = (start + i) % limit;
                ConsistentHashEntry ? entry = _ring.get (index);
                if (entry == null) {
                    continue;
                }

                if (!seen.contains (entry.nodeId)) {
                    seen.add (entry.nodeId);
                    result.add (entry.nodeId);
                }
            }

            return Result.ok<ArrayList<string>, GLib.Error> (result);
        }

        /**
         * Returns physical node count.
         *
         * @return physical node count.
         */
        public int nodeCount () {
            return (int) _nodes.size ();
        }

        /**
         * Returns total virtual node count.
         *
         * @return virtual node count.
         */
        public int virtualNodeCount () {
            return (int) _ring.size ();
        }

        /**
         * Estimates remapping ratio when one node is added.
         *
         * This method simulates adding a new node and measures how many
         * sample keys would move to different nodes.
         *
         * @param sampleKeys sample keys for estimation.
         * @return moved ratio in range [0, 1].
         */
        public double rebalanceEstimate (ArrayList<string> sampleKeys) {
            if (sampleKeys.size () == 0 || _nodes.size () == 0) {
                return 0.0;
            }

            string probeNode = "__rebalance_probe__";
            int n = 0;
            while (_nodes.contains (probeNode)) {
                n++;
                probeNode = "__rebalance_probe_%d__".printf (n);
            }

            ArrayList<ConsistentHashEntry> simulated = buildRingWithExtraNode (probeNode);
            int moved = 0;
            int total = 0;

            for (int i = 0; i < sampleKeys.size (); i++) {
                string ? key = sampleKeys.get (i);
                if (key == null || key.length == 0) {
                    continue;
                }

                string ? before = locateNodeInRing (_ring, key);
                string ? after = locateNodeInRing (simulated, key);
                if (before == null || after == null) {
                    continue;
                }

                total++;
                if (before != after) {
                    moved++;
                }
            }

            if (total == 0) {
                return 0.0;
            }
            return (double) moved / (double) total;
        }

        /**
         * Returns key distribution across nodes for samples.
         *
         * @param sampleKeys sample keys.
         * @return map of node -> assigned key count.
         */
        public HashMap<string, int> distribution (ArrayList<string> sampleKeys) {
            var result = new HashMap<string, int> (GLib.str_hash, GLib.str_equal);

            _nodes.forEach ((node) => {
                result.put (node, 0);
            });

            for (int i = 0; i < sampleKeys.size (); i++) {
                string ? key = sampleKeys.get (i);
                if (key == null || key.length == 0) {
                    continue;
                }

                string ? node = locateNodeInRing (_ring, key);
                if (node == null) {
                    continue;
                }
                int current = result.getOrDefault (node, 0);
                result.put (node, current + 1);
            }

            return result;
        }

        /**
         * Clears all nodes and virtual ring state.
         */
        public void clear () {
            _nodes.clear ();
            _ring.clear ();
        }

        private void rebuildRing () {
            _ring.clear ();

            _nodes.forEach ((node) => {
                addVirtualEntries (_ring, node);
            });
            sortRing (_ring);
        }

        private ArrayList<ConsistentHashEntry> buildRingWithExtraNode (string nodeId) {
            var ring = new ArrayList<ConsistentHashEntry> ();

            for (int i = 0; i < _ring.size (); i++) {
                ConsistentHashEntry ? entry = _ring.get (i);
                if (entry != null) {
                    ring.add (new ConsistentHashEntry (entry.hashValue, entry.nodeId));
                }
            }
            addVirtualEntries (ring, nodeId);
            sortRing (ring);
            return ring;
        }

        private void addVirtualEntries (ArrayList<ConsistentHashEntry> targetRing, string nodeId) {
            for (int i = 0; i < _replicas; i++) {
                string virtualNode = "%s#%d".printf (nodeId, i);
                targetRing.add (new ConsistentHashEntry (hashOf (virtualNode), nodeId));
            }
        }

        private void sortRing (ArrayList<ConsistentHashEntry> targetRing) {
            targetRing.sort ((a, b) => {
                if (a.hashValue < b.hashValue) {
                    return -1;
                }
                if (a.hashValue > b.hashValue) {
                    return 1;
                }
                return GLib.strcmp (a.nodeId, b.nodeId);
            });
        }

        private string ? locateNodeInRing (ArrayList<ConsistentHashEntry> ring, string key) {
            if (ring.size () == 0) {
                return null;
            }

            uint target = hashOf (key);
            int index = findIndex (ring, target);
            ConsistentHashEntry ? entry = ring.get (index);
            return entry == null ? null : entry.nodeId;
        }

        private int findIndex (ArrayList<ConsistentHashEntry> ring, uint target) {
            for (int i = 0; i < ring.size (); i++) {
                ConsistentHashEntry ? entry = ring.get (i);
                if (entry != null && entry.hashValue >= target) {
                    return i;
                }
            }
            return 0;
        }

        private static uint hashOf (string value) {
            return GLib.str_hash (value);
        }

        private static GLib.Error ? validateNodeId (string nodeId) {
            if (nodeId.length == 0) {
                return new ConsistentHashError.INVALID_ARGUMENT ("nodeId must not be empty");
            }
            return null;
        }

        private static GLib.Error ? validateKey (string key) {
            if (key.length == 0) {
                return new ConsistentHashError.INVALID_ARGUMENT ("key must not be empty");
            }
            return null;
        }
    }
}
