import AVFoundation

class ComponentRequiredProperties: Rule {
  override func testComponent(component: AVAudioUnitComponent, config: AudioUnitConfig?)
    -> [RuleError]
  {
    var result: [RuleError] = []
    if component.manufacturerName == "" {
      // looking at you, iZotope
      result.append(
        ruleError("The AVAudioUnitComponent.manufacturerName property must be a non-empty string"))
    }
    if component.name == "" {
      result.append(
        ruleError("The AVAudioUnitComponent.name property must be a non-empty string"))
    }
    if component.typeName == "" {
      // looking at you, iZotope
      result.append(
        ruleError("The AVAudioUnitComponent.typeName property must be a non-empty string")
      )
    }
    return result
  }
}
