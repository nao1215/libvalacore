namespace Vala.Config {
    /**
     * Java-like key-value properties container.
     */
    public class Properties : GLib.Object {
        private GLib.HashTable<string, string> _values;

        /**
         * Creates an empty Properties object.
         */
        public Properties () {
            _values = new GLib.HashTable<string, string>(str_hash, str_equal);
        }

        /**
         * Loads properties from file.
         *
         * Supported format:
         * - key=value
         * - blank lines are ignored
         * - lines starting with # are ignored
         *
         * @param path source file path.
         * @return true on success.
         */
        public bool load (Vala.Io.Path path) {
            string content;
            try {
                if (!FileUtils.get_contents (path.toString (), out content)) {
                    return false;
                }
            } catch (GLib.FileError e) {
                return false;
            }

            _values.remove_all ();
            string[] lines = content.split ("\n");
            foreach (string line in lines) {
                string trimmed = line.strip ();
                if (trimmed.length == 0 || trimmed.has_prefix ("#")) {
                    continue;
                }

                int index = trimmed.index_of_char ('=');
                if (index <= 0) {
                    continue;
                }

                string key = trimmed.substring (0, index).strip ();
                string value = trimmed.substring (index + 1).strip ();
                if (key.length == 0) {
                    continue;
                }
                _values.insert (key, value);
            }
            return true;
        }

        /**
         * Saves properties to file.
         *
         * @param path destination file path.
         * @return true on success.
         */
        public bool save (Vala.Io.Path path) {
            GLib.StringBuilder builder = new GLib.StringBuilder ();
            foreach (string key in keys ()) {
                string? value = _values.lookup (key);
                if (value == null) {
                    continue;
                }
                builder.append (key);
                builder.append ("=");
                builder.append (value);
                builder.append ("\n");
            }

            try {
                return FileUtils.set_contents (path.toString (), builder.str);
            } catch (GLib.FileError e) {
                return false;
            }
        }

        /**
         * Returns value by key.
         *
         * @param key target key.
         * @return value or null.
         */
        public new string ? get (string key) {
            if (key.length == 0) {
                return null;
            }
            return _values.lookup (key);
        }

        /**
         * Returns value or default when missing.
         *
         * @param key target key.
         * @param defaultValue fallback value.
         * @return found value or default.
         */
        public string getOrDefault (string key, string defaultValue) {
            string? value = get (key);
            return value ?? defaultValue;
        }

        /**
         * Sets key-value pair.
         *
         * @param key target key.
         * @param value value text.
         */
        public new void set (string key, string value) {
            if (key.length == 0) {
                return;
            }
            _values.insert (key, value);
        }

        /**
         * Removes a key.
         *
         * @param key target key.
         * @return true when removed.
         */
        public bool remove (string key) {
            if (key.length == 0) {
                return false;
            }
            return _values.remove (key);
        }

        /**
         * Returns all keys.
         *
         * @return array of keys.
         */
        public string[] keys () {
            string[] result = {};
            GLib.HashTableIter<string, string> iter = GLib.HashTableIter<string, string>(_values);
            unowned string key;
            unowned string value;
            while (iter.next (out key, out value)) {
                result += key;
            }
            return result;
        }

        /**
         * Returns number of entries.
         *
         * @return size.
         */
        public uint size () {
            return _values.size ();
        }
    }
}
