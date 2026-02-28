[![Build](https://github.com/nao1215/libcore/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/nao1215/libcore/actions/workflows/build.yml)
[![UnitTest](https://github.com/nao1215/libcore/actions/workflows/unit_test.yml/badge.svg?branch=main)](https://github.com/nao1215/libcore/actions/workflows/unit_test.yml)
![GitHub](https://img.shields.io/github/license/nao1215/libcore)

## libvalacore - standard library extension for Vala
libvalacore provides a rich set of convenient, high-level APIs that complement the Vala standard library.

Inspired by the standard libraries of Java, Go, and OCaml, it offers intuitive and consistent interfaces for file I/O, string manipulation, argument parsing, and more.

>[!NOTE]
> This library is under active development. The API is not yet stable and may change without notice.

# API Reference

## Vala.Io.Files
File and directory operations. All methods are static and take a `Vala.Io.Path` argument.

| Method | Description |
|---|---|
| `isFile(Path path)` | Returns whether the path is a regular file |
| `isDir(Path path)` | Returns whether the path is a directory |
| `exists(Path path)` | Returns whether the file or directory exists |
| `canRead(Path path)` | Returns whether the path is readable |
| `canWrite(Path path)` | Returns whether the path is writable |
| `canExec(Path path)` | Returns whether the path is executable |
| `isSymbolicFile(Path path)` | Returns whether the path is a symbolic link |
| `isHiddenFile(Path path)` | Returns whether the path is a hidden file (starts with `.`) |
| `makeDirs(Path path)` | Creates a directory including parent directories |
| `makeDir(Path path)` | Creates a single directory |

## Vala.Io.Path
An object representing a file system path.

| Method | Description |
|---|---|
| `Path(string path)` | Constructor. Creates a Path from a string |
| `toString()` | Returns the path as a string |
| `basename()` | Extracts the base name (file name) from the path |
| `dirname(string path)` | Extracts the directory name from the path |

## Vala.Io.Strings
Static utility methods for string manipulation. All methods are null-safe.

| Method | Description |
|---|---|
| `isNullOrEmpty(string? str)` | Returns whether the string is null or empty |
| `isBlank(string? s)` | Returns whether the string is null, empty, or whitespace only |
| `isNumeric(string? s)` | Returns whether the string contains only digits |
| `isAlpha(string? s)` | Returns whether the string contains only alphabetic characters |
| `isAlphaNumeric(string? s)` | Returns whether the string contains only alphanumeric characters |
| `trimSpace(string str)` | Removes leading and trailing whitespace/tabs |
| `trimLeft(string? s, string cutset)` | Removes specified characters from the left |
| `trimRight(string? s, string cutset)` | Removes specified characters from the right |
| `trimPrefix(string? s, string prefix)` | Removes the prefix if present |
| `trimSuffix(string? s, string suffix)` | Removes the suffix if present |
| `contains(string? s, string? substr)` | Returns whether `s` contains `substr` |
| `startsWith(string? s, string? prefix)` | Returns whether `s` starts with `prefix` |
| `endsWith(string? s, string? suffix)` | Returns whether `s` ends with `suffix` |
| `toUpperCase(string? s)` | Converts to upper case |
| `toLowerCase(string? s)` | Converts to lower case |
| `replace(string? s, string old, string new)` | Replaces all occurrences |
| `repeat(string? s, int count)` | Repeats the string `count` times |
| `reverse(string? s)` | Reverses the string |
| `padLeft(string? s, int len, char pad)` | Pads on the left to specified length |
| `padRight(string? s, int len, char pad)` | Pads on the right to specified length |
| `center(string? s, int width, char pad)` | Centers within specified width |
| `indexOf(string? s, string? substr)` | Returns index of first occurrence (-1 if not found) |
| `lastIndexOf(string? s, string? substr)` | Returns index of last occurrence (-1 if not found) |
| `count(string? s, string? substr)` | Counts non-overlapping occurrences |
| `join(string separator, string[] parts)` | Joins array with separator |
| `split(string? s, string delimiter)` | Splits by delimiter |
| `splitByNum(string str, uint num)` | Splits every `num` characters |
| `substring(string? s, int start, int end)` | Returns substring [start, end) |
| `capitalize(string? s)` | Capitalizes the first character |
| `toCamelCase(string? s)` | Converts to camelCase |
| `toSnakeCase(string? s)` | Converts to snake_case |
| `toKebabCase(string? s)` | Converts to kebab-case |
| `toPascalCase(string? s)` | Converts to PascalCase |
| `title(string? s)` | Capitalizes the first letter of each word |
| `compareTo(string? a, string? b)` | Lexicographic comparison |
| `compareIgnoreCase(string? a, string? b)` | Case-insensitive comparison |
| `equalsIgnoreCase(string? a, string? b)` | Case-insensitive equality |
| `lines(string? s)` | Splits by newlines |
| `words(string? s)` | Splits by whitespace (non-empty tokens) |
| `truncate(string? s, int maxLen, string ellipsis)` | Truncates with ellipsis |
| `wrap(string? s, int width)` | Wraps at specified width |

## Vala.Lang.Objects
Static utility methods for null checking.

| Method | Description |
|---|---|
| `isNull<T>(T? obj)` | Returns whether the object is null |
| `nonNull<T>(T? obj)` | Returns whether the object is not null |

## Vala.Lang.Os
Operating system interface methods.

| Method | Description |
|---|---|
| `get_env(string env)` | Returns the value of an environment variable (null if not set) |
| `cwd()` | Returns the current working directory |
| `chdir(string path)` | Changes the current working directory |

## Vala.Parser.ArgParser
Command-line argument parser with Builder pattern.

| Method | Description |
|---|---|
| `addOption(string short, string long, string desc)` | Registers a command-line option |
| `parse(string[] args)` | Parses command-line arguments |
| `hasOption(string shortOption)` | Returns whether the option was specified |
| `usage()` | Prints usage information to stdout |
| `showVersion()` | Prints application version to stdout |
| `copyArgWithoutCmdNameAndOptions()` | Returns arguments excluding the command name and options |
| `parseResult()` | Returns a string summarizing all options and arguments |

### ArgParser.Builder

| Method | Description |
|---|---|
| `applicationName(string name)` | Sets the application name |
| `applicationArgument(string arg)` | Sets the argument placeholder for usage display |
| `description(string desc)` | Sets the application description |
| `version(string ver)` | Sets the application version |
| `author(string author)` | Sets the author name |
| `contact(string contact)` | Sets the contact information |
| `build()` | Builds and returns the ArgParser instance |

# How to build (install)
```
$ sudo apt update
$ sudo apt install valac build-essential meson valadoc libglib2.0-dev ninja-build uncrustify

$ git clone https://github.com/nao1215/libvalacore.git
$ cd libvalacore
$ meson setup build
$ ninja -C build
$ sudo ninja -C build install
```

# How to test
```
$ meson setup build
$ meson test -C build
```

# Test coverage
We target 80%+ line coverage. CI enforces this threshold automatically.
```
$ sudo apt install lcov
$ ./scripts/coverage.sh          # Show coverage summary
$ ./scripts/coverage.sh --check  # Check 80% threshold (fails if below)
$ ./scripts/coverage.sh --html   # Generate HTML report
```

# Code formatting
All Vala source code is formatted with [uncrustify](https://github.com/uncrustify/uncrustify) using the config at `etc/uncrustify.cfg`.
```
$ ./scripts/format.sh          # Format all .vala files
$ ./scripts/format.sh --check  # Check formatting (CI mode)
```

# Valadoc
[Click here for libcore's Valadoc.](https://nao1215.github.io/libvalacore/)

# Contributing
Contributions are welcome! Please follow the steps below:

1. Read [CONTRIBUTING.md](./CONTRIBUTING.md)
2. Fork the repository and create a feature branch
3. Format your code: `./scripts/format.sh`
4. Add tests and make sure they pass: `meson setup build && meson test -C build`
5. Submit a pull request


# LICENSE
The libvalacore project is licensed under the terms of the Apache License 2.0.
See [LICENSE](./LICENSE).
