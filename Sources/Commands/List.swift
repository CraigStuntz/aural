struct ListAudioUnits {
  static func run(options: Options) {
    let components = AudioUnitComponents.components(maybeFilter: options.filter)
    let data = components.map {
      [
        $0.manufacturerName,
        $0.name,
        $0.typeName,
        $0.versionString,
        "\($0.audioComponentDescription.componentType.toString()) \($0.audioComponentDescription.componentSubType.toString()) \($0.audioComponentDescription.componentManufacturer.toString())",
      ]
    }
    Table(
      headers: [
        "manufacturer",
        "name",
        "type",
        "version",
        "type subt mnfr",
      ], data: data
    ).printToConsole()
  }
}
