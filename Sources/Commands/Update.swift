import AVFoundation

struct UpdateAudioUnits {
  static func run(options: Options) async {
    let components = AudioUnitComponents.components(filter: options.filter)
    let audioUnitConfigs = AudioUnitConfigs()
    let updateConfigs = UpdateConfigs(audioUnitConfigs: audioUnitConfigs, components: components)
    if !updateConfigs.noConfiguration.isEmpty {
      let noConfigsData = updateConfigs.noConfiguration.map { [$0] }
      Table(headers: ["No update configurations found for:"], data: noConfigsData).printToConsole()
      print()
    }
    if updateConfigs.toUpdate.isEmpty {
      print("No Audio Units configured for update.")
    } else {
      print("Requesting current versions from manufacturer's sites...", terminator: "")
      // otherwise Swift won't flush the handle -- screen won't be updated
      // until newline
      fflush(stdout)
      var current: [[String]] = []
      var failures: [[String]] = []
      var outOfDate: [[String]] = []
      await withTaskGroup(of: Result<UpdateSuccess, UpdateError>.self) { group in
        for updateConfig in updateConfigs.toUpdate {
          group.addTask { await updateConfig.requestCurrentVersion() }
        }
        for await result in group {
          print(".", terminator: "")
          // otherwise Swift won't flush the handle -- screen won't be updated
          // until newline
          fflush(stdout)
          switch result {
          case .success(let updateSuccess):
            let currentVersion = updateSuccess.currentVersion ?? "<unknown>"
            let audioUnitConfig = updateSuccess.updateConfig.audioUnitConfig
            if updateSuccess.compatible {
              current.append([
                audioUnitConfig.manufacturer,
                audioUnitConfig.name,
                currentVersion,
                updateSuccess.updateConfig.existingVersion,
              ])
            } else {
              outOfDate.append([
                audioUnitConfig.manufacturer,
                audioUnitConfig.name,
                currentVersion,
                updateSuccess.updateConfig.existingVersion,
                audioUnitConfig.update ?? "",
              ])
            }
          case .failure(let updateError):
            failures.append([
              updateError.description
            ])
          }
        }
      }

      print()  // Terminate "Requesting current versions..." line
      print()  // insert blank line
      if !current.isEmpty {
        print("Up to date Audio Units:")
        Table(
          headers: ["manufacturer", "name", "latest version", "local version"],
          data: current
        ).printToConsole()
      }
      if !outOfDate.isEmpty {
        print("Audio Units which need to be updated:")
        Table(
          headers: [
            "manufacturer", "name", "latest version", "local version", "update instructions",
          ],
          data: outOfDate
        ).printToConsole()
      }
      if !outOfDate.isEmpty && !outOfDate.isEmpty {
        print()
      }
      if !failures.isEmpty {
        print("Errors encountered during update:")
        Table(headers: [], data: failures).printToConsole()
      }
    }
  }
}

struct UpdateConfig {
  let existingVersion: String
  let audioUnitConfig: AudioUnitConfig

  func requestCurrentVersion() async -> Result<UpdateSuccess, UpdateError> {
    guard let versionUrl = self.audioUnitConfig.versionUrl, !versionUrl.isEmpty else {
      return .failure(
        .noConfiguration(
          description:
            "There is no update version URL for \(self.audioUnitConfig.manufacturer) \(self.audioUnitConfig.name)"
        ))
    }
    do {
      let currentVersion = try await Version.getAndParse(audioUnitConfig: self.audioUnitConfig)
      if currentVersion != nil {
        let compatible = Version.compatible(
          version1: currentVersion, version2: self.existingVersion)
        return .success(
          UpdateSuccess(updateConfig: self, currentVersion: currentVersion, compatible: compatible))
      } else {
        return .failure(
          .configurationNotFoundInHttpResult(
            description: "Current version of \(self.audioUnitConfig.name) not found"))
      }
    } catch {
      return .failure(
        .genericUpdateError(
          description:
            "Caught error \(error) while checking the current version of \(self.audioUnitConfig.name)"
        ))
    }
  }
}

struct UpdateConfigs {
  let noConfiguration: [String]
  let toUpdate: [UpdateConfig]

  init(audioUnitConfigs: AudioUnitConfigs, components: [AVAudioUnitComponent]) {
    var noConfiguration: [String] = []
    var toUpdate: [UpdateConfig] = []
    for component in components {
      guard let audioUnitConfig = audioUnitConfigs[component] else {
        noConfiguration.append(
          "\(component.manufacturerName) \(component.name) (\(component.versionString))")
        continue
      }
      if audioUnitConfig.system != true
        && audioUnitConfig.versionUrl != nil
        && audioUnitConfig.versionUrl != ""
      {
        toUpdate.append(
          UpdateConfig(
            existingVersion: component.versionString,
            audioUnitConfig: audioUnitConfig
          ))
      }
    }
    self.noConfiguration = noConfiguration
    self.toUpdate = toUpdate
  }
}

enum UpdateError: Error, CustomStringConvertible {
  case configurationNotFoundInHttpResult(description: String)
  case noConfiguration(description: String)
  case webRequestFailed(description: String)
  case genericUpdateError(description: String)

  public var description: String {
    switch self {
    case .configurationNotFoundInHttpResult(let description): return description
    case .noConfiguration(let description): return description
    case .webRequestFailed(let description): return description
    case .genericUpdateError(let description): return description
    }
  }
}
struct UpdateSuccess {
  let updateConfig: UpdateConfig
  let currentVersion: String?
  let compatible: Bool
}
