import AVFoundation
import Foundation

struct AudioUnitComponents {
  static func components(maybeFilter: Filter?) -> [AVAudioUnitComponent] {
    guard let filter = maybeFilter else {
      let componentDescription = AudioComponentDescription()
      return AVAudioUnitComponentManager.shared().components(matching: componentDescription).sorted(
        by: audioUnitMetadataIsLessThan)
    }
    return AVAudioUnitComponentManager.shared().components(passingTest: { (component, _) in
      switch filter.filterType {
      case .manufacturer:
        return component.manufacturerName == filter.name
      case .name:
        return component.name == filter.name
      case .type:
        return component.typeName == filter.name
      }
    }).sorted(by: audioUnitMetadataIsLessThan)
  }
}
