import AVFoundation
import AudioToolbox

class FactoryPresetsMustExist: Rule {
  override func testAudioUnit(audioUnit: AUAudioUnit, config: AudioUnitConfig?) -> [RuleError] {
    guard let factoryPresets = audioUnit.factoryPresets else {
      return [ruleError("AUAudioUnit.factoryPresets is nil")]
    }
    if factoryPresets.isEmpty {
      return [ruleError("AUAudioUnit.factoryPresets is empty")]
    }
    if factoryPresets.count < 5 {
      return [ruleError("AUAudioUnit.factoryPresets is kinda sus")]
    }
    return []
  }

  override func shouldTest(component: AVAudioUnitComponent, config: AudioUnitConfig?) -> Bool {
    return Rule.isTypeThatShouldContainFactoryPresets(component: component, config: config)
  }
}
