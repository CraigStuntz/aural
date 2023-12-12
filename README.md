# Aural

A macOS command line tool for managing Audio Units.

```
 $ aural --help
OVERVIEW: A utility for managing Audio Units.

USAGE: aural [--filter <filter>] <subcommand>

OPTIONS:
  --filter <filter>       Restrict Audio Units processed. Format name:value, allowed names are manufacturer, type, or subtype.
  --version               Show the version.
  -h, --help              Show help information.

SUBCOMMANDS:
  export                  Exports the installed Audio Units and their presets
  list (default)          Outputs installed Audio Units
  update                  Queries for available updates for installed Audio Units

  See 'aural help <subcommand>' for detailed help.
```

## Building

You need to have the command-line tools installed. You don't necessarily need XCode:

```bash
$ xcode-select --install
```

To build using the `Makefile` you will also need to have `swift-format` installed:

```bash
$ brew install swift-format
```

To build:

```bash
$ make
```

To just run, building if needed:

```bash
$ swift run aural [--argument]
```

To run tests: 

```bash
$ make test
```

If you get an error about 
`unable to lookup item ‘PlatformPath’ from command line tools installation`
and you have XCode, then do:

```bash
$ sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer
```