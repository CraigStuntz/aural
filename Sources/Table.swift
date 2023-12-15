struct Table {
  let maxesByColumn: [Int]
  let data: [[String]]
  let headers: [String]

  init(headers: [String], data: [[String]]) {
    self.data = data
    self.headers = headers
    self.maxesByColumn = Table.maxes(headers, data)
  }

  static func maxes(_ headers: [String], _ data: [[String]]) -> [Int] {
    if data.isEmpty {
      return []
    }
    var result: [Int] = []
    for column in 0..<data[0].count {
      var maxWidth = data.map { $0[column].count }.max()!
      if headers.count > column {
        maxWidth = max(maxWidth, headers[column].count)
      }
      result.append(maxWidth)
    }
    return result
  }

  // returns a Table instance with all headers and data padded ti column widths
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

  func printToConsole() {
    let padded = self.toPadded()
    for line in padded {
      print(line.joined(separator: "\t"))
    }
  }
}
