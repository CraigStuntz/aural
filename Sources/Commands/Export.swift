import AVFoundation

struct ExportAudioUnits {
  static func logic(options: Options) async {
    print("Export!")
    let configs = AudioUnitConfigs()
    let components = AudioUnitComponents.components(maybeFilter: options.filter)
    for component in components where !skipForExport(component: component, configs: configs) {
      await logicExportComponent(component: component)
    }
  }

  static func logicExportComponent(component: AVAudioUnitComponent) async {
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

  static let auvw = "auvw".toFourCharCode()

  static func skipForExport(component: AVAudioUnitComponent, configs: AudioUnitConfigs) -> Bool {
    if let config = configs[component] {
      if config.system == true {
        return true
      }
    }
    // Cherry Audio uses 'auvw' on "Synthesizer Expander Module View"
    // This can't be loaded and isn't an actual
    return component.audioComponentDescription.componentType == auvw
  }
}
