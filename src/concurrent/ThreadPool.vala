namespace Vala.Concurrent {
    /**
     * Recoverable worker pool configuration errors.
     */
    public errordomain WorkerPoolError {
        INVALID_ARGUMENT
    }

    /**
     * Function delegate that returns a value of type T.
     */
    public delegate T TaskFunc<T> ();

    /**
     * Function delegate that takes no arguments and returns nothing.
     */
    public delegate void VoidTaskFunc ();

    /**
     * Fixed-size worker pool for executing tasks concurrently.
     *
     * WorkerPool manages a pool of worker threads and a task queue.
     * Tasks submitted via {@link submitInt}, {@link submitString},
     * {@link execute} etc. are queued and processed by the next
     * available worker thread.
     *
     * Example:
     * {{{
     *     var pool = WorkerPool.withDefault ();
     *     pool.execute (() => {
     *         // background work
     *     });
     *     pool.shutdown ();
     * }}}
     *
     * Example with return value:
     * {{{
     *     var pool = new WorkerPool (4);
     *     int result = pool.submitInt (() => { return 42; }).await ();
     *     pool.shutdown ();
     * }}}
     */
    public class WorkerPool : GLib.Object {
        private int _poolSize;
        private GLib.AsyncQueue<TaskWrapper> _queue;
        private GLib.Thread<void *>[] _workers;
        private bool _shutdown;
        private GLib.Mutex _mutex;
        private int _activeCount;

        /**
         * Creates a thread pool with the specified number of worker threads.
         *
         * Example:
         * {{{
         *     var pool = new WorkerPool (4);
         * }}}
         *
         * @param poolSize the number of worker threads (must be > 0).
         * @throws WorkerPoolError.INVALID_ARGUMENT when poolSize is not positive.
         */
        public WorkerPool (int poolSize) throws WorkerPoolError {
            if (poolSize <= 0) {
                throw new WorkerPoolError.INVALID_ARGUMENT (
                          "poolSize must be positive, got %d".printf (poolSize)
                );
            }
            initializePool (poolSize);
        }

        private WorkerPool.unchecked (int poolSize) {
            initializePool (poolSize);
        }

        private void initializePool (int poolSize) {
            _poolSize = poolSize;
            _queue = new GLib.AsyncQueue<TaskWrapper> ();
            _shutdown = false;
            _activeCount = 0;

            _workers = new GLib.Thread<void *>[_poolSize];
            for (int i = 0; i < _poolSize; i++) {
                int id = i;
                _workers[i] = new GLib.Thread<void *> ("pool-worker-%d".printf (id), () => {
                    workerLoop ();
                    return null;
                });
            }
        }

        /**
         * Creates a thread pool with pool size equal to the number of CPU cores.
         *
         * Example:
         * {{{
         *     var pool = WorkerPool.withDefault ();
         * }}}
         *
         * @return a new WorkerPool sized to CPU core count.
         */
        public static WorkerPool withDefault () {
            int cpus = (int) GLib.get_num_processors ();
            if (cpus < 1) {
                cpus = 1;
            }
            return new WorkerPool.unchecked (cpus);
        }

        /**
         * Submits a task that returns an int and returns a PromiseInt
         * representing the pending result.
         *
         * Example:
         * {{{
         *     var pool = new WorkerPool (2);
         *     var promise = pool.submitInt (() => { return 42; });
         *     int result = promise.await ();
         *     pool.shutdown ();
         * }}}
         *
         * @param task the task to execute.
         * @return a PromiseInt for the pending result.
         */
        public PromiseInt submitInt (owned TaskFunc<int> task) {
            var promise = new PromiseInt ();
            var wrapper = new TaskWrapper ();
            var captured = (owned) task;
            wrapper.run = () => {
                int val = captured ();
                promise.complete (val);
            };
            if (!enqueue (wrapper)) {
                promise.complete (0);
            }
            return promise;
        }

        /**
         * Submits a task that returns a string and returns a PromiseString
         * representing the pending result.
         *
         * Example:
         * {{{
         *     var pool = new WorkerPool (2);
         *     var promise = pool.submitString (() => { return "hello"; });
         *     string result = promise.await ();
         *     pool.shutdown ();
         * }}}
         *
         * @param task the task to execute.
         * @return a PromiseString for the pending result.
         */
        public PromiseString submitString (owned TaskFunc<string> task) {
            var promise = new PromiseString ();
            var wrapper = new TaskWrapper ();
            var captured = (owned) task;
            wrapper.run = () => {
                string val = captured ();
                promise.complete (val);
            };
            if (!enqueue (wrapper)) {
                promise.complete ("");
            }
            return promise;
        }

        /**
         * Submits a task that returns a bool and returns a PromiseBool
         * representing the pending result.
         *
         * Example:
         * {{{
         *     var pool = new WorkerPool (2);
         *     var promise = pool.submitBool (() => { return true; });
         *     bool result = promise.await ();
         *     pool.shutdown ();
         * }}}
         *
         * @param task the task to execute.
         * @return a PromiseBool for the pending result.
         */
        public PromiseBool submitBool (owned TaskFunc<bool> task) {
            var promise = new PromiseBool ();
            var wrapper = new TaskWrapper ();
            var captured = (owned) task;
            wrapper.run = () => {
                bool val = captured ();
                promise.complete (val);
            };
            if (!enqueue (wrapper)) {
                promise.complete (false);
            }
            return promise;
        }

        /**
         * Submits a task that returns a double and returns a PromiseDouble
         * representing the pending result.
         *
         * Example:
         * {{{
         *     var pool = new WorkerPool (2);
         *     var promise = pool.submitDouble (() => { return 3.14; });
         *     double result = promise.await ();
         *     pool.shutdown ();
         * }}}
         *
         * @param task the task to execute.
         * @return a PromiseDouble for the pending result.
         */
        public PromiseDouble submitDouble (owned TaskFunc<double ?> task) {
            var promise = new PromiseDouble ();
            var wrapper = new TaskWrapper ();
            var captured = (owned) task;
            wrapper.run = () => {
                double ? val = captured ();
                promise.complete (val != null ? val : 0.0);
            };
            if (!enqueue (wrapper)) {
                promise.complete (0.0);
            }
            return promise;
        }

        /**
         * Executes a void task in the thread pool.
         *
         * Example:
         * {{{
         *     var pool = WorkerPool.withDefault ();
         *     pool.execute (() => {
         *         print ("running in background\n");
         *     });
         * }}}
         *
         * @param task the task to execute.
         */
        public void execute (owned VoidTaskFunc task) {
            var wrapper = new TaskWrapper ();
            var captured = (owned) task;
            wrapper.run = () => {
                captured ();
            };
            enqueue (wrapper);
        }

        /**
         * Signals shutdown and waits for all queued tasks to complete.
         * No new tasks can be submitted after calling this method.
         *
         * Example:
         * {{{
         *     pool.shutdown ();
         * }}}
         */
        public void shutdown () {
            _mutex.lock ();
            if (_shutdown) {
                _mutex.unlock ();
                return;
            }
            _shutdown = true;
            for (int i = 0; i < _poolSize; i++) {
                var poison = new TaskWrapper ();
                poison.poison = true;
                _queue.push (poison);
            }
            _mutex.unlock ();

            unowned GLib.Thread<void *> self = GLib.Thread.self<void *> ();
            for (int i = 0; i < _poolSize; i++) {
                if (_workers[i] == self) {
                    continue;
                }
                _workers[i].join ();
            }
        }

        /**
         * Returns whether the pool has been shut down.
         *
         * @return true if shutdown has been called.
         */
        public bool isShutdown () {
            _mutex.lock ();
            bool s = _shutdown;
            _mutex.unlock ();
            return s;
        }

        /**
         * Returns the number of currently active (executing) tasks.
         *
         * @return active task count.
         */
        public int activeCount () {
            _mutex.lock ();
            int c = _activeCount;
            _mutex.unlock ();
            return c;
        }

        /**
         * Returns the number of worker threads in this pool.
         *
         * @return the pool size.
         */
        public int poolSize () {
            return _poolSize;
        }

        /**
         * Returns the number of tasks waiting in the queue.
         *
         * @return pending queue size.
         */
        public int queueSize () {
            return _queue.length ();
        }

        private bool enqueue (TaskWrapper wrapper) {
            _mutex.lock ();
            if (_shutdown) {
                _mutex.unlock ();
                warning ("WorkerPool is shut down, task rejected");
                return false;
            }
            _queue.push (wrapper);
            _mutex.unlock ();
            return true;
        }

        private void workerLoop () {
            while (true) {
                TaskWrapper task = _queue.pop ();
                if (task.poison) {
                    break;
                }

                if (task.run == null) {
                    continue;
                }

                _mutex.lock ();
                _activeCount++;
                _mutex.unlock ();

                task.run ();

                _mutex.lock ();
                _activeCount--;
                _mutex.unlock ();
            }
        }
    }

    /**
     * Internal task wrapper used by WorkerPool.
     */
    public class TaskWrapper : GLib.Object {
        /** The task function to execute. */
        public VoidTaskFunc ? run;
        /** Whether this is a poison pill to stop a worker. */
        public bool poison = false;
    }

    /**
     * Promise for an int result from an asynchronous computation.
     *
     * Example:
     * {{{
     *     var promise = pool.submitInt (() => { return 42; });
     *     int result = promise.await ();
     * }}}
     */
    public class PromiseInt : GLib.Object {
        private GLib.Mutex _mutex;
        private GLib.Cond _cond;
        private int _value;
        private bool _done;

        internal PromiseInt () {
            _done = false;
            _value = 0;
        }

        /**
         * Sets the result value and notifies waiters.
         *
         * @param value the result.
         */
        internal void complete (int value) {
            _mutex.lock ();
            _value = value;
            _done = true;
            _cond.broadcast ();
            _mutex.unlock ();
        }

        /**
         * Blocks until the result is available and returns it.
         *
         * @return the computed int value.
         */
        public int await () {
            _mutex.lock ();
            while (!_done) {
                _cond.wait (_mutex);
            }
            int v = _value;
            _mutex.unlock ();
            return v;
        }

        /**
         * Returns whether the computation is complete.
         *
         * @return true if complete.
         */
        public bool isDone () {
            _mutex.lock ();
            bool d = _done;
            _mutex.unlock ();
            return d;
        }
    }

    /**
     * Promise for a string result from an asynchronous computation.
     *
     * Example:
     * {{{
     *     var promise = pool.submitString (() => { return "hello"; });
     *     string result = promise.await ();
     * }}}
     */
    public class PromiseString : GLib.Object {
        private GLib.Mutex _mutex;
        private GLib.Cond _cond;
        private string _value;
        private bool _done;

        internal PromiseString () {
            _done = false;
            _value = "";
        }

        /**
         * Sets the result value and notifies waiters.
         *
         * @param value the result.
         */
        internal void complete (string value) {
            _mutex.lock ();
            _value = value;
            _done = true;
            _cond.broadcast ();
            _mutex.unlock ();
        }

        /**
         * Blocks until the result is available and returns it.
         *
         * @return the computed string value.
         */
        public string await () {
            _mutex.lock ();
            while (!_done) {
                _cond.wait (_mutex);
            }
            string v = _value;
            _mutex.unlock ();
            return v;
        }

        /**
         * Returns whether the computation is complete.
         *
         * @return true if complete.
         */
        public bool isDone () {
            _mutex.lock ();
            bool d = _done;
            _mutex.unlock ();
            return d;
        }
    }

    /**
     * Promise for a bool result from an asynchronous computation.
     *
     * Example:
     * {{{
     *     var promise = pool.submitBool (() => { return true; });
     *     bool result = promise.await ();
     * }}}
     */
    public class PromiseBool : GLib.Object {
        private GLib.Mutex _mutex;
        private GLib.Cond _cond;
        private bool _value;
        private bool _done;

        internal PromiseBool () {
            _done = false;
            _value = false;
        }

        /**
         * Sets the result value and notifies waiters.
         *
         * @param value the result.
         */
        internal void complete (bool value) {
            _mutex.lock ();
            _value = value;
            _done = true;
            _cond.broadcast ();
            _mutex.unlock ();
        }

        /**
         * Blocks until the result is available and returns it.
         *
         * @return the computed bool value.
         */
        public bool await () {
            _mutex.lock ();
            while (!_done) {
                _cond.wait (_mutex);
            }
            bool v = _value;
            _mutex.unlock ();
            return v;
        }

        /**
         * Returns whether the computation is complete.
         *
         * @return true if complete.
         */
        public bool isDone () {
            _mutex.lock ();
            bool d = _done;
            _mutex.unlock ();
            return d;
        }
    }

    /**
     * Promise for a double result from an asynchronous computation.
     *
     * Example:
     * {{{
     *     var promise = pool.submitDouble (() => { return 3.14; });
     *     double result = promise.await ();
     * }}}
     */
    public class PromiseDouble : GLib.Object {
        private GLib.Mutex _mutex;
        private GLib.Cond _cond;
        private double _value;
        private bool _done;

        internal PromiseDouble () {
            _done = false;
            _value = 0.0;
        }

        /**
         * Sets the result value and notifies waiters.
         *
         * @param value the result.
         */
        internal void complete (double value) {
            _mutex.lock ();
            _value = value;
            _done = true;
            _cond.broadcast ();
            _mutex.unlock ();
        }

        /**
         * Blocks until the result is available and returns it.
         *
         * @return the computed double value.
         */
        public double await () {
            _mutex.lock ();
            while (!_done) {
                _cond.wait (_mutex);
            }
            double v = _value;
            _mutex.unlock ();
            return v;
        }

        /**
         * Returns whether the computation is complete.
         *
         * @return true if complete.
         */
        public bool isDone () {
            _mutex.lock ();
            bool d = _done;
            _mutex.unlock ();
            return d;
        }
    }
}
