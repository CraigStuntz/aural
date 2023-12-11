import ArgumentParser
import Foundation

enum FilterType: String {
  case manufacturer
  case subtype
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
    if parts.count == 2 {
      let filterType = FilterType.init(rawValue: parts.first!)
      if filterType != nil {
        return (filterType!, parts.last!.trimmingCharacters(in: CharacterSet.whitespaces))
      }
    }
    return nil
  }
}
