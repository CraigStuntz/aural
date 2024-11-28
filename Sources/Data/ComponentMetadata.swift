import AVFoundation

struct ComponentMetadata: Sendable {
  let name: String
  let manufacturerName: String
  let versionString: String

  init(avAudioUnitComponent: AVAudioUnitComponent) {
    self.name = avAudioUnitComponent.name
    self.manufacturerName = avAudioUnitComponent.manufacturerName
    self.versionString = avAudioUnitComponent.versionString
  }
}
