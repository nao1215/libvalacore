namespace Vala.Concurrent {
    /**
     * Thread-safe message-passing channel inspired by Go channels.
     *
     * ChannelInt provides a typed, thread-safe communication mechanism
     * between threads. It supports both unbuffered (synchronous) and
     * buffered (asynchronous up to capacity) modes.
     *
     * In unbuffered mode (default), send blocks until a receiver calls
     * receive, providing strict rendezvous semantics. Only one sender
     * can be in flight at a time.
     *
     * Example (unbuffered):
     * {{{
     *     var ch = new ChannelInt ();
     *     new Thread<void *> ("sender", () => {
     *         ch.send (42);
     *         return null;
     *     });
     *     int val = ch.receive ();
     * }}}
     *
     * Example (buffered):
     * {{{
     *     var ch = ChannelInt.buffered (10);
     *     ch.send (1);
     *     ch.send (2);
     *     int v1 = ch.receive ();
     *     int v2 = ch.receive ();
     * }}}
     */
    public class ChannelInt : GLib.Object {
        private GLib.AsyncQueue<IntBox> _queue;
        private int _capacity;
        private bool _closed;
        private GLib.Mutex _mutex;
        private GLib.Cond _notFull;
        private GLib.Cond _delivered;
        private int _size;

        /**
         * Creates an unbuffered channel.
         * Send blocks until a receiver is ready (rendezvous).
         */
        public ChannelInt () {
            _capacity = 0;
            _closed = false;
            _size = 0;
            _queue = new GLib.AsyncQueue<IntBox> ();
        }

        /**
         * Creates a buffered channel with the given capacity.
         *
         * @param capacity buffer size (must be > 0).
         * @return a new buffered ChannelInt.
         */
        public static ChannelInt buffered (int capacity) {
            if (capacity <= 0) {
                error ("capacity must be positive, got %d", capacity);
            }
            var ch = new ChannelInt ();
            ch._capacity = capacity;
            return ch;
        }

        /**
         * Sends a value into the channel.
         * For buffered channels, blocks if the buffer is full.
         * For unbuffered channels, blocks until a receiver calls receive
         * (strict rendezvous: only one sender in flight at a time).
         * Logs a warning and returns if the channel is closed.
         *
         * @param value the value to send.
         */
        public void send (int value) {
            _mutex.lock ();
            if (_closed) {
                _mutex.unlock ();
                warning ("send on closed channel");
                return;
            }

            if (_capacity > 0) {
                while (_size >= _capacity && !_closed) {
                    _notFull.wait (_mutex);
                }
                if (_closed) {
                    _mutex.unlock ();
                    warning ("send on closed channel");
                    return;
                }
                _queue.push (new IntBox (value));
                _size++;
                _mutex.unlock ();
            } else {
                while (_size > 0 && !_closed) {
                    _delivered.wait (_mutex);
                }
                if (_closed) {
                    _mutex.unlock ();
                    warning ("send on closed channel");
                    return;
                }
                _queue.push (new IntBox (value));
                _size++;
                while (_size > 0 && !_closed) {
                    _delivered.wait (_mutex);
                }
                _mutex.unlock ();
            }
        }

        /**
         * Tries to send a value without blocking.
         *
         * @param value the value to send.
         * @return true if the value was sent.
         */
        public bool trySend (int value) {
            _mutex.lock ();
            if (_closed) {
                _mutex.unlock ();
                return false;
            }

            if (_capacity > 0 && _size >= _capacity) {
                _mutex.unlock ();
                return false;
            }
            if (_capacity == 0 && _size > 0) {
                _mutex.unlock ();
                return false;
            }

            _queue.push (new IntBox (value));
            _size++;
            _mutex.unlock ();
            return true;
        }

        /**
         * Receives a value from the channel, blocking until one is available.
         * Returns the default value (0) if the channel is closed and empty.
         *
         * @return the received value or 0 if closed and empty.
         */
        public int receive () {
            IntBox ? box = _queue.pop ();
            if (box == null) {
                return 0;
            }
            if (box.sentinel) {
                _queue.push (box);
                return 0;
            }

            _mutex.lock ();
            _size--;
            if (_capacity > 0) {
                _notFull.signal ();
            } else {
                _delivered.broadcast ();
            }
            _mutex.unlock ();

            return box.value;
        }

        /**
         * Tries to receive a value without blocking.
         *
         * @return the value wrapped in IntBox, or null if nothing is available.
         */
        public IntBox ? tryReceive () {
            IntBox ? box = _queue.try_pop ();
            if (box == null) {
                return null;
            }
            if (box.sentinel) {
                _queue.push (box);
                return null;
            }

            _mutex.lock ();
            _size--;
            if (_capacity > 0) {
                _notFull.signal ();
            } else {
                _delivered.broadcast ();
            }
            _mutex.unlock ();

            return box;
        }

        /**
         * Closes the channel. No more values can be sent.
         * Pending receives will drain remaining values, then
         * return 0 for subsequent calls.
         */
        public void close () {
            _mutex.lock ();
            _closed = true;
            _notFull.broadcast ();
            _delivered.broadcast ();
            _mutex.unlock ();

            var sentinel = new IntBox (0);
            sentinel.sentinel = true;
            _queue.push (sentinel);
        }

        /**
         * Returns whether the channel is closed.
         *
         * @return true if closed.
         */
        public bool isClosed () {
            _mutex.lock ();
            bool c = _closed;
            _mutex.unlock ();
            return c;
        }

        /**
         * Returns the number of items currently in the buffer.
         *
         * @return current buffer size.
         */
        public int size () {
            _mutex.lock ();
            int s = _size;
            _mutex.unlock ();
            return s;
        }

        /**
         * Returns the buffer capacity.
         * 0 means unbuffered.
         *
         * @return the capacity.
         */
        public int capacity () {
            return _capacity;
        }
    }

    /**
     * Boxed int value for channel transport.
     */
    public class IntBox : GLib.Object {
        /** The int value. */
        public int value;
        /** Whether this is a sentinel for close notification. */
        public bool sentinel = false;

        /**
         * Creates a new IntBox.
         *
         * @param value the int value.
         */
        public IntBox (int value) {
            this.value = value;
        }
    }

    /**
     * Thread-safe string message-passing channel.
     *
     * In unbuffered mode (default), send blocks until a receiver calls
     * receive, providing strict rendezvous semantics.
     *
     * Example:
     * {{{
     *     var ch = ChannelString.buffered (5);
     *     ch.send ("hello");
     *     string msg = ch.receive ();
     * }}}
     */
    public class ChannelString : GLib.Object {
        private GLib.AsyncQueue<StringBox> _queue;
        private int _capacity;
        private bool _closed;
        private GLib.Mutex _mutex;
        private GLib.Cond _notFull;
        private GLib.Cond _delivered;
        private int _size;

        /**
         * Creates an unbuffered string channel.
         * Send blocks until a receiver is ready (rendezvous).
         */
        public ChannelString () {
            _capacity = 0;
            _closed = false;
            _size = 0;
            _queue = new GLib.AsyncQueue<StringBox> ();
        }

        /**
         * Creates a buffered string channel.
         *
         * @param capacity buffer size (must be > 0).
         * @return a new buffered ChannelString.
         */
        public static ChannelString buffered (int capacity) {
            if (capacity <= 0) {
                error ("capacity must be positive, got %d", capacity);
            }
            var ch = new ChannelString ();
            ch._capacity = capacity;
            return ch;
        }

        /**
         * Sends a string value into the channel.
         * For buffered channels, blocks if the buffer is full.
         * For unbuffered channels, blocks until a receiver calls receive.
         *
         * @param value the string to send.
         */
        public void send (string value) {
            _mutex.lock ();
            if (_closed) {
                _mutex.unlock ();
                warning ("send on closed channel");
                return;
            }

            if (_capacity > 0) {
                while (_size >= _capacity && !_closed) {
                    _notFull.wait (_mutex);
                }
                if (_closed) {
                    _mutex.unlock ();
                    warning ("send on closed channel");
                    return;
                }
                _queue.push (new StringBox (value));
                _size++;
                _mutex.unlock ();
            } else {
                while (_size > 0 && !_closed) {
                    _delivered.wait (_mutex);
                }
                if (_closed) {
                    _mutex.unlock ();
                    warning ("send on closed channel");
                    return;
                }
                _queue.push (new StringBox (value));
                _size++;
                while (_size > 0 && !_closed) {
                    _delivered.wait (_mutex);
                }
                _mutex.unlock ();
            }
        }

        /**
         * Tries to send a string value without blocking.
         *
         * @param value the string to send.
         * @return true if the value was sent.
         */
        public bool trySend (string value) {
            _mutex.lock ();
            if (_closed) {
                _mutex.unlock ();
                return false;
            }

            if (_capacity > 0 && _size >= _capacity) {
                _mutex.unlock ();
                return false;
            }
            if (_capacity == 0 && _size > 0) {
                _mutex.unlock ();
                return false;
            }

            _queue.push (new StringBox (value));
            _size++;
            _mutex.unlock ();
            return true;
        }

        /**
         * Receives a string from the channel, blocking until available.
         *
         * @return the received string, or empty string if closed and empty.
         */
        public string receive () {
            StringBox ? box = _queue.pop ();
            if (box == null) {
                return "";
            }
            if (box.sentinel) {
                _queue.push (box);
                return "";
            }

            _mutex.lock ();
            _size--;
            if (_capacity > 0) {
                _notFull.signal ();
            } else {
                _delivered.broadcast ();
            }
            _mutex.unlock ();

            return box.value;
        }

        /**
         * Tries to receive a string without blocking.
         *
         * @return the StringBox or null if nothing available.
         */
        public StringBox ? tryReceive () {
            StringBox ? box = _queue.try_pop ();
            if (box == null) {
                return null;
            }
            if (box.sentinel) {
                _queue.push (box);
                return null;
            }

            _mutex.lock ();
            _size--;
            if (_capacity > 0) {
                _notFull.signal ();
            } else {
                _delivered.broadcast ();
            }
            _mutex.unlock ();

            return box;
        }

        /**
         * Closes the channel.
         */
        public void close () {
            _mutex.lock ();
            _closed = true;
            _notFull.broadcast ();
            _delivered.broadcast ();
            _mutex.unlock ();

            var sentinel = new StringBox ("");
            sentinel.sentinel = true;
            _queue.push (sentinel);
        }

        /**
         * Returns whether the channel is closed.
         *
         * @return true if closed.
         */
        public bool isClosed () {
            _mutex.lock ();
            bool c = _closed;
            _mutex.unlock ();
            return c;
        }

        /**
         * Returns the number of items in the buffer.
         *
         * @return current buffer size.
         */
        public int size () {
            _mutex.lock ();
            int s = _size;
            _mutex.unlock ();
            return s;
        }

        /**
         * Returns the buffer capacity.
         *
         * @return the capacity (0 = unbuffered).
         */
        public int capacity () {
            return _capacity;
        }
    }

    /**
     * Boxed string value for channel transport.
     */
    public class StringBox : GLib.Object {
        /** The string value. */
        public string value;
        /** Whether this is a sentinel for close notification. */
        public bool sentinel = false;

        /**
         * Creates a new StringBox.
         *
         * @param value the string value.
         */
        public StringBox (string value) {
            this.value = value;
        }
    }
}
