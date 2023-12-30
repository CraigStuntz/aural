import AVFoundation
import Foundation

let defaultExportPath = "Audio Music Apps/Patches/Instrument/_Instruments"

struct ExportAudioUnits {
  static func logic(options: Options) async {
    let exportURL: URL = .musicDirectory.appending(
      path: "Audio Music Apps/Patches/Instrument/_Instruments")
    print("Exporting to \(exportURL.path())")
    let configs = AudioUnitConfigs()
    let components = AudioUnitComponents.components(maybeFilter: options.filter)
    for component in components where !skipForExport(component: component, configs: configs) {
      await logicExportComponent(component: component, exportURL: exportURL)
    }
  }

  static func logicExportComponent(component: AVAudioUnitComponent, exportURL: URL) async {
    print("\(component.manufacturerName) \(component.name):")
    let location = NSString.path(withComponents: [component.manufacturerName, component.name])
    let url = exportURL.appending(path: location)
    do {
      try FileManager.default.createDirectory(
        at: url, withIntermediateDirectories: true, attributes: nil)
    } catch {
      fatalError("Could not create directory at \(location) because of \(error)")
    }
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
      guard let state = auAudioUnit.fullState else {
        print("No state")
        return
      }
      print(
        state.isEmpty ? "    State is empty" : "    First key of state: \(state.keys.first ?? "")")
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
