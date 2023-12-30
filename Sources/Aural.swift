import AVFoundation
import ArgumentParser

@main
struct Aural: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "A utility for managing Audio Units.",
    version: "0.0.1",
    subcommands: [Export.self, List.self, Update.self, Validate.self],
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
  struct Export: ParsableCommand {
    static var configuration =
      CommandConfiguration(
        abstract: "Exports the installed Audio Units and their presets. (unimplemented, for now)",
        subcommands: [Logic.self],
        defaultSubcommand: Logic.self
      )

    @OptionGroup var options: Options
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

  struct Validate: AsyncParsableCommand {
    static var configuration =
      CommandConfiguration(
        abstract: "Validates (checks for common errors) the installed Audio Units."
      )

    @OptionGroup var options: Options

    @Option(
      help: "Run only one validation, e.g. --rule AuvalMustPass",
      completion: .list(ValidateAudioUnits.allRuleNames)
    )
    var rule: String?

    mutating func run() async throws {
      try await ValidateAudioUnits.run(options: options, rule: rule)
    }
  }
}

extension Aural.Export {
  struct Logic: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
      abstract:
        "Exports Audio Unit and preset names to Logic Pro libraries. (unimplemented, for now)"
    )

    @OptionGroup var options: Options

    mutating func run() async {
      await ExportAudioUnits.logic(options: options)
    }
  }
}
