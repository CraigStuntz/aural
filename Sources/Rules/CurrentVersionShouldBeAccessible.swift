import AVFoundation

class CurrentVersionShouldBeAccessible: Rule {
  override func testComponent(component: AVAudioUnitComponent, config: AudioUnitConfig?)
    -> [RuleError]
  {
    let updateConfigs = AudioUnitConfigs()
    let updateConfig = updateConfigs.toConfig(component)
    if updateConfig.versionUrl == nil {
      return [
        ruleWarning(
          "No publicly accessible web page for retrieving the component's current version is known")
      ]
    }
    return []
  }
}
