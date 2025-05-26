import AVFoundation
@preconcurrency import ArgumentParser

@main
struct Aural: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "A utility for managing Audio Units",
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
      "Restrict Audio Units processed. Format name:value, allowed names are manufacturer, name, or type"
  )
  var filter: Filter?

  @Flag(
    name: [.short, .long],
    help: "Decrease verbosity to only include specifically requested/error output"
  )
  var quiet = false

  @Flag(
    name: [.short, .long],
    help: "Increase verbosity to include informational output"
  )
  var verbose = false

  func assignVerbosity() -> Options {
    // In principle we could do this with a didSet on the quiet and verbose
    // properties. In practice Swift ignores a didSet when setting from an argument.
    if verbose {
      verbosity = .verbose
    } else if quiet {
      verbosity = .quiet
    }
    return self
  }
}

extension Aural {
  struct Export: ParsableCommand {
    static let configuration =
      CommandConfiguration(
        abstract: "Exports the installed Audio Units and their presets. (unimplemented, for now)",
        shouldDisplay: false,
        subcommands: [Logic.self],
        defaultSubcommand: Logic.self
      )

    @OptionGroup var options: Options
  }

  struct List: ParsableCommand {
    static let configuration =
      CommandConfiguration(abstract: "Outputs installed Audio Units")

    @OptionGroup var options: Options

    mutating func run() {
      ListAudioUnits.run(options: options.assignVerbosity())
    }
  }

  struct Update: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "update",
      abstract: "Queries for available updates for installed Audio Units")

    @OptionGroup var options: Options

    @Flag(
      name: [.customLong("integration-test")],
      help: "Integration test all URLs in configuration file"
    )
    var integrationTest: Bool = false

    @Flag(
      name: [.customLong("write-config-file")],
      help: "Write configuration to plist file"
    )
    var writeConfigFile: Bool = false

    mutating func run() async {
      await UpdateAudioUnits.run(
        options: options.assignVerbosity(),
        integrationTest: integrationTest,
        updateWriter: UpdateWriter(),
        writeConfigFile: writeConfigFile)
    }
  }

  struct Validate: AsyncParsableCommand {
    static let configuration =
      CommandConfiguration(
        abstract: "Validates (checks for common errors) the installed Audio Units",
        usage: "Example: aural validate --filter 'manufacturer:Apple' --filter 'name:AUMIDISynth'"
      )

    static func allRuleNames() -> [String] {
      let validate = ValidateAudioUnits()
      return validate.allRuleNames()
    }

    @OptionGroup var options: Options

    @Option(
      help: "Run only one validation, e.g. --rule AuvalMustPass",
      completion: .list(allRuleNames())
    )
    var rule: String?

    mutating func run() async throws {
      let validate = ValidateAudioUnits()
      try await validate.run(options: options.assignVerbosity(), rule: rule)
    }
  }
}

extension Aural.Export {
  struct Logic: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      abstract:
        "Exports Audio Unit and preset names to Logic Pro libraries. (unimplemented, for now)"
    )

    @OptionGroup var options: Options

    mutating func run() async {
      await ExportAudioUnits.logic(options: options.assignVerbosity())
    }
  }
}
