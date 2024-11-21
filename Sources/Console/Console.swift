import Foundation

enum Verbosity {
  case quiet, standard, verbose
}

nonisolated(unsafe) var verbosity = Verbosity.standard

struct StderrOutputStream: TextOutputStream {
  mutating func write(_ string: String) {
    fputs(string, stderr)
  }
}

struct Console {
  let colors =
    isatty(STDOUT_FILENO) != 0
    && (ProcessInfo.processInfo.environment["TERM"] ?? "").lowercased() != "dumb"

  private static func eprint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    var standardError = StderrOutputStream()
    print(items, separator: separator, terminator: terminator, to: &standardError)
    if terminator == "" {
      // otherwise Swift won't flush the handle -- screen won't be updated
      // until newline
      fflush(stderr)
    }
  }

  private static func intenalPrint(
    _ items: Any..., separator: String = " ", terminator: String = "\n"
  ) {
    print(items, separator: separator, terminator: terminator)
    if terminator == "" {
      // otherwise Swift won't flush the handle -- screen won't be updated
      // until newline
      fflush(stdout)
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
    intenalPrint(items, separator: separator, terminator: terminator)
  }

  /// Sends a message to `stdout` if the `verbosity` is not `.quiet`
  static func standard(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    if verbosity != .quiet {
      intenalPrint(items, separator: separator, terminator: terminator)
    }
  }

  /// Sends a message to `stdout` if the `verbosity` is `.verbose`
  static func verbose(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    if verbosity == .verbose {
      intenalPrint(items, separator: separator, terminator: terminator)
    }
  }
}
