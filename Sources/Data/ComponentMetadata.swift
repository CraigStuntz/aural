import AVFoundation

struct ComponentMetadata: CustomReflectable, Sendable {
  let name: String
  let manufacturerName: String
  let typeName: String
  let audioComponentDescription: AudioComponentDescription
  let versionString: String

  var customMirror: Mirror {
    var children: [Mirror.Child] = [
      ("manufacturer", manufacturerName),
      ("name", name),
      ("type", typeName),
      ("version", versionString),
    ]
    if verbosity == .verbose {
      children.append(
        (
          "type subt mnfr",
          ComponentMetadata.audioComponentDescriptionToFourLetterCodes(audioComponentDescription)
        ))
    }
    return Mirror(self, children: children)
  }

  /// This initializer mostly exists to get property names for displaing in the Table
  init() {
    name = ""
    manufacturerName = ""
    typeName = ""
    audioComponentDescription = AudioComponentDescription()
    versionString = ""
  }

  init(avAudioUnitComponent: AVAudioUnitComponent) {
    self.name = avAudioUnitComponent.name
    self.manufacturerName = avAudioUnitComponent.manufacturerName
    self.typeName = avAudioUnitComponent.typeName
    self.audioComponentDescription = avAudioUnitComponent.audioComponentDescription
    self.versionString = avAudioUnitComponent.versionString
  }

  static func audioComponentDescriptionToFourLetterCodes(
    _ audioComponentDescription: AudioComponentDescription
  ) -> String {
    return
      "\(audioComponentDescription.componentType.toString()) \(audioComponentDescription.componentSubType.toString()) \(audioComponentDescription.componentManufacturer.toString())"
  }
}
