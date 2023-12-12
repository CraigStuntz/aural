import AVFoundation
import Foundation

struct AudioUnitComponents {
  static func components(filter: Filter?) -> [AVAudioUnitComponent] {
    if filter == nil {
      let componentDescription = AudioComponentDescription()
      return AVAudioUnitComponentManager.shared().components(matching: componentDescription)
    }
    return AVAudioUnitComponentManager.shared().components(passingTest: { (component, _) in
      switch filter!.filterType {
      case .manufacturer:
        return component.manufacturerName == filter!.name
      case .name:
        return component.name == filter!.name
      case .type:
        return component.typeName == filter!.name
      }
    })
  }
}
