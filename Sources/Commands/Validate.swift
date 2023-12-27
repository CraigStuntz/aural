import AVFoundation

let allRules: [Rule] = [
  AuvalMustPass(),
  ComponentRequiredProperties(),
  FactoryPresetsMustExist(),
]

struct ValidateAudioUnits {
  static func run(options: Options) async {
    let configs = AudioUnitConfigs()
    let components = AudioUnitComponents.components(maybeFilter: options.filter)
    print("Validating \(components.count) components...")
    for component in components {
      var results: [RuleError] = []
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
        for rule in allRules {
          results.append(
            contentsOf: rule.run(
              component: component, audioUnit: auAudioUnit, config: configs[component]))
        }
      } catch {
        fatalError(
          "Failed to load Audio Unit \(component.manufacturerName) \(component.name) because of error \(error)"
        )
      }
      if results.isEmpty {
        print(" (no errors)")
      } else {
        print()
      }
      for result in results {
        print("  \(result.description)")
      }
    }
  }
}
