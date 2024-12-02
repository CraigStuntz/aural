import Foundation

/// These are different log levels which can be compared with the `--verbosity`
/// level to determine if we should output to the screen
enum Level {
  case force, standard, verbose
}

/// This represents possible values for the `--verbosity` flag
enum Verbosity {
  case quiet, standard, verbose
}

// This is modified at most once in `assignVerbosity` at program startup and
// never modified again, so it's concurrency safe in practice although the
// compiler can't verify this fact.
nonisolated(unsafe) var verbosity = Verbosity.standard

protocol Handle: TextOutputStream {
  var handle: FileHandle { get }
  var pointer: UnsafeMutablePointer<FILE> { get }
}

extension Handle {
  func write(_ string: String) {
    guard let data = string.data(using: .utf8) else {
      fatalError()  // encoding failure: handle as you wish
    }
    handle.write(data)
  }
}

struct StderrOutputStream: Handle {
  let handle = FileHandle.standardError
  let pointer = stderr
}

struct StdoutOutputStream: Handle {
  let handle = FileHandle.standardOutput
  let pointer = stdout
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

  private static func internalPrint<Target>(
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

  /// Sends a message to `stdout` if the `verbosity` is not `.quiet`
  static func standard(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    if shouldPrintFor(level: .standard) {
      var standardOut = StdoutOutputStream()
      internalPrint(items, separator: separator, terminator: terminator, to: &standardOut)
    }
  }

  /// Sends a message to `stdout` if the `verbosity` is `.verbose`
  static func verbose(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    if shouldPrintFor(level: .verbose) {
      var standardOut = StdoutOutputStream()
      internalPrint(items, separator: separator, terminator: terminator, to: &standardOut)
    }
  }

  static func write(
    _ items: Any..., separator: String = " ", terminator: String = "\n", level: Level = .standard
  ) {
    if shouldPrintFor(level: level) {
      var standardOut = StdoutOutputStream()
      internalPrint(items, separator: separator, terminator: terminator, to: &standardOut)
    }
  }

  private static func shouldPrintFor(level: Level) -> Bool {
    return switch level {
    case .force: true
    case .verbose: verbosity == .verbose
    default: verbosity != .quiet
    }
  }
}
