import ArgumentParser
import Foundation

enum FilterType: String {
  case manufacturer
  case name
  case type
}

struct Filter: ExpressibleByArgument {
  let filterType: FilterType
  let name: String

  init(filterType: FilterType, name: String) {
    self.filterType = filterType
    self.name = name
  }

  init?(argument: String) {
    let parsed = Filter.parseArgument(argument)
    if let (filterType, name) = parsed {
      self.init(filterType: filterType, name: name)
    } else {
      return nil
    }
  }

  static func parseArgument(_ filter: String) -> (FilterType, String)? {
    let parts = filter.split(whereSeparator: { $0 == ":" }).map(String.init)
    guard parts.count == 2 else {
      return nil
    }
    let type = parts[0]
    let value = parts[1]
    guard let filterType = FilterType.init(rawValue: type) else {
      return nil
    }
    return (filterType, value.trimmingCharacters(in: CharacterSet.whitespaces))
  }
}
