# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## 0.9.0

### Changed
- Unified failure handling across core modules from process-abort style to recoverable errors:
  - `Vala.Lang.Context` now throws `ContextError` for invalid parent/key/timeout arguments
  - `Vala.Time.Cron` now throws `CronError` for invalid schedule/interval inputs
  - `Vala.Io.Watcher`/`Vala.Io.FileWatcher` now throw `WatcherError` on invalid watch targets
  - `Vala.Concurrent.SingleFlight` now reports invalid key/type mismatch via `SingleFlightError` (and failed futures)
  - `Vala.Lang.Preconditions` now throws `PreconditionError` instead of terminating the process
- `Vala.Lang.Exceptions.sneakyThrow` now rethrows the original `GLib.Error` instead of aborting
- `Vala.Concurrent.ChannelInt` / `Vala.Concurrent.ChannelString` `buffered(int)` now throw `ChannelError.INVALID_ARGUMENT` when `capacity <= 0`

### Fixed
- Removed remaining shell-command construction in archive helpers:
  - `Tar.create` now executes `tar` directly without `sh -c`
  - `Zip.create`/`Zip.createFromDir`/`Zip.extractFile` now avoid `sh -c` and use direct subprocess execution/streaming
- Improved archive safety and compatibility:
  - archive entry names starting with `-` are handled safely in create/extract paths
  - single-file extraction paths in Zip use temp-file write + move semantics
- Removed dead XML node code path (`XmlNode.appendText`) and strengthened XML node snapshot behavior tests
- Added regression tests for JSON builder snapshot semantics (`build()` result immutability against later builder reuse)
- Standardized temp test directory cleanup in JSON/XML/ZIP tests to filesystem API based deletion (no shell cleanup calls)

## 0.8.0

### Added
- `Vala.Validation.Validator` - Fluent validation API with `ValidationResult` and field-level errors
- `Vala.Time.Cron` - Interval/daily scheduling with cancellation support
- `Vala.Event.EventBus` - In-process pub/sub with sync and async dispatch modes
- `Vala.Io.FileTree` - Recursive tree walk, search, copy/sync, and delete utilities
- `Vala.Crypto.Identifiers` - Identifier helpers including UUID/ULID/KSUID generation
- `Vala.Io.Watcher` and `Vala.Io.FileWatcher` - File system watching with recursive and glob modes
- `Vala.Compress.Gzip` and `Vala.Compress.Zlib` - Byte/file compression and decompression helpers
- `Vala.Archive.Zip` and `Vala.Archive.Tar` - Archive create/extract/list/update helpers
- `Vala.Encoding.Json` - JSON value tree, query, immutable update, merge, flatten, and pretty-print
- `Vala.Net.Http` - One-liner HTTP helpers and request builder with headers/auth/query/body utilities
- `Vala.Text.Template` - Mustache-style template rendering with conditionals, loops, filters, and fallback values
- `Vala.Encoding.Xml` - XML parse/serialize helpers with XPath-style query
- `Vala.Encoding.Toml` - TOML parse/query/stringify helpers
- `Vala.Encoding.Yaml` - YAML parse/query/stringify helpers including multi-document parsing

### Changed
- Expanded `README.md` API reference for newly added modules and types
- Added/expanded Meson test targets for new modules
- Consolidated CI checks into a single workflow that runs configure/build/test/coverage in sequence
- Optimized `scripts/coverage.sh` for CI reuse:
  - reuses existing coverage-enabled build artifacts by default
  - supports `--skip-test` to avoid duplicate test execution
  - captures coverage in a single `lcov` pass over `build/tests` (with optional `--parallel` when available)

### Fixed
- `Gzip`/`Zlib` converter loops no longer rebuild full tail buffers per iteration
- `Gzip.compressLevel`/`Zlib.compressLevel` now fail gracefully on invalid levels (empty byte array)
- `Tar.create` now validates input before removing an existing destination archive
- `Tar.createFromDir` now uses `tar -C` to preserve destination path semantics
- `Tar.extractFile` now extracts to a temp file and atomically moves on success to avoid destination truncation on failure
- `Yaml` flow mapping now preserves nested flow values (`{}`/`[]`) and handles commas inside quoted scalars
- `EventBus` async dispatch now uses bounded `WorkerPool` instead of per-handler thread creation
- `EventBus.subscribeOnce` now removes one-shot subscribers before dispatch to avoid duplicate delivery under concurrent publish
- `Http` timeout conversion now validates milliseconds and avoids zero/overflowed socket timeouts
- `Http` response parser now validates `Content-Length`/chunk sizes and supports chunk-size extensions
- `Http.download` now streams response bodies directly to disk instead of loading full payloads in memory
- `Toml.getIntOr` now guards int64-to-int narrowing overflow
- `Xml` parser now validates closing tag names, and serializer preserves mixed-content order
- `ValidationResult.errors()` and `Validator.validate()` now return defensive snapshots
- `Validator.validate()` now resets validator internal state between runs, and field validation rejects whitespace-only names
- Replaced shell-based recursive cleanup in tests with filesystem API helpers
- Synchronized shared counters in concurrency-sensitive tests (`EventBus`, `ThreadPool2`, `Cron`)
- `Yaml` inline mapping values now parse as full nodes (not scalar-only), quoted escapes are decoded, and `key:value` (no-space) flow pairs are accepted
- `Yaml` serializer now quotes strings with leading/trailing whitespace to preserve round-trip fidelity
- `Tar` relative path safety check now rejects only true parent traversal components (`..`, `../...`) without over-rejecting names like `..foo`

## 0.7.0

### Added
- `Vala.Net.Retry` - Configurable retry policy with fixed/exponential backoff, jitter, retry predicates, and HTTP status-based retry filtering
- `Vala.Net.RateLimiter` - Token-bucket rate limiter with non-blocking (`allow`) and blocking (`wait`) permit acquisition
- `Vala.Net.CircuitBreaker` - Circuit breaker state machine (`CLOSED`/`OPEN`/`HALF_OPEN`) for unstable dependency protection
- `Vala.Io.AtomicFile` - Atomic file update helper with optional backup support and consistency-read helper
- `Vala.Io.FileLock` - Lock-file based inter-process synchronization utility with timeout and callback execution helper
- `Vala.Io.Shell` and `Vala.Io.ShellResult` - Shell command execution utility with captured output, timeout execution, pipelines, and `which` resolution
- New Valadoc wiki guides:
  - `docs/wiki/getting-started.valadoc`
  - `docs/wiki/io-guide.valadoc`
  - `docs/wiki/resilience-guide.valadoc`

### Changed
- Expanded Valadoc class-level documentation across core namespaces (`Vala.Lang`, `Vala.Io`, `Vala.Concurrent`, `Vala.Crypto`, `Vala.Math`, `Vala.Time`, `Vala.Text`) with usage-oriented descriptions and examples
- Reworked `docs/wiki/index.valadoc` to include:
  - design goals
  - quick start
  - implemented namespace guide
  - recommended entry points
  - links to practical guides

## 0.6.0

### Added
- `Vala.Concurrent.WorkerPool` - Fixed-size thread pool with task queue and typed promises (PromiseInt, PromiseString, PromiseBool, PromiseDouble)
- `Vala.Concurrent.ChannelInt` - Go-style typed int channel with buffered and unbuffered (rendezvous) modes
- `Vala.Concurrent.ChannelString` - Go-style typed string channel with buffered and unbuffered (rendezvous) modes
- `Vala.Collections.Stream<T>` - Fluent pipeline API for collection transformations (filter, map, sorted, distinct, limit, skip, takeWhile, dropWhile, peek, reduce, min, max)
- `Vala.Collections.Lists` - Static utility methods for ArrayList operations (partition, chunk, zip, flatten, groupBy, distinct, reverse, sliding, interleave, frequency)
- `Vala.Collections.Maps` - Static utility methods for HashMap operations (merge, filter, mapValues, mapKeys, invert, getOrDefault, computeIfAbsent, keys, values, entries, fromPairs)
- `Vala.Collections.MultiMap<K,V>` - One-key to multiple-values collection
- `Vala.Collections.ImmutableList<T>` - Immutable list value object
- `Vala.Collections.LruCache<K,V>` - LRU cache with optional TTL and cache-miss loader
- `Vala.Math.BigDecimal` - Arbitrary-precision decimal arithmetic
- `Vala.Math.BigInteger` - Arbitrary-precision integer arithmetic
- `Vala.Encoding.Csv` - CSV parser and writer utilities
- `Vala.Io.Filesystem` - Filesystem metadata helpers
- `Vala.Io.Console` - TTY detection and password input utilities
- `Vala.Io.Process` - Process execution utilities
- `Vala.Io.Resource` - Binary resource read helpers
- `Vala.Io.Temp` - Temporary file/directory helpers with auto-cleanup callbacks
- `Vala.Time.Dates` - Date utility helpers
- `Vala.Lang.Exceptions` - Exception utility class
- `Vala.Lang.ShutdownHooks` - Atexit callback registration
- `Vala.Lang.Randoms` - Random utility class
- New delegate types: `BiPredicateFunc<A,B>`, `TaskFunc<T>`, `VoidTaskFunc`

### Changed
- Expanded `README.md` API reference for all new classes
- `Lists.distinctString` optimized from O(n²) to O(n) using HashSet

### Fixed
- `Stream.skip` now guards against negative input
- Channel unbuffered mode now implements strict rendezvous semantics (one sender in flight at a time)
- Channel `receive()` on closed empty channel returns immediately via sentinel instead of blocking
- Channel uses `broadcast()` for delivered condition to prevent deadlock with multiple concurrent senders
- WorkerPool `enqueue()` is now atomic with shutdown check (queue push inside critical section)
- WorkerPool promises are always completed with default values when tasks are rejected after shutdown
- WorkerPool `shutdown()` is idempotent and guards against self-join deadlock

### Infrastructure
- Added vala-lint integration with Docker-based CI check

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
