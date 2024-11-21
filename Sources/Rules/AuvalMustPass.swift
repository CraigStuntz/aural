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
    // We capture stdout because otherwise auval will fill the screen with non-
    // error output
    let out = Pipe()
    // but if the user has specifically requested verbose output, let 'em have it'
    let captureStdOut = verbosity != .verbose
    if captureStdOut {
      process.standardOutput = out
    }
    // We capture stderr in case auval writes something there, which it won't.
    // But if it did we would display it to the user
    let error = Pipe()
    process.standardError = error
    nonisolated(unsafe) var processError = ""
    process.terminationHandler = { process in
      let errorData = error.fileHandleForReading.readDataToEndOfFile()
      processError = String(data: errorData, encoding: .utf8) ?? ""
    }
    do {
      try process.run()
    } catch {
      return [ruleError("auval failed with error \(error)")]
    }
    if captureStdOut {
      // Must do, otherwise Process can hang on .waitUntilExit() for large output
      out.fileHandleForReading.readDataToEndOfFile()
    }
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
