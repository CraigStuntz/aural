import AVFoundation
import AudioToolbox

class PresetStateMustWork: Rule {
  override func testAudioUnit(audioUnit: AUAudioUnit, config: AudioUnitConfig?) -> [RuleError] {
    guard let factoryPresets = audioUnit.factoryPresets, factoryPresets.count > 0 else {
      return [ruleError("No factory presets found for testing")]
    }
    let preset = factoryPresets[0]
    do {
      try audioUnit.presetState(for: preset)
    } catch {
      return [
        ruleError(
          "Attempting to retrieve preset state of \(preset.name) threw error \"\(error.localizedDescription)\""
        )
      ]
    }
    return []
  }

  override func shouldTest(component: AVAudioUnitComponent, config: AudioUnitConfig?) -> Bool {
    return Rule.isTypeThatShouldContainFactoryPresets(component: component, config: config)
  }
}
