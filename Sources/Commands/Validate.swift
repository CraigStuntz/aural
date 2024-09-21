import AVFoundation
import ArgumentParser

struct ValidateAudioUnits {
  static let allRules: [Rule] = [
    AuvalMustPass(),
    ComponentRequiredProperties(),
    FactoryPresetsMustExist(),
    PresetStateMustWork(),
  ]

  static let allRuleNames: [String] = allRules.map { $0.ruleName }

  static func rules(_ rule: String?) -> [Rule] {
    guard let name = rule else {
      return allRules
    }
    return allRules.filter {
      $0.ruleName.caseInsensitiveCompare(name) == ComparisonResult.orderedSame
    }
  }

  static func run(options: Options, rule: String?) async throws {
    let configs = AudioUnitConfigs()
    let components = AudioUnitComponents.components(maybeFilter: options.filter)
    let rules = rules(rule)
    guard rules.count > 0 else {
      Console.error("Unknown rule '\(rule ?? "")'")
      throw ExitCode.failure
    }
    let ruleDescription = rule == nil ? "using all rules" : "rule = \(rule ?? "")"
    Console.standard("Validating \(components.count) components, \(ruleDescription)...")
    for component in components {
      let ruleErrors = await runValidationFor(component, configs[component], rules)
      if ruleErrors.isEmpty {
        Console.standard(" (no errors)")
      } else {
        Console.standard()
      }
      for ruleError in ruleErrors {
        switch ruleError {
        case .warning(let description): Console.warning("  \(description)")
        case .error(let description): Console.error("  \(description)")
        }
      }
    }
  }

  private static func runValidationFor(
    _ component: AVAudioUnitComponent,
    _ config: AudioUnitConfig?,
    _ rules: [Rule]
  ) async -> [RuleError] {
    var ruleErrors: [RuleError] = []
    Console.standard(
      "\(component.manufacturerName) \(component.name) (\(component.typeName)):", terminator: "")
    // otherwise Swift won't flush the handle -- screen won't be updated
    // until newline
    fflush(stdout)
    var auAudioUnit: AUAudioUnit? = nil
    do {
      if Rule.shouldLoadAudioUnit(component: component) {
        Console.standard("Loading...")
        Console.standard(component.audioComponentDescription)
        auAudioUnit = try await AUAudioUnit.instantiate(
          with: component.audioComponentDescription)
        Console.standard("Loaded.")
      }
      for rule in rules {
        Console.standard(rule.ruleName)
        ruleErrors.append(
          contentsOf: rule.run(
            component: component, audioUnit: auAudioUnit, config: config))
      }
    } catch {
      fatalError(
        "Failed to load Audio Unit \(component.manufacturerName) \(component.name) because of error \(error)"
      )
    }
    return ruleErrors
  }
}
