# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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
