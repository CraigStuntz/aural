import AVFoundation

struct UpdateAudioUnits {
  static func run(options: Options, integrationTest: Bool, writeConfigFile: Bool) async {
    let components = AudioUnitComponents.components(maybeFilter: options.filter)
    let audioUnitConfigs = AudioUnitConfigs()
    let updateConfigs = UpdateConfigs(
      audioUnitConfigs: audioUnitConfigs,
      components: components,
      integrationTest: integrationTest)
    printNoConfiguration(updateConfigs.noConfiguration)
    if writeConfigFile {
      audioUnitConfigs.writeConfig(components, "AudioUnits.plist")
    }
    if updateConfigs.toUpdate.isEmpty {
      Console.standard("No Audio Units configured for update.")
    } else {
      Console.standard("Requesting current versions from manufacturer's sites...", terminator: "")
      let updateResult = await download(updateConfigs)
      Console.standard()  // Terminate "Requesting current versions..." line
      print(updateResult)
    }
  }

  private static func download(_ updateConfigs: UpdateConfigs) async -> UpdateResult {
    var current: [UpdateUpToDate] = []
    var failures: [String] = []
    var outOfDate: [UpdateNeedsUpdate] = []
    await withTaskGroup(of: [Result<UpdateSuccess, UpdateError>].self) { group in
      let byUrl = Dictionary(
        grouping: updateConfigs.toUpdate,
        by: { updateConfig in updateConfig.audioUnitConfig.versionUrl })
      for updateUrl in byUrl.keys {
        group.addTask {
          await fetchResponseAndCheckVersions(url: updateUrl, updateConfigs: byUrl[updateUrl])
        }
      }
      for await results in group {
        Console.standard(".", terminator: "")
        for result in results {
          switch result {
          case .success(let updateSuccess):
            let latestVersion = updateSuccess.latestVersion ?? "<unknown>"
            let audioUnitConfig = updateSuccess.updateConfig.audioUnitConfig
            if updateSuccess.compatible {
              current.append(
                UpdateUpToDate(updateSuccess: updateSuccess, latestVersion: latestVersion))
            } else {
              outOfDate.append(
                UpdateNeedsUpdate(
                  updateSuccess: updateSuccess, latestVersion: latestVersion,
                  updateInstructions: audioUnitConfig.update))
            }
          case .failure(let updateError):
            failures.append(updateError.description)
          }
        }
      }
    }
    return UpdateResult(current: current, failures: failures, outOfDate: outOfDate)
  }

  private static func fetchResponseAndCheckVersions(url: String?, updateConfigs: [UpdateConfig]?)
    async
    -> [Result<UpdateSuccess, UpdateError>]
  {
    guard let urlString = url else {
      fatalError("Version URL is not assigned.")
    }
    guard let configs = updateConfigs else {
      fatalError("[UpdateConfig] array was not passed in.")
    }
    guard let versionUrl = URL(string: urlString) else {
      return [.failure(.invalidUrl(description: urlString))]
    }
    do {
      let body = try await Http.get(url: versionUrl)
      return configs.map { updateConfig in
        updateConfig.checkCompatibility(responseBody: body)
      }
    } catch {
      return [
        .failure(
          .genericUpdateError(description: "Fetching \(urlString) failed because of \(error)."))
      ]
    }
  }

  private static func print(_ updateResult: UpdateResult) {
    Console.standard()  // insert blank line
    if !updateResult.current.isEmpty && verbosity != .quiet {
      Console.standard("Up to date Audio Units:")
      Table(reflecting: UpdateUpToDate(), data: updateResult.current).printToConsole(
        level: .standard)
    }
    if !(updateResult.current.isEmpty && updateResult.outOfDate.isEmpty) {
      Console.standard()
    }
    if !updateResult.outOfDate.isEmpty {
      Console.standard("Audio Units which need to be updated:")
      Table(reflecting: UpdateNeedsUpdate(), data: updateResult.outOfDate).printToConsole(
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

  private static func printNoConfiguration(_ noConfiguration: [ComponentMetadata]) {
    if !noConfiguration.isEmpty && verbosity != .quiet {
      Table(
        reflecting: UpdateNoConfiguration(),
        data: noConfiguration.map { UpdateNoConfiguration(metadata: $0) }
      )
      .printToConsole()
      Console.standard()
    }
  }
}

struct UpdateConfig: Sendable {
  let metadata: ComponentMetadata
  let audioUnitConfig: AudioUnitConfig

  func checkCompatibility(responseBody: String) -> Result<UpdateSuccess, UpdateError> {
    do {
      guard
        let latestVersion = try Version.parse(
          responseBody: responseBody, audioUnitConfig: self.audioUnitConfig)
      else {
        return .failure(
          .configurationNotFoundInHttpResult(
            description: "Current version of \(self.metadata.name) not found"))
      }
      let compatible = Version.compatible(
        latestVersion: latestVersion, existingVersion: self.metadata.versionString)
      return .success(
        UpdateSuccess(
          metadata: metadata,
          updateConfig: self,
          latestVersion: latestVersion,
          compatible: compatible))
    } catch {
      return .failure(
        .genericUpdateError(
          description:
            "Caught error \(error) while checking the current version of \(self.metadata.name)"
        ))
    }
  }
}

struct UpdateConfigs {
  let noConfiguration: [ComponentMetadata]
  let toUpdate: [UpdateConfig]

  init(
    audioUnitConfigs: AudioUnitConfigs,
    components: [AVAudioUnitComponent],
    integrationTest: Bool
  ) {
    var noConfiguration: [ComponentMetadata] = []
    var toUpdate: [UpdateConfig] = []
    let metadata =
      integrationTest
      ? audioUnitConfigs.configs.map { config in ComponentMetadata(audioUnitConfig: config) }
      : components.map { component in ComponentMetadata(avAudioUnitComponent: component) }
    for metadatum in metadata {
      guard let audioUnitConfig = audioUnitConfigs[metadatum] else {
        noConfiguration.append(metadatum)
        continue
      }
      if audioUnitConfig.system != true {
        if audioUnitConfig.versionUrl != nil
          && audioUnitConfig.versionUrl != ""
        {
          toUpdate.append(
            UpdateConfig(
              metadata: metadatum,
              audioUnitConfig: audioUnitConfig
            ))
        } else {
          noConfiguration.append(metadatum)
        }
      }
    }
    self.noConfiguration = noConfiguration
    self.toUpdate = toUpdate
  }
}

enum UpdateError: Error, CustomStringConvertible {
  case configurationNotFoundInHttpResult(description: String)
  case invalidUrl(description: String)
  case noConfiguration(description: String)
  case noRegexMatch(regex: String)
  case webRequestFailed(description: String)
  case genericUpdateError(description: String)

  public var description: String {
    switch self {
    case .configurationNotFoundInHttpResult(let description): return description
    case .invalidUrl(let description): return "Invalid URL \(description)"
    case .noConfiguration(let description): return description
    case .noRegexMatch(let regex): return "No match for regex \(regex)"
    case .webRequestFailed(let description): return description
    case .genericUpdateError(let description): return description
    }
  }
}

struct UpdateResult {
  let current: [UpdateUpToDate]
  let failures: [String]
  let outOfDate: [UpdateNeedsUpdate]
}

struct UpdateSuccess: Sendable {
  let metadata: ComponentMetadata
  let updateConfig: UpdateConfig
  let latestVersion: String?
  let compatible: Bool
}

// Result types for display in a Table

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

struct UpdateNeedsUpdate: CustomReflectable {
  let manufacturer: String
  let name: String
  let latestVersion: String
  let localVersion: String
  let updateInstructions: String
  let fourLetterCodes: String

  init() {
    manufacturer = ""
    name = ""
    latestVersion = ""
    localVersion = ""
    updateInstructions = ""
    fourLetterCodes = ""
  }

  init(updateSuccess: UpdateSuccess, latestVersion: String, updateInstructions: String?) {
    manufacturer = updateSuccess.metadata.manufacturerName
    name = updateSuccess.metadata.name
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

struct UpdateUpToDate: CustomReflectable {
  let manufacturer: String
  let name: String
  let latestVersion: String
  let localVersion: String
  let fourLetterCodes: String

  init() {
    manufacturer = ""
    name = ""
    latestVersion = ""
    localVersion = ""
    fourLetterCodes = ""
  }

  init(updateSuccess: UpdateSuccess, latestVersion: String) {
    manufacturer = updateSuccess.metadata.manufacturerName
    name = updateSuccess.metadata.name
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
