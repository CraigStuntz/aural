import AVFoundation
import ArgumentParser

@main
struct Aural: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "A utility for managing Audio Units.",
    version: "0.0.1",
    subcommands: [Export.self, List.self, Update.self],
    defaultSubcommand: List.self
  )

  @OptionGroup var options: Options
}

struct Options: ParsableArguments {
  @Option(
    name: [.short, .long],
    help:
      "Restrict Audio Units processed. Format name:value, allowed names are manufacturer, name, or type."
  )
  var filter: Filter?
}

extension Aural {
  static func format(_ result: Int, usingHex: Bool) -> String {
    usingHex
      ? String(result, radix: 16)
      : String(result)
  }

  struct Export: ParsableCommand {
    static var configuration =
      CommandConfiguration(
        abstract: "Exports the installed Audio Units and their presets",
        subcommands: [Logic.self],
        defaultSubcommand: Logic.self)

    @OptionGroup var options: Options

    mutating func run() {
      let result = [].reduce(0, +)
      print(format(result, usingHex: false))
    }
  }

  struct List: ParsableCommand {
    static var configuration =
      CommandConfiguration(abstract: "Outputs installed Audio Units")

    @OptionGroup var options: Options

    mutating func run() {
      let components = AudioUnitComponents.components(filter: options.filter)
      let manufacturerNameMaxCount = components.map { $0.manufacturerName.count }.max()
      let nameMaxCount = components.map { $0.name.count }.max()
      let typeNameMaxCount = components.map { $0.typeName.count }.max()
      for component in components {
        let manufacturerName = component.manufacturerName.padding(
          toLength: manufacturerNameMaxCount!, withPad: " ", startingAt: 0)
        let name = component.name.padding(
          toLength: nameMaxCount!, withPad: " ", startingAt: 0)
        let typeName = component.typeName.padding(
          toLength: typeNameMaxCount!, withPad: " ", startingAt: 0)
        print(
          "\(manufacturerName)\t\(name)\t\(typeName)\t\(component.versionString)"
        )
      }
    }
  }

  struct Update: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "update",
      abstract: "Queries for available updates for installed Audio Units")

    @OptionGroup var options: Options

    mutating func run() async {
      print("Updating...")
      let components = AudioUnitComponents.components(filter: options.filter)
      let configs = AudioUnitConfigs()
      let updateConfigs = UpdateConfigs(configs: configs, components: components)
      print("No update configuration found for \(updateConfigs.noConfiguration)")
      for updateConfig in updateConfigs.toUpdate {
        guard let versionUrl = updateConfig.config.versionUrl, !versionUrl.isEmpty else {
          print("There is no update version URL for \(updateConfig.config.manufacturer) \(updateConfig.config.name)")
          continue
        }
        guard let versionRegex = updateConfig.config.versionRegex, !versionRegex.isEmpty else {
          print("There is no update version Regex for \(updateConfig.config.manufacturer) \(updateConfig.config.name)")
          continue
        }
        do {
          let currentVersion = try await HTTPVersionRetriever.retrieve(url: versionUrl, versionMatchRegex: versionRegex)
          if currentVersion != nil {
            print ("Current version of \(updateConfig.config.name) is \(currentVersion!)")
            print ("Existing version of \(updateConfig.config.name) is \(updateConfig.existingVersion)")
            print ("Compatible? \(Versions.compatible(version1: currentVersion, version2: updateConfig.existingVersion))")
          } else {
            print("Current version of \(updateConfig.config.name) not found")
          }
        } catch {
          print("Caught error \(error) while checking the current version of \(updateConfig.config.name)")
        }
      }
    }
  }
}

extension Aural.Export {
  struct Logic: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Exports Audio Unit and preset names to Logic Pro libraries."
    )

    mutating func run() {
      print("Export!")
    }
  }
}
