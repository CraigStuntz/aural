protocol UpdateWriter {
  func print(_ updateResult: UpdateResult)
  func printNoConfiguration(_ noConfiguration: [ComponentMetadata])
  func standard(_ items: Any..., separator: String, terminator: String)
}

extension UpdateWriter {
  func standard() {
    standard([], separator: " ", terminator: "\n")
  }
  func standard(_ items: Any...) {
    standard(items, separator: " ", terminator: "\n")
  }
  func standard(_ items: Any..., terminator: String) {
    standard(items, separator: " ", terminator: terminator)
  }
}

struct ConsoleUpdateWriter: UpdateWriter {
  func print(_ updateResult: UpdateResult) {
    Console.standard()  // insert blank line
    if !updateResult.current.isEmpty && verbosity != .quiet {
      Console.standard("Up to date Audio Units:")
      Table(
        reflecting: UpdateUpToDate(),
        data: updateResult.current.sorted(by: audioUnitMetadataIsLessThan)
      ).printToConsole(
        level: .standard)
    }
    if !(updateResult.current.isEmpty && updateResult.outOfDate.isEmpty) {
      Console.standard()
    }
    if !updateResult.outOfDate.isEmpty {
      Console.standard("Audio Units which need to be updated:")
      Table(
        reflecting: UpdateNeedsUpdate(),
        data: updateResult.outOfDate.sorted(by: audioUnitMetadataIsLessThan)
      ).printToConsole(
        level: .standard)
    }
    if !updateResult.outOfDate.isEmpty && !updateResult.failures.isEmpty {
      Console.standard()
    }
    if !updateResult.failures.isEmpty {
      Console.error("Errors encountered during update:")
      let data = updateResult.failures.map { description in [description] }
      Table(headers: [], data: data).printToConsole()
    }
  }

  func printNoConfiguration(_ noConfiguration: [ComponentMetadata]) {
    if !noConfiguration.isEmpty && verbosity != .quiet {
      Table(
        reflecting: UpdateNoConfiguration(),
        data: noConfiguration.map { UpdateNoConfiguration(metadata: $0) }
      )
      .printToConsole()
      Console.standard()
    }
  }

  func standard(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    Console.standard(items, separator: separator, terminator: terminator)
  }
}

struct UpdateNoConfiguration: CustomReflectable {
  let componentDescription: String
  let fourLetterCodes: String

  init() {
    componentDescription = ""
    fourLetterCodes = ""
  }

  init(metadata: ComponentMetadata) {
    componentDescription =
      "\(metadata.manufacturerName) \(metadata.name) (\(metadata.versionString))"
    fourLetterCodes = ComponentMetadata.audioComponentDescriptionToFourLetterCodes(
      metadata.audioComponentDescription)
  }

  var customMirror: Mirror {
    var children: [Mirror.Child] = [
      ("No update configurations found for:", componentDescription)
    ]
    if verbosity == .verbose {
      children.append(("type subt mnfr", fourLetterCodes))
    }
    return Mirror(self, children: children)
  }
}

struct UpdateNeedsUpdate: AudioUnitMetadata, CustomReflectable {
  let manufacturer: String
  let name: String
  let type: String
  let latestVersion: String
  let localVersion: String
  let updateInstructions: String
  let fourLetterCodes: String

  init() {
    manufacturer = ""
    name = ""
    type = ""
    latestVersion = ""
    localVersion = ""
    updateInstructions = ""
    fourLetterCodes = ""
  }

  init(updateSuccess: UpdateSuccess, latestVersion: String, updateInstructions: String?) {
    manufacturer = updateSuccess.metadata.manufacturerName
    name = updateSuccess.metadata.name
    type = updateSuccess.metadata.typeName
    self.latestVersion = latestVersion
    localVersion = updateSuccess.updateConfig.metadata.versionString
    self.updateInstructions = updateInstructions ?? ""
    fourLetterCodes = ComponentMetadata.audioComponentDescriptionToFourLetterCodes(
      updateSuccess.metadata.audioComponentDescription
    )
  }

  var customMirror: Mirror {
    var children: [Mirror.Child] = [
      ("manufacturer", manufacturer),
      ("name", name),
      ("latest version", latestVersion),
      ("local version", localVersion),
      ("update instructions", updateInstructions),
    ]
    if verbosity == .verbose {
      children.append(("type subt mnfr", fourLetterCodes))
    }
    return Mirror(self, children: children)
  }
}

struct UpdateUpToDate: AudioUnitMetadata, CustomReflectable {
  let manufacturer: String
  let name: String
  let type: String
  let latestVersion: String
  let localVersion: String
  let fourLetterCodes: String

  init() {
    manufacturer = ""
    name = ""
    type = ""
    latestVersion = ""
    localVersion = ""
    fourLetterCodes = ""
  }

  init(updateSuccess: UpdateSuccess, latestVersion: String) {
    manufacturer = updateSuccess.metadata.manufacturerName
    name = updateSuccess.metadata.name
    type = updateSuccess.metadata.typeName
    self.latestVersion = latestVersion
    localVersion = updateSuccess.updateConfig.metadata.versionString
    fourLetterCodes = ComponentMetadata.audioComponentDescriptionToFourLetterCodes(
      updateSuccess.metadata.audioComponentDescription
    )
  }

  var customMirror: Mirror {
    var children: [Mirror.Child] = [
      ("manufacturer", manufacturer),
      ("name", name),
      ("latest version", latestVersion),
      ("local version", localVersion),
    ]
    if verbosity == .verbose {
      children.append(("type subt mnfr", fourLetterCodes))
    }
    return Mirror(self, children: children)
  }
}
