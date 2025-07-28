import AVFoundation
import ArgumentParser

struct ValidateAudioUnits {
  let allRules: [Rule] = [
    ArchitectureMustMatch(),
    AuvalMustPass(),
    ComponentRequiredProperties(),
    CurrentVersionShouldBeAccessible(),
    FactoryPresetsMustExist(),
    PresetStateMustWork(),
  ]

  func allRuleNames() -> [String] {
    return allRules.map { $0.ruleName }
  }

  func rules(_ rule: String?) -> [Rule] {
    guard let name = rule else {
      return allRules
    }
    return allRules.filter {
      $0.ruleName.caseInsensitiveCompare(name) == ComparisonResult.orderedSame
    }
  }

  func run(
    options: Options,
    rule: String?,
    validateWriter: ValidateWriter
  ) async throws {
    let configs = AudioUnitConfigs()
    let components = AudioUnitComponents.components(maybeFilter: options.filter)
    let rules = rules(rule)
    guard rules.count > 0 else {
      validateWriter.error("Unknown rule '\(rule ?? "")'")
      throw ExitCode.failure
    }
    let ruleDescription = rule == nil ? "using all rules" : "rule = \(rule ?? "")"
    validateWriter.standard(
      "Validating \(components.count) components, \(ruleDescription)... ", terminator: "")
    for component in components {
      let ruleErrors = await runValidationFor(component, configs[component], rules, validateWriter)
      if ruleErrors.isEmpty {
        validateWriter.verbose(" (no errors)")
      }
      for ruleError in ruleErrors {
        switch ruleError {
        case .warning(let description): validateWriter.warning("    \(description)")
        case .error(let description): validateWriter.error("    \(description)")
        }
      }
    }
  }

  private func runValidationFor(
    _ component: AVAudioUnitComponent,
    _ config: AudioUnitConfig?,
    _ rules: [Rule],
    _ validateWriter: ValidateWriter
  ) async -> [RuleError] {
    var ruleErrors: [RuleError] = []
    validateWriter.standard(
      "\(component.manufacturerName) \(component.name) (\(component.typeName)): ", terminator: "")
    // otherwise Swift won't flush the handle -- screen won't be updated
    // until newline
    fflush(stdout)
    var auAudioUnit: AUAudioUnit? = nil
    do {
      if Rule.shouldLoadAudioUnit(component: component) {
        validateWriter.verbose("Loading... ", terminator: "")
        validateWriter.verbose("\(component.audioComponentDescription) ", terminator: "")
        auAudioUnit = try await AUAudioUnit.instantiate(
          with: component.audioComponentDescription)
        validateWriter.verbose("loaded. ", terminator: "")
      }
      validateWriter.standard("")
      for rule in rules {
        validateWriter.standard("  \(rule.ruleName)")
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
