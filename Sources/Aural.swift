import AVFoundation
import ArgumentParser
import AudioToolbox

@main
struct Aural: ParsableCommand {
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
    help:
      "Restrict Audio Units processed. Format name:value, allowed names are manufacturer, type, or subtype."
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
      let componentDescription = AudioComponentDescription()
      let components = AVAudioUnitComponentManager.shared().components(
        matching: componentDescription)
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

  struct Update: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "update",
      abstract: "Queries for available updates for installed Audio Units")

    mutating func run() {
      print("Updating...")
      let config = AudioUnitConfigs.parseConfig()
      print(config.first!.name)
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
