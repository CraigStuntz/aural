import AVFoundation

struct UpdateConfig {
  let existingVersion: String
  let config: AudioUnitConfig
}

struct UpdateConfigs {
  let noConfiguration: [String]
  let toUpdate: [UpdateConfig]

  init(configs: AudioUnitConfigs, components: [AVAudioUnitComponent]) {
    var noConfiguration: [String] = []
    var toUpdate: [UpdateConfig] = []
    let nonSystemComponents = components.filter({ !UpdateConfigs.isSystemComponent(component: $0) })
    for component in nonSystemComponents {
      let config = configs[component]
      if config != nil {
        toUpdate.append(
          UpdateConfig(
            existingVersion: component.versionString,
            config: config!
          ))
      } else {
        noConfiguration.append(
          "\(component.manufacturerName) \(component.name) (\(component.versionString))")
      }
    }
    self.noConfiguration = noConfiguration
    self.toUpdate = toUpdate
  }

  static func isSystemComponent(component: AVAudioUnitComponent) -> Bool {
    if ["Apple", "Legacy", "MacinTalk"].contains(component.manufacturerName) {
      return true
    }
    if component.manufacturerName == "Eloquence" && component.name == "KonaSynthesizer" {
      return true
    }
    return false
  }
}
