import AVFoundation

class AuvalMustPass: Rule {
  override func testComponent(component: AVAudioUnitComponent, config: AudioUnitConfig?)
    -> [RuleError]
  {
    let process = Process()
    process.executableURL = URL(filePath: "/usr/bin/auval")
    let componentType = component.audioComponentDescription.componentType.toString()
    let componentSubType = component.audioComponentDescription.componentSubType.toString()
    let componentManufacturer = component.audioComponentDescription.componentManufacturer.toString()
    process.arguments = [
      "-v",
      componentType,
      componentSubType,
      componentManufacturer,
      "-strict",
    ]
    let out = Pipe()
    let error = Pipe()
    process.standardOutput = out
    process.standardError = error
    var processError = ""
    process.terminationHandler = { process in
      let errorData = error.fileHandleForReading.readDataToEndOfFile()
      processError = String(data: errorData, encoding: .utf8) ?? ""
    }
    do {
      try process.run()
    } catch {
      return [ruleError("auval failed with error \(error)")]
    }
    // Must do, otherwise Process can hang on .waitUntilExit() for large output
    out.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
      return [
        ruleError(
          "auval failed; run with /usr/bin/auval -v \(componentType) \(componentSubType) \(componentManufacturer) -strict for more information \(processError)"
        )
      ]
    }
    return []
  }
}
