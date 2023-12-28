import AVFoundation

class Rule {
  final func ruleError(_ message: String) -> RuleError {
    return .error(description: "ERROR: \(message)")
  }

  final func ruleWarning(_ message: String) -> RuleError {
    return .warning(description: "WARNING: \(message)")
  }

  final func run(component: AVAudioUnitComponent, audioUnit: AUAudioUnit?, config: AudioUnitConfig?)
    -> [RuleError]
  {
    guard shouldTest(component: component, config: config) else {
      return []
    }
    var result = testComponent(component: component, config: config)
    guard let audioUnit = audioUnit else {
      return result
    }
    result.append(contentsOf: testAudioUnit(audioUnit: audioUnit, config: config))
    return result
  }

  static let auvw = "auvw".toFourCharCode()

  static func shouldLoadAudioUnit(component: AVAudioUnitComponent) -> Bool {
    // loading Cherry Audio Synthesizer Expander Module View (Unknown) fails with
    // "Error Domain=NSOSStatusErrorDomain Code=-50
    // "paramErr: error in user parameter list" (auval also fails similarly)
    // and that's fine. I don't think there's a meaningful test I can do on such
    // an Audio Unit?
    return component.audioComponentDescription.componentType != auvw
  }

  func shouldTest(component: AVAudioUnitComponent, config: AudioUnitConfig?) -> Bool {
    return true
  }

  func testAudioUnit(audioUnit: AUAudioUnit, config: AudioUnitConfig?) -> [RuleError] {
    return []
  }

  func testComponent(component: AVAudioUnitComponent, config: AudioUnitConfig?) -> [RuleError] {
    return []
  }
}

enum RuleError: Error, CustomStringConvertible {
  case error(description: String)
  case warning(description: String)

  public var description: String {
    switch self {
    case .error(let description): return description
    case .warning(let description): return description
    }
  }
}
