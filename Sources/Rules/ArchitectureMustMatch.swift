import AVFoundation
import AudioToolbox
import Foundation

class ArchitectureMustMatch: Rule {
  static let currentArchitecture = getCurrentArchitecture()

  override func testComponent(component: AVAudioUnitComponent, config: AudioUnitConfig?)
    -> [RuleError]
  {
    let errors = checkArchitectureCompatibility(for: component)
    return errors.map { error in .error(description: error) }
  }

  func checkArchitectureCompatibility(for component: AVAudioUnitComponent) -> [String] {
    var errors: [String] = []
    var componentDescription = component.audioComponentDescription
    guard let component = AudioComponentFindNext(nil, &componentDescription) else {
      errors.append("Cannot find matching audio component")
      return errors
    }
    var configInfo: Unmanaged<CFDictionary>?
    let status = AudioComponentCopyConfigurationInfo(component, &configInfo)
    guard status == noErr else {
      errors.append("Cannot retrieve component configuration")
      return errors
    }
    guard let configDict = configInfo?.takeRetainedValue() as? [String: Any] else {
      errors.append("Invalid component configuration")
      return errors
    }
    guard
      let architectures = configDict[kAudioUnitConfigurationInfo_AvailableArchitectures]
        as? [String]
    else {
      errors.append("Cannot retrieve component supported architectures")
      errors.append("Available keys: \(Array(configDict.keys))")
      return errors
    }

    if !containsHostNativeArchitecture(architectures) {
      let errorMessage =
        "Component does not support current host architecture (\(ArchitectureMustMatch.currentArchitecture)). Supported: \(architectures.joined(separator: ", "))"
      errors.append(errorMessage)
    }

    return errors
  }

  private func containsHostNativeArchitecture(_ architectures: [String]) -> Bool {
    let currentArchitectureIsARM64 = ArchitectureMustMatch.currentArchitecture.starts(with: "arm64")
    return architectures.contains { architecture in
      if currentArchitectureIsARM64 && architecture.starts(with: "arm64") {
        return true
      }
      return architecture == ArchitectureMustMatch.currentArchitecture
    }
  }

  private static func getCurrentArchitecture() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)

    let machine = withUnsafePointer(to: &systemInfo.machine) {
      $0.withMemoryRebound(to: CChar.self, capacity: 1) {
        String.init(validatingCString: $0)
      }
    }

    return machine ?? "unknown"
  }
}
