[![Build](https://github.com/nao1215/libcore/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/nao1215/libcore/actions/workflows/build.yml)
[![UnitTest](https://github.com/nao1215/libcore/actions/workflows/unit_test.yml/badge.svg?branch=main)](https://github.com/nao1215/libcore/actions/workflows/unit_test.yml)
![GitHub](https://img.shields.io/github/license/nao1215/libcore)

![logo](./docs/images/logo-small.png)

libvalacore is an ambitious effort to build a powerful core standard library for the Vala language.

Vala has a solid GLib/GObject foundation, but lacks the kind of rich, batteries-included standard library that developers in Java, Go, Python, or OCaml take for granted. libvalacore fills that gap: it provides intuitive, consistent, and well-tested APIs for file I/O, collections, string processing, encoding, cryptography, networking, concurrency, and much more — all designed to feel natural in idiomatic Vala.

Our goal is to make Vala a language where everyday programming tasks can be accomplished with a single import, without hunting for scattered third-party packages or reinventing the wheel.

>[!NOTE]
> This library is under active development. The API is not yet stable and may change without notice.

## API Reference

### Valadoc
[Click here for libcore's Valadoc.](https://nao1215.github.io/libvalacore/)


### Vala.Io.Files
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
| `copy(Path src, Path dst)` | Copies a file from source to destination |
| `move(Path src, Path dst)` | Moves (renames) a file |
| `remove(Path path)` | Deletes a file or empty directory |
| `readAllText(Path path)` | Reads the entire file as a string |
| `readAllLines(Path path)` | Reads the file as a list of lines |
| `writeText(Path path, string text)` | Writes a string to a file |
| `appendText(Path path, string text)` | Appends a string to a file |
| `size(Path path)` | Returns the file size in bytes |
| `listDir(Path path)` | Lists directory entries |
| `tempFile(string prefix, string suffix)` | Creates a temporary file |
| `tempDir(string prefix)` | Creates a temporary directory |
| `touch(Path path)` | Creates a file or updates its modification time |
| `readBytes(Path path)` | Reads file contents as a byte array |
| `writeBytes(Path path, uint8[] data)` | Writes a byte array to a file |
| `chmod(Path path, int mode)` | Changes file permissions |
| `chown(Path path, int uid, int gid)` | Changes file ownership |
| `lastModified(Path path)` | Returns the last modification time |
| `createSymlink(Path target, Path link)` | Creates a symbolic link |
| `readSymlink(Path path)` | Reads the target of a symbolic link |
| `isSameFile(Path a, Path b)` | Returns whether two paths refer to the same file |
| `glob(Path dir, string pattern)` | Returns files matching a glob pattern |
| `deleteRecursive(Path path)` | Recursively deletes a directory and all its contents |

### Vala.Io.Path
An immutable value object representing a file system path. Methods that transform the path return a new Path instance.

| Method | Description |
|---|---|
| `Path(string path)` | Constructor. Creates a Path from a string |
| `toString()` | Returns the path as a string |
| `basename()` | Extracts the base name (file name) from the path |
| `dirname(string path)` | Extracts the directory name from the path |
| `extension()` | Returns the file extension including the dot (e.g. ".txt") |
| `withoutExtension()` | Returns the path without the file extension |
| `isAbsolute()` | Returns whether the path is absolute |
| `parent()` | Returns a new Path for the parent directory |
| `resolve(string other)` | Resolves a path against this path |
| `join(string part1, ...)` | Joins multiple path components |
| `equals(Path other)` | Returns whether two paths are equal |
| `startsWith(string prefix)` | Returns whether the path starts with the prefix |
| `endsWith(string suffix)` | Returns whether the path ends with the suffix |
| `components()` | Returns the path components as a list |
| `normalize()` | Returns a normalized path (resolves "." and "..") |
| `abs()` | Returns the absolute, normalized path |
| `separator()` | Returns the OS path separator (static) |
| `volumeName()` | Returns the volume name (empty on Linux) |
| `toUri()` | Returns the file:// URI representation |
| `match(string pattern)` | Returns whether the basename matches a glob pattern |
| `relativeTo(Path base)` | Computes the relative path from a base path |

### Vala.Io.Scanner
Tokenized input reader inspired by Java's Scanner and Go's bufio.Scanner. Reads from files, strings, or stdin and splits input by a configurable delimiter.

| Method | Description |
|---|---|
| `Scanner.fromFile(Path path)` | Creates a Scanner from a file (returns null on error) |
| `Scanner.fromString(string s)` | Creates a Scanner from a string |
| `Scanner.fromStdin()` | Creates a Scanner from standard input |
| `nextLine()` | Reads the next line |
| `nextInt()` | Reads the next token as an integer |
| `nextDouble()` | Reads the next token as a double |
| `next()` | Reads the next token (split by delimiter) |
| `hasNextLine()` | Returns whether there is another line |
| `hasNextInt()` | Returns whether the next token is an integer |
| `setDelimiter(string pattern)` | Sets the delimiter regex pattern |
| `close()` | Closes the underlying stream |

### Vala.Io.StringBuilder
A mutable string buffer for efficient string construction. Wraps GLib.StringBuilder with a rich, Java/C#-inspired API.

| Method | Description |
|---|---|
| `StringBuilder()` | Creates an empty StringBuilder |
| `StringBuilder.withString(string s)` | Creates a StringBuilder with initial content |
| `StringBuilder.sized(size_t size)` | Creates a StringBuilder with pre-allocated capacity |
| `append(string s)` | Appends a string |
| `appendLine(string s)` | Appends a string followed by a newline |
| `appendChar(char c)` | Appends a single character |
| `insert(int offset, string s)` | Inserts a string at the specified position |
| `deleteRange(int start, int end)` | Deletes characters in [start, end) |
| `replaceRange(int start, int end, string s)` | Replaces characters in [start, end) |
| `reverse()` | Reverses the contents |
| `length()` | Returns the current byte length |
| `charAt(int index)` | Returns the character at the index |
| `clear()` | Clears the buffer |
| `toString()` | Returns the built string |
| `capacity()` | Returns the allocated buffer capacity |

### Vala.Io.BufferedWriter
Buffered character-output-stream writer. Wraps GLib.DataOutputStream for convenient string and line writing, similar to Java's BufferedWriter.

| Method | Description |
|---|---|
| `BufferedWriter.fromFile(Path path)` | Creates a writer to a file (replaces content) |
| `BufferedWriter.fromFileAppend(Path path)` | Creates a writer that appends to a file |
| `write(string s)` | Writes a string to the stream |
| `writeLine(string s)` | Writes a string followed by a newline |
| `newLine()` | Writes a newline |
| `flush()` | Flushes any buffered data |
| `close()` | Closes the underlying stream |

### Vala.Io.BufferedReader
Buffered character-input-stream reader. Wraps GLib.DataInputStream for convenient line-by-line or full-text reading, similar to Java's BufferedReader.

| Method | Description |
|---|---|
| `BufferedReader.fromFile(Path path)` | Creates a reader from a file (returns null on error) |
| `BufferedReader.fromString(string s)` | Creates a reader from a string |
| `readLine()` | Reads a single line (null at EOF) |
| `readChar()` | Reads a single byte as a character |
| `readAll()` | Reads the remaining stream as a string |
| `hasNext()` | Returns whether there is more data to read |
| `close()` | Closes the underlying stream |

### Vala.Io.StringJoiner
Constructs a sequence of characters separated by a delimiter, optionally with a prefix and suffix. Equivalent to Java's StringJoiner.

| Method | Description |
|---|---|
| `StringJoiner(string delimiter, string prefix, string suffix)` | Constructor. Creates a StringJoiner with delimiter, prefix, and suffix |
| `add(string element)` | Adds an element to the joiner |
| `merge(StringJoiner other)` | Merges another joiner's elements into this one |
| `setEmptyValue(string value)` | Sets the value returned when no elements are present |
| `length()` | Returns the length of the joined string |
| `toString()` | Returns the joined string with prefix, elements, and suffix |

### Vala.Io.Strings
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

### Vala.Collections.Optional\<T\>
A type-safe container that may or may not contain a value. An alternative to null inspired by Java's Optional, OCaml's option, and Rust's Option.

| Method | Description |
|---|---|
| `Optional.of<T>(T value)` | Creates an Optional containing the value |
| `Optional.empty<T>()` | Creates an empty Optional |
| `Optional.ofNullable<T>(T? value)` | Creates an Optional from a nullable value |
| `isPresent()` | Returns whether a value is present |
| `isEmpty()` | Returns whether this Optional is empty |
| `get()` | Returns the value, or null if empty |
| `orElse(T other)` | Returns the value, or the default if empty |
| `orElseGet(SupplierFunc<T> func)` | Returns the value, or invokes the supplier if empty |
| `ifPresent(ConsumerFunc<T> func)` | Invokes the function if a value is present |
| `filter(PredicateFunc<T> func)` | Returns this Optional if matching, otherwise empty |

### Vala.Collections.Result\<T,E\>
A container representing either a success value or an error. Inspired by Rust's Result and OCaml's result.

| Method | Description |
|---|---|
| `Result.ok<T,E>(T value)` | Creates a successful Result |
| `Result.error<T,E>(E err)` | Creates a failed Result |
| `isOk()` | Returns whether this is a success |
| `isError()` | Returns whether this is an error |
| `unwrap()` | Returns the success value, or null if error |
| `unwrapOr(T defaultValue)` | Returns the success value, or the default on error |
| `unwrapError()` | Returns the error value, or null if success |
| `map<U>(MapFunc<T,U> func)` | Transforms the success value |
| `mapError<F>(MapFunc<E,F> func)` | Transforms the error value |

### Vala.Collections.Stack\<T\>
A LIFO (Last-In-First-Out) stack backed by GLib.Queue.

| Method | Description |
|---|---|
| `push(T element)` | Pushes an element onto the top |
| `pop()` | Removes and returns the top element |
| `peek()` | Returns the top element without removing it |
| `size()` | Returns the number of elements |
| `isEmpty()` | Returns whether the stack is empty |
| `clear()` | Removes all elements |

### Vala.Collections.Queue\<T\>
A FIFO (First-In-First-Out) queue backed by GLib.Queue.

| Method | Description |
|---|---|
| `enqueue(T element)` | Adds an element to the end |
| `dequeue()` | Removes and returns the front element |
| `peek()` | Returns the front element without removing it |
| `size()` | Returns the number of elements |
| `isEmpty()` | Returns whether the queue is empty |
| `clear()` | Removes all elements |

## Vala.Lang.Objects
Static utility methods for null checking.

| Method | Description |
|---|---|
| `isNull<T>(T? obj)` | Returns whether the object is null |
| `nonNull<T>(T? obj)` | Returns whether the object is not null |

### Vala.Lang.Os
Operating system interface methods.

| Method | Description |
|---|---|
| `get_env(string env)` | Returns the value of an environment variable (null if not set) |
| `cwd()` | Returns the current working directory |
| `chdir(string path)` | Changes the current working directory |

### Vala.Parser.ArgParser
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

#### ArgParser.Builder

| Method | Description |
|---|---|
| `applicationName(string name)` | Sets the application name |
| `applicationArgument(string arg)` | Sets the argument placeholder for usage display |
| `description(string desc)` | Sets the application description |
| `version(string ver)` | Sets the application version |
| `author(string author)` | Sets the author name |
| `contact(string contact)` | Sets the contact information |
| `build()` | Builds and returns the ArgParser instance |

## How to build (install)
```
$ sudo apt update
$ sudo apt install valac build-essential meson valadoc libglib2.0-dev ninja-build uncrustify

$ git clone https://github.com/nao1215/libvalacore.git
$ cd libvalacore
$ meson setup build
$ ninja -C build
$ sudo ninja -C build install
```

## How to test
```
$ meson setup build
$ meson test -C build
```

## Test coverage
We target 80%+ line coverage. CI enforces this threshold automatically.
```
$ sudo apt install lcov
$ ./scripts/coverage.sh          # Show coverage summary
$ ./scripts/coverage.sh --check  # Check 80% threshold (fails if below)
$ ./scripts/coverage.sh --html   # Generate HTML report
```

## Code formatting
All Vala source code is formatted with [uncrustify](https://github.com/uncrustify/uncrustify) using the config at `etc/uncrustify.cfg`.
```
$ ./scripts/format.sh          # Format all .vala files
$ ./scripts/format.sh --check  # Check formatting (CI mode)
```

## Contributing
Contributions are welcome! Please follow the steps below:

1. Read [CONTRIBUTING.md](./CONTRIBUTING.md)
2. Fork the repository and create a feature branch
3. Format your code: `./scripts/format.sh`
4. Add tests and make sure they pass: `meson setup build && meson test -C build`
5. Submit a pull request


## LICENSE
The libvalacore project is licensed under the terms of the Apache License 2.0.
See [LICENSE](./LICENSE).
