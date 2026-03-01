using Vala.Collections;
using Vala.Time;

namespace Vala.Concurrent {
    /**
     * Wrapper for queued task function used by invokeAll.
     */
    public class ThreadPoolTaskFunc<T>: GLib.Object {
        private TaskFunc<T> _task;

        /**
         * Creates task wrapper.
         *
         * @param task wrapped function.
         */
        public ThreadPoolTaskFunc (owned TaskFunc<T> task) {
            _task = (owned) task;
        }

        /**
         * Executes wrapped task.
         *
         * @return task result.
         */
        public T run () {
            return _task ();
        }
    }

    internal class ThreadPoolTask : GLib.Object {
        public VoidTaskFunc ? run;
        public bool poison;

        public ThreadPoolTask () {
            poison = false;
            run = null;
        }
    }

    /**
     * Generic fixed-size thread pool for asynchronous task execution.
     *
     * ThreadPool executes submitted tasks on worker threads and returns
     * {@link Future} values for result-oriented workflows.
     */
    public class ThreadPool : GLib.Object {
        private int _pool_size;
        private GLib.AsyncQueue<ThreadPoolTask> _queue;
        private GLib.Thread<void *>[] _workers;

        private GLib.Mutex _mutex;
        private GLib.Cond _terminated_cond;

        private bool _shutdown;
        private bool _shutdown_now;
        private int _active_count;
        private int _alive_workers;

        private static ThreadPool ? _global_pool = null;
        private static GLib.Mutex _global_mutex;

        /**
         * Creates a fixed-size thread pool.
         *
         * @param poolSize number of worker threads (must be > 0).
         */
        public ThreadPool (int poolSize) {
            if (poolSize <= 0) {
                error ("poolSize must be positive, got %d", poolSize);
            }

            _pool_size = poolSize;
            _queue = new GLib.AsyncQueue<ThreadPoolTask> ();
            _shutdown = false;
            _shutdown_now = false;
            _active_count = 0;
            _alive_workers = _pool_size;

            _workers = new GLib.Thread<void *>[_pool_size];
            for (int i = 0; i < _pool_size; i++) {
                int id = i;
                _workers[i] = new GLib.Thread<void *> ("thread-pool-worker-%d".printf (id), () => {
                    workerLoop ();
                    return null;
                });
            }
        }

        /**
         * Creates a thread pool sized to current CPU core count.
         *
         * @return default thread pool.
         */
        public static ThreadPool withDefault () {
            int cpus = (int) GLib.get_num_processors ();
            if (cpus < 1) {
                cpus = 1;
            }
            return new ThreadPool (cpus);
        }

        /**
         * Submits a task and returns a future for its result.
         *
         * @param task task to execute.
         * @return pending future.
         */
        public Future<T> submit<T> (owned TaskFunc<T> task) {
            var future = Future<T>.pending<T> ();

            var captured = (owned) task;

            var wrapper = new ThreadPoolTask ();
            wrapper.run = () => {
                if (future.isCancelled ()) {
                    return;
                }

                T value = captured ();
                future.completeSuccess ((owned) value);
            };

            if (!enqueue (wrapper)) {
                future.completeFailure ("thread pool is shut down");
            }
            return future;
        }

        /**
         * Submits a task without return value.
         *
         * @param task task to execute.
         */
        public void execute (owned VoidTaskFunc task) {
            var captured = (owned) task;
            var wrapper = new ThreadPoolTask ();
            wrapper.run = () => {
                captured ();
            };
            enqueue (wrapper);
        }

        /**
         * Submits all tasks and returns futures in the same order.
         *
         * @param tasks wrapped tasks to submit.
         * @return list of pending futures.
         */
        public ArrayList<Future<T> > invokeAll<T> (ArrayList<ThreadPoolTaskFunc<T> > tasks) {
            var futures = new ArrayList<Future<T> > ();
            for (int i = 0; i < tasks.size (); i++) {
                ThreadPoolTaskFunc<T> ? task = tasks.get (i);
                if (task == null) {
                    futures.add (Future<T>.failed<T> ("null task at index %d".printf (i)));
                    continue;
                }

                futures.add (submit<T> (() => {
                    return task.run ();
                }));
            }
            return futures;
        }

        /**
         * Shuts down the pool after queued tasks are processed.
         */
        public void shutdown () {
            _mutex.lock ();
            if (_shutdown) {
                _mutex.unlock ();
                return;
            }

            _shutdown = true;
            for (int i = 0; i < _pool_size; i++) {
                var poison = new ThreadPoolTask ();
                poison.poison = true;
                _queue.push (poison);
            }
            _mutex.unlock ();

            joinWorkersSafely ();
        }

        /**
         * Requests immediate shutdown.
         *
         * Queued but not yet running tasks are discarded.
         */
        public void shutdownNow () {
            _mutex.lock ();
            if (_shutdown_now) {
                _mutex.unlock ();
                return;
            }

            _shutdown = true;
            _shutdown_now = true;

            while (_queue.try_pop () != null) {
                // drop queued tasks for immediate stop.
            }

            for (int i = 0; i < _pool_size; i++) {
                var poison = new ThreadPoolTask ();
                poison.poison = true;
                _queue.push (poison);
            }
            _mutex.unlock ();

            joinWorkersSafely ();
        }

        /**
         * Waits for worker termination up to timeout.
         *
         * @param timeout maximum wait duration.
         * @return true when all workers terminated within timeout.
         */
        public bool awaitTermination (Duration timeout) {
            int64 timeout_millis = timeout.toMillis ();
            if (timeout_millis < 0) {
                error ("timeout must be non-negative");
            }

            int64 deadline = GLib.get_monotonic_time () + timeout_millis * 1000;

            _mutex.lock ();
            while (_alive_workers > 0) {
                if (!_terminated_cond.wait_until (_mutex, deadline)) {
                    _mutex.unlock ();
                    return false;
                }
            }
            _mutex.unlock ();
            return true;
        }

        /**
         * Returns whether shutdown has been requested.
         *
         * @return true when shutdown or shutdownNow was called.
         */
        public bool isShutdown () {
            _mutex.lock ();
            bool is_shutdown = _shutdown;
            _mutex.unlock ();
            return is_shutdown;
        }

        /**
         * Returns currently executing task count.
         *
         * @return active task count.
         */
        public int activeCount () {
            _mutex.lock ();
            int count = _active_count;
            _mutex.unlock ();
            return count;
        }

        /**
         * Returns queued task count.
         *
         * @return queue size.
         */
        public int queueSize () {
            return _queue.length ();
        }

        /**
         * Returns process-wide shared thread pool.
         *
         * @return global thread pool.
         */
        public static ThreadPool global () {
            _global_mutex.lock ();
            if (_global_pool == null || _global_pool.isShutdown ()) {
                _global_pool = ThreadPool.withDefault ();
            }
            ThreadPool pool = _global_pool;
            _global_mutex.unlock ();
            return pool;
        }

        /**
         * Executes a fire-and-forget task on the global pool.
         *
         * @param task task to execute.
         */
        public static void go (owned VoidTaskFunc task) {
            global ().execute ((owned) task);
        }

        private bool enqueue (ThreadPoolTask task) {
            _mutex.lock ();
            if (_shutdown) {
                _mutex.unlock ();
                return false;
            }
            _queue.push (task);
            _mutex.unlock ();
            return true;
        }

        private void workerLoop () {
            while (true) {
                ThreadPoolTask task = _queue.pop ();
                if (task.poison) {
                    break;
                }

                if (task.run == null) {
                    continue;
                }

                _mutex.lock ();
                _active_count++;
                _mutex.unlock ();

                task.run ();

                _mutex.lock ();
                _active_count--;
                _mutex.unlock ();
            }

            _mutex.lock ();
            _alive_workers--;
            if (_alive_workers == 0) {
                _terminated_cond.broadcast ();
            }
            _mutex.unlock ();
        }

        private void joinWorkersSafely () {
            unowned GLib.Thread<void *> self = GLib.Thread.self<void *> ();
            for (int i = 0; i < _pool_size; i++) {
                if (_workers[i] == self) {
                    continue;
                }
                _workers[i].join ();
            }
        }
    }
}
