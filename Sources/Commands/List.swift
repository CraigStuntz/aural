struct ListAudioUnits {
  static func run(options: Options) {
    let components = AudioUnitComponents.components(maybeFilter: options.filter)
    let data = components.map { ComponentMetadata(avAudioUnitComponent: $0) }
    Table(
      reflecting: ComponentMetadata(), data: data
    ).printToConsole(level: .force)
  }
}
