import AVFoundation

class ComponentRequiredProperties: Rule {
  override func testComponent(component: AVAudioUnitComponent, config: AudioUnitConfig?)
    -> [RuleError]
  {
    var result: [RuleError] = []
    if component.localizedTypeName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == ""
    {
      result.append(
        ruleError("The AVAudioUnitComponent.localizedTypeName property must be a non-empty string"))
    }
    if component.manufacturerName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == ""
    {
      // looking at you, iZotope
      result.append(
        ruleError("The AVAudioUnitComponent.manufacturerName property must be a non-empty string"))
    }
    if component.name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "" {
      result.append(
        ruleError("The AVAudioUnitComponent.name property must be a non-empty string"))
    }
    if component.typeName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "" {
      // looking at you, iZotope
      result.append(
        ruleError("The AVAudioUnitComponent.typeName property must be a non-empty string")
      )
    }
    if component.allTagNames.isEmpty {
      result.append(
        ruleWarning("The AVAudioUnitComponent.allTagNames property should not be empty")
      )
    }
    return result
  }
}
