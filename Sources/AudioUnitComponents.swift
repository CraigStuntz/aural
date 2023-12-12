import AVFoundation
import Foundation

struct AudioUnitComponents {
  static func components(filter: Filter?) -> [AVAudioUnitComponent] {
    if filter == nil {
      let componentDescription = AudioComponentDescription()
      return AVAudioUnitComponentManager.shared().components(matching: componentDescription)
    }
    return AVAudioUnitComponentManager.shared().components(passingTest: {
      if $1.hashValue == 0 {
        // THis is dumb, but Swift requires you to use all arguments in a predicate.
        // SO we do a do-nothing comparison on $1.
      }
      switch filter!.filterType {
      case .manufacturer:
        return $0.manufacturerName == filter!.name
      case .name:
        return $0.name == filter!.name
      case .type:
        return $0.typeName == filter!.name
      }
    })
  }
}
