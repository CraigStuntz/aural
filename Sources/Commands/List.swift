struct ListAudioUnits {
  static func run(options: Options) {
    let components = AudioUnitComponents.components(maybeFilter: options.filter)
    let data = components.map { [$0.manufacturerName, $0.name, $0.typeName, $0.versionString] }
    Table(headers: ["manufacturer", "name", "type", "version"], data: data).printToConsole()
  }
}
