import Foundation

enum Verbosity {
  case quiet, standard, verbose
}

// This is modified at most once in `assignVerbosity` at program startup and
// never modified again, so it's concurrency safe in practice although the
// compiler can't verify this fact.
nonisolated(unsafe) var verbosity = Verbosity.standard

protocol Handle {
  var handle: FileHandle { get }
  var pointer: UnsafeMutablePointer<FILE> { get }
}

struct StderrOutputStream: Handle, TextOutputStream {
  let handle = FileHandle.standardError
  let pointer = stderr

  func write(_ string: String) {
    guard let data = string.data(using: .utf8) else {
      fatalError()  // encoding failure: handle as you wish
    }
    handle.write(data)
  }
}

struct StdoutOutputStream: Handle, TextOutputStream {
  let handle = FileHandle.standardOutput
  let pointer = stdout

  func write(_ string: String) {
    guard let data = string.data(using: .utf8) else {
      fatalError()  // encoding failure: handle as you wish
    }
    handle.write(data)
  }
}

struct Console {
  let colors =
    isatty(STDOUT_FILENO) != 0
    && (ProcessInfo.processInfo.environment["TERM"] ?? "").lowercased() != "dumb"

  private static func eprint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    var standardErr = StderrOutputStream()
    print(items, separator: separator, terminator: terminator, to: &standardErr)
    if terminator == "" {
      // otherwise Swift won't flush the handle -- screen won't be updated
      // until newline
      fflush(stderr)
    }
  }

  private static func intenalPrint<Target>(
    _ items: Any...,
    separator: String = " ",
    terminator: String = "\n",
    to output: inout Target
  ) where Target: Handle, Target: TextOutputStream {
    print(items, separator: separator, terminator: terminator, to: &output)
    if terminator == "" {
      // otherwise Swift won't flush the handle -- screen won't be updated
      // until newline
      fflush(output.pointer)
    }
  }

  /// Sends a message of error severity to `stderr`
  static func error(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    eprint(items, separator: separator, terminator: terminator)
  }

  /// Sends a message of warning severity to `stderr`
  static func warning(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    eprint(items, separator: separator, terminator: terminator)
  }

  /// Sometimes we want to send a non-error message to stdout no matter what the
  /// `verbosity` setting (e.g., when running `aural list`). This is for those
  /// times.
  static func force(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    var standardOut = StdoutOutputStream()
    intenalPrint(items, separator: separator, terminator: terminator, to: &standardOut)
  }

  /// Sends a message to `stdout` if the `verbosity` is not `.quiet`
  static func standard(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    if verbosity != .quiet {
      var standardOut = StdoutOutputStream()
      intenalPrint(items, separator: separator, terminator: terminator, to: &standardOut)
    }
  }

  /// Sends a message to `stdout` if the `verbosity` is `.verbose`
  static func verbose(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    if verbosity == .verbose {
      var standardOut = StdoutOutputStream()
      intenalPrint(items, separator: separator, terminator: terminator, to: &standardOut)
    }
  }
}
