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
      print("Unknown rule '\(rule ?? "")'")
      throw ExitCode.failure
    }
    let ruleDescription = rule == nil ? "using all rules" : "rule = \(rule ?? "")"
    print("Validating \(components.count) components, \(ruleDescription)...")
    for component in components {
      let ruleErrors = await runValidationFor(component, configs[component], rules)
      if ruleErrors.isEmpty {
        print(" (no errors)")
      } else {
        print()
      }
      for ruleError in ruleErrors {
        print("  \(ruleError.description)")
      }
    }
  }

  private static func runValidationFor(
    _ component: AVAudioUnitComponent,
    _ config: AudioUnitConfig?,
    _ rules: [Rule]
  ) async -> [RuleError] {
    var ruleErrors: [RuleError] = []
    print(
      "\(component.manufacturerName) \(component.name) (\(component.typeName)):", terminator: "")
    // otherwise Swift won't flush the handle -- screen won't be updated
    // until newline
    fflush(stdout)
    var auAudioUnit: AUAudioUnit? = nil
    do {
      if Rule.shouldLoadAudioUnit(component: component) {
        auAudioUnit = try await AUAudioUnit.instantiate(
          with: component.audioComponentDescription)
      }
      for rule in rules {
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
