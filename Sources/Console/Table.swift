/// A simple table component to display data in a CLI
struct Table {
  let maxesByColumn: [Int]
  let data: [[String]]
  let headers: [String]

  init(headers: [String], data: [[String]]) {
    self.data = data
    self.headers = headers
    self.maxesByColumn = Table.maxes(headers, data)
  }

  /// Create a table using type information.
  /// - Parameters:
  ///   - reflecting: A sample object to be used for generation of header names
  ///   - data: A list of data objects, which will be displayed using `Mirror`
  init<T>(reflecting: T, data: [T]) {
    let mirror = Mirror(reflecting: reflecting)
    self.headers = mirror.children.map { child in child.label ?? "" }
    self.data = data.map { datum in
      Mirror(reflecting: datum).children.map { val in String(describing: val.value) }
    }
    self.maxesByColumn = Table.maxes(self.headers, self.data)
  }

  /// finds the maximum data/header width of each column
  static func maxes(_ headers: [String], _ data: [[String]]) -> [Int] {
    if headers.isEmpty && data.isEmpty {
      return []
    }
    var result: [Int] = []
    for column in 0..<data[0].count {
      var maxWidth = data.map { $0[column].count }.max()
      if headers.count > column {
        maxWidth = max(maxWidth ?? 0, headers[column].count)
      }
      guard let max = maxWidth else {
        fatalError(
          """
          Could not find a max width of data or header. 
          This should never happen due to a check at the top of the method.
          """)
      }
      result.append(max)
    }
    return result
  }

  /// returns Table data with all headers (and separators) and data padded to column widths
  func toPadded() -> [[String]] {
    var result: [[String]] = []
    if !headers.isEmpty {
      let paddedHeaders = self.headers.enumerated().map {
        $1.padding(toLength: self.maxesByColumn[$0], withPad: " ", startingAt: 0)
      }
      let dividers = paddedHeaders.enumerated().map {
        (index, header) in String(repeatElement("-", count: self.maxesByColumn[index]))
      }
      result.append(paddedHeaders)
      result.append(dividers)
    }
    let paddedData = self.data.map { line in
      line.enumerated().map {
        $1.padding(toLength: self.maxesByColumn[$0], withPad: " ", startingAt: 0)
      }
    }
    result += paddedData
    return result
  }

  func printToConsole(level: Level = .standard) {
    let padded = self.toPadded()
    for line in padded {
      Console.write(line.joined(separator: "\t"), level: level)
    }
  }
}
