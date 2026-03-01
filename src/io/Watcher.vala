using Vala.Collections;
using Vala.Time;

namespace Vala.Io {
    /**
     * Watch callback type.
     */
    public delegate void WatchCallback (WatchEvent eventData);

    /**
     * Rename callback type.
     */
    public delegate void RenameCallback (WatchEvent from, WatchEvent to);

    /**
     * Filesystem watch event type.
     */
    public enum WatchEventType {
        CREATED,
        MODIFIED,
        DELETED,
        RENAMED
    }

    /**
     * Value object that represents one filesystem event.
     */
    public class WatchEvent : GLib.Object {
        /**
         * Changed path.
         */
        public Path path {
            get;
            private set;
        }

        /**
         * Event type.
         */
        public WatchEventType eventType {
            get;
            private set;
        }

        /**
         * UNIX timestamp in milliseconds.
         */
        public int64 timestamp {
            get;
            private set;
        }

        internal WatchEvent (Path path, WatchEventType eventType, int64 timestamp) {
            this.path = path;
            this.eventType = eventType;
            this.timestamp = timestamp;
        }
    }

    /**
     * Active filesystem watcher with callback registration.
     */
    public class FileWatcher : GLib.Object {
        private ArrayList<GLib.FileMonitor> _monitors;
        private HashMap<string, bool> _watched_dirs;
        private HashMap<string, int64 ?> _last_dispatch;
        private bool _closed;
        private bool _recursive;
        private string ? _glob;
        private int64 _debounce_millis;
        private Path ? _pending_move_from;
        private int64 _pending_move_ts;
        private Path ? _pending_deleted_from;
        private int64 _pending_deleted_ts;

        private WatchCallback ? _created_callback;
        private WatchCallback ? _modified_callback;
        private WatchCallback ? _deleted_callback;
        private RenameCallback ? _renamed_callback;

        internal FileWatcher (Path root, bool recursive, string ? glob) {
            _monitors = new ArrayList<GLib.FileMonitor> ();
            _watched_dirs = new HashMap<string, bool> (GLib.str_hash, GLib.str_equal);
            _last_dispatch = new HashMap<string, int64 ?> (GLib.str_hash, GLib.str_equal);
            _closed = false;
            _recursive = recursive;
            _glob = glob;
            _debounce_millis = 100;
            _pending_move_from = null;
            _pending_move_ts = 0;
            _pending_deleted_from = null;
            _pending_deleted_ts = 0;

            if (!Files.exists (root)) {
                error ("watch path does not exist: %s", root.toString ());
            }

            if (recursive) {
                if (!Files.isDir (root)) {
                    error ("watchRecursive/watchGlob requires directory path");
                }
                attachDirectoryRecursive (root);
            } else {
                attachSinglePath (root);
            }
        }

        /**
         * Registers callback fired on create event.
         *
         * @param fn callback.
         * @return this watcher.
         */
        public FileWatcher onCreated (owned WatchCallback fn) {
            _created_callback = (owned) fn;
            return this;
        }

        /**
         * Registers callback fired on modify event.
         *
         * @param fn callback.
         * @return this watcher.
         */
        public FileWatcher onModified (owned WatchCallback fn) {
            _modified_callback = (owned) fn;
            return this;
        }

        /**
         * Registers callback fired on delete event.
         *
         * @param fn callback.
         * @return this watcher.
         */
        public FileWatcher onDeleted (owned WatchCallback fn) {
            _deleted_callback = (owned) fn;
            return this;
        }

        /**
         * Registers callback fired on rename event.
         *
         * @param fn callback.
         * @return this watcher.
         */
        public FileWatcher onRenamed (owned RenameCallback fn) {
            _renamed_callback = (owned) fn;
            return this;
        }

        /**
         * Updates debounce interval.
         *
         * @param interval debounce duration.
         * @return this watcher.
         */
        public FileWatcher debounce (Duration interval) {
            int64 ms = interval.toMillis ();
            if (ms < 0) {
                ms = 0;
            }
            _debounce_millis = ms;
            return this;
        }

        /**
         * Stops watching and releases resources.
         */
        public void close () {
            if (_closed) {
                return;
            }

            _closed = true;
            for (int i = 0; i < _monitors.size (); i++) {
                GLib.FileMonitor ? monitor = _monitors.get (i);
                if (monitor != null) {
                    monitor.cancel ();
                }
            }
            _monitors.clear ();
            _watched_dirs.clear ();
            _last_dispatch.clear ();
        }

        ~FileWatcher () {
            close ();
        }

        private void attachSinglePath (Path path) {
            if (Files.isDir (path)) {
                attachDirectoryMonitor (path);
                return;
            }

            var file = GLib.File.new_for_path (path.toString ());
            try {
                GLib.FileMonitor monitor = file.monitor_file (FileMonitorFlags.NONE);
                connectMonitor (monitor);
                _monitors.add (monitor);
            } catch (Error e) {
                warning ("failed to monitor file: %s", path.toString ());
            }
        }

        private void attachDirectoryRecursive (Path dir) {
            if (_watched_dirs.containsKey (dir.toString ())) {
                return;
            }

            attachDirectoryMonitor (dir);
            _watched_dirs.put (dir.toString (), true);

            GLib.List<string> ? entries = Files.listDir (dir);
            if (entries == null) {
                return;
            }

            foreach (string name in entries) {
                Path child = new Path (dir.toString () + "/" + name);
                if (Files.isDir (child) && !Files.isSymbolicFile (child)) {
                    attachDirectoryRecursive (child);
                }
            }
        }

        private void attachDirectoryMonitor (Path dir) {
            var file = GLib.File.new_for_path (dir.toString ());
            try {
                GLib.FileMonitor monitor = file.monitor_directory (FileMonitorFlags.NONE);
                connectMonitor (monitor);
                _monitors.add (monitor);
            } catch (Error e) {
                warning ("failed to monitor directory: %s", dir.toString ());
            }
        }

        private void connectMonitor (GLib.FileMonitor monitor) {
            monitor.changed.connect ((file, other, eventType) => {
                if (_closed) {
                    return;
                }

                string ? pathText = file.get_path ();
                if (pathText == null) {
                    return;
                }

                Path primaryPath = new Path (pathText);
                Path ? otherPath = null;
                if (other != null) {
                    string ? otherText = other.get_path ();
                    if (otherText != null) {
                        otherPath = new Path (otherText);
                    }
                }

                if (_recursive &&
                    (eventType == GLib.FileMonitorEvent.CREATED ||
                     eventType == GLib.FileMonitorEvent.MOVED_IN) &&
                    Files.isDir (primaryPath) &&
                    !Files.isSymbolicFile (primaryPath)) {
                    attachDirectoryRecursive (primaryPath);
                }

                switch (eventType) {
                        case GLib.FileMonitorEvent.CREATED :
                            dispatchSingleEvent (WatchEventType.CREATED, primaryPath);
                            break;
                        case GLib.FileMonitorEvent.MOVED_IN :
                            handleMovedIn (primaryPath);
                            break;
                        case GLib.FileMonitorEvent.DELETED :
                            dispatchSingleEvent (WatchEventType.DELETED, primaryPath);
                            break;
                        case GLib.FileMonitorEvent.MOVED_OUT :
                            handleMovedOut (primaryPath);
                            break;
                        case GLib.FileMonitorEvent.CHANGED :
                        case GLib.FileMonitorEvent.CHANGES_DONE_HINT :
                        case GLib.FileMonitorEvent.ATTRIBUTE_CHANGED :
                            dispatchSingleEvent (WatchEventType.MODIFIED, primaryPath);
                            break;
                        case GLib.FileMonitorEvent.RENAMED :
                        case GLib.FileMonitorEvent.MOVED :
                            dispatchRenameEvent (primaryPath, otherPath);
                            break;
                        default:
                            break;
                }
            });
        }

        private void handleMovedOut (Path path) {
            int64 now = currentTimeMillis ();
            if (_pending_move_from != null && now - _pending_move_ts > 1000) {
                dispatchSingleEvent (WatchEventType.DELETED, _pending_move_from);
            }
            _pending_move_from = path;
            _pending_move_ts = now;
        }

        private void handleMovedIn (Path path) {
            int64 now = currentTimeMillis ();
            if (_pending_move_from != null && now - _pending_move_ts <= 1000) {
                dispatchRenameEvent (_pending_move_from, path);
                _pending_move_from = null;
                _pending_move_ts = 0;
                return;
            }
            dispatchSingleEvent (WatchEventType.CREATED, path);
        }

        private void dispatchSingleEvent (WatchEventType type, Path path) {
            if (!matchesGlob (path)) {
                return;
            }

            int64 now = currentTimeMillis ();
            if (type == WatchEventType.CREATED &&
                _pending_deleted_from != null &&
                now - _pending_deleted_ts <= 500) {
                if (_pending_deleted_from.parent ().toString () == path.parent ().toString ()) {
                    dispatchRenameEvent (_pending_deleted_from, path);
                    _pending_deleted_from = null;
                    _pending_deleted_ts = 0;
                    return;
                }
            }

            string key = "%d:%s".printf ((int) type, path.toString ());
            if (isDebounced (key, now)) {
                return;
            }

            var eventData = new WatchEvent (path, type, now);
            switch (type) {
                case WatchEventType.CREATED:
                    if (_created_callback != null) {
                        _created_callback (eventData);
                    }
                    break;
                case WatchEventType.MODIFIED:
                    if (_modified_callback != null) {
                        _modified_callback (eventData);
                    }
                    break;
                case WatchEventType.DELETED:
                    _pending_deleted_from = path;
                    _pending_deleted_ts = now;
                    if (_deleted_callback != null) {
                        _deleted_callback (eventData);
                    }
                    break;
                default:
                    break;
            }
        }

        private void dispatchRenameEvent (Path from, Path ? to) {
            Path toPath = to;
            if (toPath == null) {
                return;
            }

            if (!matchesGlob (from) && !matchesGlob (toPath)) {
                return;
            }

            int64 now = currentTimeMillis ();
            string key = "rename:%s:%s".printf (from.toString (), toPath.toString ());
            if (isDebounced (key, now)) {
                return;
            }

            if (_renamed_callback != null) {
                var fromEvent = new WatchEvent (from, WatchEventType.RENAMED, now);
                var toEvent = new WatchEvent (toPath, WatchEventType.RENAMED, now);
                _renamed_callback (fromEvent, toEvent);
            }
        }

        private bool matchesGlob (Path path) {
            if (_glob == null) {
                return true;
            }
            return GLib.PatternSpec.match_simple (_glob, path.basename ());
        }

        private bool isDebounced (string key, int64 now) {
            if (_debounce_millis <= 0) {
                _last_dispatch.put (key, now);
                return false;
            }

            if (_last_dispatch.containsKey (key)) {
                int64 ? last = _last_dispatch.get (key);
                if (last != null) {
                    if (now - last < _debounce_millis) {
                        return true;
                    }
                }
            }

            _last_dispatch.put (key, now);
            return false;
        }

        private static int64 currentTimeMillis () {
            return GLib.get_real_time () / 1000;
        }
    }

    /**
     * Static factory for filesystem watchers.
     */
    public class Watcher : GLib.Object {
        /**
         * Starts watch for file or directory.
         *
         * @param path target path.
         * @return watcher instance.
         */
        public static FileWatcher watch (Path path) {
            return new FileWatcher (path, false, null);
        }

        /**
         * Starts recursive directory watch.
         *
         * @param root root directory.
         * @return watcher instance.
         */
        public static FileWatcher watchRecursive (Path root) {
            return new FileWatcher (root, true, null);
        }

        /**
         * Starts recursive directory watch with glob filter.
         *
         * @param root root directory.
         * @param glob glob filter.
         * @return watcher instance.
         */
        public static FileWatcher watchGlob (Path root, string glob) {
            return new FileWatcher (root, true, glob);
        }
    }
}
