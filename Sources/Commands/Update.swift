import AVFoundation

struct UpdateAudioUnits {
  static func run(options: Options, writeConfigFile: Bool) async {
    let components = AudioUnitComponents.components(maybeFilter: options.filter)
    let audioUnitConfigs = AudioUnitConfigs()
    let updateConfigs = UpdateConfigs(audioUnitConfigs: audioUnitConfigs, components: components)
    if !updateConfigs.noConfiguration.isEmpty {
      if verbosity != .quiet {
        let headers =
          verbosity == .verbose
          ? ["No update configurations found for:", "manufacturer", "subtype", "type"]
          : ["No update configurations found for:"]
        Table(
          headers: headers,
          data: updateConfigs.noConfiguration.map { component in describe(component) }
        )
        .printToConsole()
        Console.standard()
      }
    }
    if writeConfigFile {
      audioUnitConfigs.writeConfig(components, "AudioUnits.plist")
    }
    if updateConfigs.toUpdate.isEmpty {
      Console.standard("No Audio Units configured for update.")
    } else {
      Console.standard("Requesting current versions from manufacturer's sites...", terminator: "")
      var current: [[String]] = []
      var failures: [[String]] = []
      var outOfDate: [[String]] = []
      await withTaskGroup(of: Result<UpdateSuccess, UpdateError>.self) { group in
        for updateConfig in updateConfigs.toUpdate {
          group.addTask { await updateConfig.requestLatestVersion() }
        }
        for await result in group {
          Console.standard(".", terminator: "")
          switch result {
          case .success(let updateSuccess):
            let latestVersion = updateSuccess.latestVersion ?? "<unknown>"
            let audioUnitConfig = updateSuccess.updateConfig.audioUnitConfig
            if updateSuccess.compatible {
              current.append([
                updateSuccess.component.manufacturerName,
                updateSuccess.component.name,
                latestVersion,
                updateSuccess.updateConfig.component.versionString,
              ])
            } else {
              outOfDate.append([
                updateSuccess.component.manufacturerName,
                updateSuccess.component.name,
                latestVersion,
                updateSuccess.updateConfig.component.versionString,
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

      Console.standard()  // Terminate "Requesting current versions..." line
      Console.standard()  // insert blank line
      if !current.isEmpty && verbosity != .quiet {
        Console.standard("Up to date Audio Units:")
        Table(
          headers: ["manufacturer", "name", "latest version", "local version"],
          data: current
        ).printToConsole()
      }
      if !(current.isEmpty && outOfDate.isEmpty) {
        Console.standard()
      }
      if !outOfDate.isEmpty {
        Console.standard("Audio Units which need to be updated:")
        Table(
          headers: [
            "manufacturer", "name", "latest version", "local version", "update instructions",
          ],
          data: outOfDate
        ).printToConsole()
      }
      if !outOfDate.isEmpty && !failures.isEmpty {
        Console.force()
      }
      if !failures.isEmpty {
        Console.error("Errors encountered during update:")
        Table(headers: [], data: failures).printToConsole()
      }
    }
  }

  static func describe(_ component: AVAudioUnitComponent) -> [String] {
    var result = ["\(component.manufacturerName) \(component.name) (\(component.versionString))"]
    if verbosity == .verbose {
      result.append(contentsOf: [
        component.audioComponentDescription.componentManufacturer.toString(),
        component.audioComponentDescription.componentSubType.toString(),
        component.audioComponentDescription.componentType.toString(),
      ])
    }
    return result
  }
}

struct UpdateConfig {
  let component: AVAudioUnitComponent
  let audioUnitConfig: AudioUnitConfig

  func requestLatestVersion() async -> Result<UpdateSuccess, UpdateError> {
    guard let versionUrl = self.audioUnitConfig.versionUrl, !versionUrl.isEmpty else {
      return .failure(
        .noConfiguration(
          description:
            "There is no update version URL for \(self.audioUnitConfig.manufacturer) \(self.audioUnitConfig.name)"
        ))
    }
    do {
      guard
        let latestVersion = try await Version.getAndParse(audioUnitConfig: self.audioUnitConfig)
      else {
        return .failure(
          .configurationNotFoundInHttpResult(
            description: "Current version of \(self.component.name) not found"))
      }
      let compatible = Version.compatible(
        latestVersion: latestVersion, existingVersion: self.component.versionString)
      return .success(
        UpdateSuccess(
          component: component, updateConfig: self, latestVersion: latestVersion,
          compatible: compatible))
    } catch {
      return .failure(
        .genericUpdateError(
          description:
            "Caught error \(error) while checking the current version of \(self.component.name)"
        ))
    }
  }
}

struct UpdateConfigs {
  let noConfiguration: [AVAudioUnitComponent]
  let toUpdate: [UpdateConfig]

  init(audioUnitConfigs: AudioUnitConfigs, components: [AVAudioUnitComponent]) {
    var noConfiguration: [AVAudioUnitComponent] = []
    var toUpdate: [UpdateConfig] = []
    for component in components {
      guard let audioUnitConfig = audioUnitConfigs[component] else {
        noConfiguration.append(component)
        continue
      }
      if audioUnitConfig.system != true {
        if audioUnitConfig.versionUrl != nil
          && audioUnitConfig.versionUrl != ""
        {
          toUpdate.append(
            UpdateConfig(
              component: component,
              audioUnitConfig: audioUnitConfig
            ))
        } else if verbosity == .verbose {
            noConfiguration.append(component)
        }
      }
    }
    self.noConfiguration = noConfiguration
    self.toUpdate = toUpdate
  }
}

enum UpdateError: Error, CustomStringConvertible {
  case configurationNotFoundInHttpResult(description: String)
  case noConfiguration(description: String)
  case noRegexMatch(regex: String)
  case webRequestFailed(description: String)
  case genericUpdateError(description: String)

  public var description: String {
    switch self {
    case .configurationNotFoundInHttpResult(let description): return description
    case .noConfiguration(let description): return description
    case .noRegexMatch(let regex): return "No match for regex \(regex)"
    case .webRequestFailed(let description): return description
    case .genericUpdateError(let description): return description
    }
  }
}

struct UpdateSuccess {
  let component: AVAudioUnitComponent
  let updateConfig: UpdateConfig
  let latestVersion: String?
  let compatible: Bool
}
