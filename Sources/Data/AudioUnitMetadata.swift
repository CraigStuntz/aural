import AVFoundation

protocol AudioUnitMetadata {
  var manufacturer: String { get }
  var name: String { get }
  var type: String { get }
}

func audioUnitMetadataIsLessThan(_ c1: AudioUnitMetadata, _ c2: AudioUnitMetadata) -> Bool {
  return (c1.manufacturer.caseInsensitiveCompare(c2.manufacturer) == .orderedAscending)
    || (c1.manufacturer.caseInsensitiveCompare(c2.manufacturer) == .orderedSame
      && c1.name.caseInsensitiveCompare(c2.name) == .orderedAscending)
    || (c1.manufacturer.caseInsensitiveCompare(c2.manufacturer) == .orderedSame
      && c1.name.caseInsensitiveCompare(c2.name) == .orderedSame
      && c1.type.caseInsensitiveCompare(c2.type) == .orderedAscending)
}

extension AVAudioUnitComponent: AudioUnitMetadata {
  var manufacturer: String {
    return manufacturerName
  }

  var type: String {
    return typeName
  }
}
