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
        abstract: "Exports the installed Audio Units and their presets. (unimplemented, for now)",
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
      ListAudioUnits.run(options: options)
    }
  }

  struct Update: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "update",
      abstract: "Queries for available updates for installed Audio Units")

    @OptionGroup var options: Options

    mutating func run() async {
      await UpdateAudioUnits.run(options: options)
    }
  }
}

extension Aural.Export {
  struct Logic: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract:
        "Exports Audio Unit and preset names to Logic Pro libraries. (unimplemented, for now)"
    )

    mutating func run() {
      print("Export!")
    }
  }
}
