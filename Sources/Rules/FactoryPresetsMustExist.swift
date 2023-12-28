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
    let isTypeThatShouldContainPresets = [
      kAudioUnitType_Effect,
      kAudioUnitType_MusicDevice,
      kAudioUnitType_MusicEffect,
    ].contains(component.audioComponentDescription.componentType)
    // Apple's "System" AUs have no factory presets nor any aility to save
    // user presets. So just ignore them.
    // There may be a more precise tests I could use, but every commercial
    // AU I've tried has factory presets, so this is OK for now.
    let isSystem = config?.system == true
    return isTypeThatShouldContainPresets && !isSystem
  }
}
