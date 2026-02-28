using Vala.Collections;

namespace Vala.Distributed {
    internal class RendezvousScoreEntry : GLib.Object {
        public string nodeId { get; private set; }
        public double score { get; private set; }

        public RendezvousScoreEntry (string nodeId, double score) {
            this.nodeId = nodeId;
            this.score = score;
        }
    }

    /**
     * Weighted rendezvous hash (highest-random-weight hashing).
     *
     * RendezvousHash assigns each key to the node with the highest score.
     * It also supports selecting top-N nodes for replication and per-node
     * weight for heterogeneous clusters.
     *
     * Example:
     * {{{
     *     var hash = new RendezvousHash ();
     *     hash.addNode ("node-a");
     *     hash.addNode ("node-b");
     *
     *     string? node = hash.getNode ("user:42");
     * }}}
     */
    public class RendezvousHash : GLib.Object {
        private HashSet<string> _nodes;
        private HashMap<string, double ?> _weights;

        /**
         * Creates empty rendezvous hash instance.
         */
        public RendezvousHash () {
            _nodes = new HashSet<string> (GLib.str_hash, GLib.str_equal);
            _weights = new HashMap<string, double ?> (GLib.str_hash, GLib.str_equal);
        }

        /**
         * Adds node to the hash set.
         *
         * @param nodeId node identifier.
         * @return true if node was newly added.
         */
        public bool addNode (string nodeId) {
            ensureNodeId (nodeId);

            bool added = _nodes.add (nodeId);
            if (added) {
                _weights.put (nodeId, 1.0);
            }
            return added;
        }

        /**
         * Removes node from the hash set.
         *
         * @param nodeId node identifier.
         * @return true if node existed.
         */
        public bool removeNode (string nodeId) {
            ensureNodeId (nodeId);

            bool removed = _nodes.remove (nodeId);
            if (removed) {
                _weights.remove (nodeId);
            }
            return removed;
        }

        /**
         * Returns whether node exists.
         *
         * @param nodeId node identifier.
         * @return true if node exists.
         */
        public bool containsNode (string nodeId) {
            ensureNodeId (nodeId);
            return _nodes.contains (nodeId);
        }

        /**
         * Returns assigned node for a key.
         *
         * @param key lookup key.
         * @return assigned node, or null when no nodes are registered.
         */
        public string ? getNode (string key) {
            ensureKey (key);
            return locateBestNode (key, null, 1.0);
        }

        /**
         * Returns top-N nodes for key by score.
         *
         * @param key lookup key.
         * @param n number of nodes to return.
         * @return sorted node list by descending score.
         */
        public ArrayList<string> getTopNodes (string key, int n) {
            ensureKey (key);
            if (n <= 0) {
                GLib.error ("n must be positive");
            }

            var scores = collectScores (key);
            sortScoreEntries (scores);

            var result = new ArrayList<string> ();
            int limit = int.min (n, (int) scores.size ());
            for (int i = 0; i < limit; i++) {
                RendezvousScoreEntry ? entry = scores.get (i);
                if (entry != null) {
                    result.add (entry.nodeId);
                }
            }

            return result;
        }

        /**
         * Sets weight for existing node.
         *
         * @param nodeId node identifier.
         * @param weight positive node weight.
         * @return true when weight is updated.
         */
        public bool setWeight (string nodeId, double weight) {
            ensureNodeId (nodeId);
            if (weight <= 0.0) {
                GLib.error ("weight must be positive");
            }
            if (!_nodes.contains (nodeId)) {
                return false;
            }

            _weights.put (nodeId, weight);
            return true;
        }

        /**
         * Returns current node count.
         *
         * @return number of registered nodes.
         */
        public int nodeCount () {
            return (int) _nodes.size ();
        }

        /**
         * Returns distribution of sample keys per node.
         *
         * @param sampleKeys sample keys.
         * @return map of nodeId to assigned key count.
         */
        public HashMap<string, int> distribution (ArrayList<string> sampleKeys) {
            var result = new HashMap<string, int> (GLib.str_hash, GLib.str_equal);
            _nodes.forEach ((nodeId) => {
                result.put (nodeId, 0);
            });

            for (int i = 0; i < sampleKeys.size (); i++) {
                string ? key = sampleKeys.get (i);
                if (key == null || key.length == 0) {
                    continue;
                }

                string ? node = getNode (key);
                if (node == null) {
                    continue;
                }
                int current = result.getOrDefault (node, 0);
                result.put (node, current + 1);
            }

            return result;
        }

        /**
         * Estimates key remap ratio when one node is added.
         *
         * @param sampleKeys sample keys.
         * @return remap ratio in range [0, 1].
         */
        public double rebalanceEstimate (ArrayList<string> sampleKeys) {
            if (sampleKeys.size () == 0 || _nodes.size () == 0) {
                return 0.0;
            }

            string probeNode = "__rebalance_probe__";
            int suffix = 0;
            while (_nodes.contains (probeNode)) {
                suffix++;
                probeNode = "__rebalance_probe_%d__".printf (suffix);
            }

            int moved = 0;
            int total = 0;
            for (int i = 0; i < sampleKeys.size (); i++) {
                string ? key = sampleKeys.get (i);
                if (key == null || key.length == 0) {
                    continue;
                }

                string ? before = getNode (key);
                string ? after = locateBestNode (key, probeNode, 1.0);
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
         * Removes all nodes and weights.
         */
        public void clear () {
            _nodes.clear ();
            _weights.clear ();
        }

        private string ? locateBestNode (string key,
                                         string ? extraNodeId,
                                         double extraWeight) {
            if (_nodes.size () == 0 && extraNodeId == null) {
                return null;
            }

            string ? bestNode = null;
            double bestScore = -1.0;

            _nodes.forEach ((nodeId) => {
                double score = scoreForNode (key, nodeId, _weights.getOrDefault (nodeId, 1.0));
                if (shouldReplaceBest (nodeId, score, bestNode, bestScore)) {
                    bestNode = nodeId;
                    bestScore = score;
                }
            });

            if (extraNodeId != null) {
                double extraScore = scoreForNode (key, extraNodeId, extraWeight);
                if (shouldReplaceBest (extraNodeId, extraScore, bestNode, bestScore)) {
                    bestNode = extraNodeId;
                }
            }

            return bestNode;
        }

        private ArrayList<RendezvousScoreEntry> collectScores (string key) {
            var result = new ArrayList<RendezvousScoreEntry> ();
            _nodes.forEach ((nodeId) => {
                result.add (new RendezvousScoreEntry (
                                nodeId,
                                scoreForNode (key, nodeId, _weights.getOrDefault (nodeId, 1.0))
                ));
            });
            return result;
        }

        private static void sortScoreEntries (ArrayList<RendezvousScoreEntry> entries) {
            entries.sort ((a, b) => {
                if (a.score > b.score) {
                    return -1;
                }
                if (a.score < b.score) {
                    return 1;
                }
                return GLib.strcmp (a.nodeId, b.nodeId);
            });
        }

        private static bool shouldReplaceBest (string candidateNode,
                                               double candidateScore,
                                               string ? currentBestNode,
                                               double currentBestScore) {
            if (currentBestNode == null) {
                return true;
            }
            if (candidateScore > currentBestScore) {
                return true;
            }
            if (candidateScore < currentBestScore) {
                return false;
            }
            return GLib.strcmp (candidateNode, currentBestNode) < 0;
        }

        private static double scoreForNode (string key, string nodeId, double weight) {
            uint64 hash = fnv1a64 ("%s|%s".printf (key, nodeId));
            uint64 mantissa = (hash >> 11) & 0x1fffffffffffffUL;
            double u = ((double) mantissa + 1.0) / 9007199254740993.0;
            return weight / (-GLib.Math.log (u));
        }

        private static uint64 fnv1a64 (string value) {
            uint64 hash = 14695981039346656037UL;
            for (int i = 0; i < value.length; i++) {
                hash ^= (uint8) value[i];
                hash *= 1099511628211UL;
            }
            return hash;
        }

        private static void ensureNodeId (string nodeId) {
            if (nodeId.length == 0) {
                GLib.error ("nodeId must not be empty");
            }
        }

        private static void ensureKey (string key) {
            if (key.length == 0) {
                GLib.error ("key must not be empty");
            }
        }
    }
}
