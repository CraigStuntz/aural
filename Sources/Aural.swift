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
      let data = components.map { [$0.manufacturerName, $0.name, $0.typeName, $0.versionString] }
      Table(headers: ["manufacturer", "name", "type", "version"], data: data).printToConsole()
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
      let audioUnitConfigs = AudioUnitConfigs()
      let updateConfigs = UpdateConfigs(audioUnitConfigs: audioUnitConfigs, components: components)
      print("No update configuration found for \(updateConfigs.noConfiguration)")
      for updateConfig in updateConfigs.toUpdate {
        let result = await updateConfig.requestCurrentVersion()
        switch result {
        case .success(let updateStatus):
          let currentVersion = updateStatus.currentVersion ?? "<unknown>"
          print(
            "\(updateStatus.config.audioUnitConfig.manufacturer) \(updateStatus.config.audioUnitConfig.name), current version: \(currentVersion), existing version \(updateStatus.config.existingVersion), compatible? \(updateStatus.compatible)"
          )
        case .failure(let updateError):
          print("Failed due to \(updateError)")
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
