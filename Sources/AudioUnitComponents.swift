import AVFoundation
import Foundation

struct AudioUnitComponents {
  static func components(filter: Filter?) -> [AVAudioUnitComponent] {
    if filter == nil {
      let componentDescription = AudioComponentDescription()
      return AVAudioUnitComponentManager.shared().components(matching: componentDescription).sorted(
        by: AudioUnitComponents.isLessThan)
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
    }).sorted(by: AudioUnitComponents.isLessThan)
  }

  static func isLessThan(_ c1: AVAudioUnitComponent, _ c2: AVAudioUnitComponent) -> Bool {
    return (c1.manufacturerName.caseInsensitiveCompare(c2.manufacturerName) == .orderedAscending)
      || (c1.manufacturerName.caseInsensitiveCompare(c2.manufacturerName) == .orderedSame
        && c1.name.caseInsensitiveCompare(c2.name) == .orderedAscending)
      || (c1.manufacturerName.caseInsensitiveCompare(c2.manufacturerName) == .orderedSame
        && c1.name.caseInsensitiveCompare(c2.name) == .orderedSame
        && c1.typeName.caseInsensitiveCompare(c2.typeName) == .orderedAscending)
  }

  static func isSystemComponent(_ component: AVAudioUnitComponent) -> Bool {
    if ["Apple", "Legacy", "MacinTalk"].contains(component.manufacturerName) {
      return true
    }
    if component.manufacturerName == "Eloquence" && component.name == "KonaSynthesizer" {
      return true
    }
    return false
  }
}
