import AVFoundation

struct UpdateAudioUnits {
  static func run(
    options: Options,
    integrationTest: Bool,
    updateWriter: UpdateWriter,
    writeConfigFile: Bool
  ) async {
    let components = AudioUnitComponents.components(maybeFilter: options.filter)
    let audioUnitConfigs = AudioUnitConfigs()
    let updateConfigs = UpdateConfigs(
      audioUnitConfigs: audioUnitConfigs,
      components: components,
      integrationTest: integrationTest)
    updateWriter.printNoConfiguration(updateConfigs.noConfiguration)
    if writeConfigFile {
      audioUnitConfigs.writeConfig(components, "AudioUnits.plist")
    }
    if updateConfigs.toUpdate.isEmpty {
      updateWriter.standard("No Audio Units configured for update.")
    } else {
      updateWriter.standard(
        "Requesting current versions from manufacturer's sites...", terminator: "")
      let updateResult = await download(updateConfigs, updateWriter)
      updateWriter.standard()  // Terminate "Requesting current versions..." line
      updateWriter.print(updateResult)
    }
  }

  private static func download(_ updateConfigs: UpdateConfigs, _ updateWriter: UpdateWriter) async
    -> UpdateResult
  {
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
        updateWriter.standard(".", terminator: "")
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
      let httpResult = try await Http.get(url: versionUrl)
      return switch httpResult {
      case .success(let body):
        configs.map { updateConfig in
          updateConfig.checkCompatibility(responseBody: body)
        }
      case .failure(let error): [.failure(.webRequestFailed(description: error.description))]
      }
    } catch {
      return [
        .failure(
          .genericUpdateError(description: "Fetching \(urlString) failed because of \(error)."))
      ]
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
