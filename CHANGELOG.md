# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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
