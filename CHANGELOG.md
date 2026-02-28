# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## 0.5.0

### Added
- `Vala.Encoding.Base64` - Base64 encode/decode helpers
- `Vala.Encoding.Hex` - Hex encode/decode helpers
- `Vala.Encoding.Url` - URL percent encode/decode helpers
- `Vala.Crypto.Hash` - MD5/SHA hash utilities
- `Vala.Crypto.Hmac` - HMAC utilities
- `Vala.Crypto.Uuid` - UUID value object and parsing helpers
- `Vala.Text.Regex` - Regular expression utility methods
- `Vala.Regex.Pattern` - Compiled regex wrapper with find/replace/group APIs
- `Vala.Time.DateTime` - Immutable date-time value object
- `Vala.Time.Duration` - Immutable duration value object
- `Vala.Time.Stopwatch` - Stopwatch for elapsed-time measurement
- `Vala.Math.Math` - Extended math utility methods
- `Vala.Math.Random` - Random number and shuffle helpers
- `Vala.Net.Url` - Immutable URL value object
- `Vala.Collections.Arrays` - Array helper methods
- `Vala.Concurrent.Mutex` - Mutex wrapper utility
- `Vala.Concurrent.RWMutex` - Read/write lock wrapper utility
- `Vala.Concurrent.WaitGroup` - WaitGroup synchronization primitive
- `Vala.Concurrent.Once` - Run-once helper
- `Vala.Concurrent.Semaphore` - Counting semaphore
- `Vala.Concurrent.CountDownLatch` - CountDownLatch synchronization primitive
- `Vala.Lang.Process` - External process execution wrapper
- `Vala.Lang.Preconditions` - Argument and state validation helpers
- `Vala.Lang.SystemInfo` - OS/home/tmp/current-directory helpers
- `Vala.Lang.StringEscape` - HTML/JSON/XML escaping helpers
- `Vala.Lang.Threads` - Thread sleep helpers
- `Vala.Lang.SystemEnv` - Environment variable get/set helpers
- `Vala.Conv.Convert` - String/number/bool conversion helpers
- `Vala.Log.LogLevel` - Logging level enum
- `Vala.Log.Logger` - Named logger with level filtering and pluggable handlers
- `Vala.Format.NumberFormat` - Number/bytes/ordinal formatting helpers
- `Vala.Runtime.SystemProperties` - System property and time helpers
- `Vala.Config.Properties` - Java-like key-value configuration loader/saver

### Changed
- Expanded `README.md` API reference for new namespaces and classes
- Added Meson source and test targets for all newly introduced classes

### Fixed
- Updated `etc/uncrustify.cfg` for compatibility with newer uncrustify releases
- Fixed `scripts/format.sh --check` to report all formatting diffs without aborting on first mismatch

## 0.4.0

### Added
- `Vala.Collections.HashMap<K,V>` - Hash table with O(1) average lookup, backed by GLib.HashTable
- `Vala.Collections.HashSet<T>` - Hash-based set with union, intersection, difference, and subset operations
- `Vala.Collections.LinkedList<T>` - Doubly-linked list backed by GLib.Queue with indexed access
- `Vala.Collections.Deque<T>` - Double-ended queue with O(1) push/pop at both ends
- `Vala.Collections.Pair<A,B>` - Immutable two-element value object (Kotlin-style)
- `Vala.Collections.Triple<A,B,C>` - Immutable three-element value object (Kotlin-style)
- `Vala.Collections.PriorityQueue<T>` - Binary min-heap with custom comparator
- `Vala.Collections.BitSet` - Bit manipulation with auto-growing byte array backing
- `Vala.Collections.TreeMap<K,V>` - Sorted map backed by binary search tree with floorKey, ceilingKey, subMap
- New delegate type: `BiConsumerFunc<A,B>`

### Fixed
- Removed stale docs/images directory

## 0.3.0

### Added
- `Vala.Io.Scanner` - Tokenized input reader from files, strings, or stdin with configurable delimiter
- `Vala.Collections.Optional<T>` - Type-safe container for nullable values (inspired by Java Optional, Rust Option)
- `Vala.Collections.Result<T,E>` - Success/error container for exception-free error handling (inspired by Rust Result)
- `Vala.Collections.Stack<T>` - LIFO stack backed by GLib.Queue
- `Vala.Collections.Queue<T>` - FIFO queue backed by GLib.Queue
- `Vala.Collections.ArrayList<T>` - Dynamic array list with O(1) indexed access and functional operations (map, filter, reduce, find, sort)
- `Vala.Io.Files` - 10 new file operation methods (readBytes, writeBytes, chmod, chown, lastModified, createSymlink, readSymlink, isSameFile, glob, deleteRecursive)
- `Vala.Io.Path` - 5 new path methods (toUri, match, relativeTo, components, separator, volumeName, normalize, abs)
- New delegate types: `SupplierFunc<T>`, `ConsumerFunc<T>`, `PredicateFunc<T>`, `MapFunc<T,U>`, `ReduceFunc<T,U>`, `ComparatorFunc<T>`

## 0.2.0

### Added
- `Vala.Io.StringJoiner` - Delimiter-separated string construction with prefix/suffix support
- `Vala.Io.BufferedReader` - Buffered stream reading from files and strings
- `Vala.Io.BufferedWriter` - Buffered stream writing with append support
- `Vala.Io.StringBuilder` - Efficient mutable string construction
- `Vala.Io.Files` - 12 new file operation methods (copy, move, remove, readAllText, readAllLines, writeText, appendText, size, listDir, tempFile, tempDir, touch)
- `Vala.Io.Path` - 12 new path manipulation methods (extension, withoutExtension, withExtension, resolve, parent, join, isAbsolute, isRelative, normalize, startsWith, endsWith, equals)
- `Vala.Io.Strings` - 30+ new string utility methods

### Changed
- Removed Apache License headers from all Vala source files

### Fixed
- Valadoc workflow now correctly detects new untracked files in docs/

### Infrastructure
- Test coverage enforcement with 80% threshold
- Coverage reporting with lcov

## 0.1.0

### Added
- `Vala.Io.Files` - File and directory operations (isFile, isDir, exists, canRead, canWrite, canExec, isSymbolicFile, isHiddenFile, makeDirs, makeDir)
- `Vala.Io.Path` - File path manipulation (basename, dirname, toString)
- `Vala.Io.Strings` - String utilities (trimSpace, isNullOrEmpty, contains, splitByNum)
- `Vala.Lang.Objects` - Object utilities (isNull, nonNull)
- `Vala.Lang.Os` - OS interfaces (cwd, chdir, get_env)
- `Vala.Parser.ArgParser` - Command-line argument parsing with Builder pattern

### Changed
- Renamed `File` class to `Files` class with static methods (Java NIO style)
- Reorganized namespace structure (`Vala.Io`, `Vala.Lang`, `Vala.Parser`)
- API version derived from git tag automatically

### Infrastructure
- Meson build system with valadoc generation
- GitHub Actions CI (build, unit test, format check)
- Automatic valadoc update on tag push
- Automatic release notes from CHANGELOG on tag push
- Uncrustify code formatting
