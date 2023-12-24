import AVFoundation

struct ExportAudioUnits {
  static func logic(options: Options) async {
    print("Export!")
    let components = AudioUnitComponents.components(maybeFilter: options.filter)
    for component in components where !skipForExport(component: component) {
      print("\(component.manufacturerName) \(component.name):")
      do {
        let auAudioUnit = try await AUAudioUnit.instantiate(
          with: component.audioComponentDescription)
        if let factoryPresets = auAudioUnit.factoryPresets {
          if !factoryPresets.isEmpty {
            print("  factory presets:")
            for preset in factoryPresets {
              print("    \(preset.number) \(preset.name)")
            }
          }
        }
        if !auAudioUnit.userPresets.isEmpty {
          print("  user presets:")
          for preset in auAudioUnit.userPresets {
            print("    \(preset.number) \(preset.name)")
          }
        }
      } catch {
        fatalError(
          "Failed to load Audio Unit \(component.manufacturerName) \(component.name) because of error \(error)"
        )
      }
    }
  }

  static func skipForExport(component: AVAudioUnitComponent) -> Bool {
    return component.typeName == "Unknown"
  }
}
