protocol ValidateWriter {
  func error(_ message: String)
  func standard(_ items: Any..., separator: String, terminator: String)
  func verbose(_ items: Any..., separator: String, terminator: String)
  func warning(_ message: String)
}

extension ValidateWriter {
  func standard() {
    standard([], separator: " ", terminator: "\n")
  }
  func standard(_ items: Any...) {
    standard(items, separator: " ", terminator: "\n")
  }
  func standard(_ items: Any..., terminator: String) {
    standard(items, separator: " ", terminator: terminator)
  }
  func verbose() {
    verbose([], separator: " ", terminator: "\n")
  }
  func verbose(_ items: Any...) {
    verbose(items, separator: " ", terminator: "\n")
  }
  func verbose(_ items: Any..., terminator: String) {
    verbose(items, separator: " ", terminator: terminator)
  }
}

struct ConsoleValidateWriter: ValidateWriter {
  func error(_ message: String) {
    Console.error(message)
  }
  func standard(_ message: Any..., separator: String, terminator: String) {
    Console.standard(message, separator: separator, terminator: terminator)
  }
  func verbose(_ message: Any..., separator: String, terminator: String) {
    Console.verbose(message, separator: separator, terminator: terminator)
  }
  func warning(_ message: String) {
    Console.warning(message)
  }
}
