# Aural

A macOS command line tool for listing, checking for updates, and validation of 
Audio Units. An "Audio Unit" is like a VST except it's Apple's own format and 
is used by Logic Pro, GarageBand, and other applications.

One shortcoming of Audio Units is there is no built-in solution for determining
when there is an update available. As a typical user may have hundreds of 
Audio Units installed from dozens of manufacturers, this can quickly become 
painful. Aural solves this and other problems.

```
 $ aural --help
OVERVIEW: A utility for managing Audio Units

USAGE: aural [--filter <filter>] [--quiet] [--verbose] <subcommand>

OPTIONS:
  -f, --filter <filter>   Restrict Audio Units processed. Format name:value, allowed names are manufacturer, name, or type
  -q, --quiet             Decrease verbosity to only include specifically requested/error output
  -v, --verbose           Increase verbosity to include informational output
  --version               Show the version.
  -h, --help              Show help information.

SUBCOMMANDS:
  list (default)          Outputs installed Audio Units
  update                  Queries for available updates for installed Audio Units
  validate                Validates (checks for common errors) the installed Audio Units

  See 'aural help <subcommand>' for detailed help.
```

## Update Configuration

Aural needs to know where to look for the latest version of any Audio Units you
may have installed. It uses a [configuration file](https://github.com/CraigStuntz/aural/blob/main/Sources/Resources/AudioUnits.plist)
for this. When you run `aural update` aural will tell you if it does not know
how to check the latest version of any Audio Unit on your system. 

To request support for new Audio Units in `aural update`, open an 
[Issue](https://github.com/CraigStuntz/aural/issues) in this
repository. I will guide you through the process. Or if you're especially 
adventurous, do `aural update --write-config-file`, edit the generated 
`AudioUnits.plist`, and open a PR!

## Building

You need to have the command-line tools installed. You don't necessarily need XCode:

```bash
$ xcode-select --install
```

To build using the `Makefile` you will also need to have 
[`swift-format`](https://github.com/apple/swift-format) installed:

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
$ sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```