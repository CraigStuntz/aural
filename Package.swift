// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "aural",
  platforms: [
      .macOS(.v13),
      .macCatalyst(.v13),
      .iOS(.v13),
      .tvOS(.v13),
      .watchOS(.v6),
  ],
  dependencies: [
    // other dependencies
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.0.2"),
    .package(url: "https://github.com/adam-fowler/jmespath.swift", from: "1.0.2")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .executableTarget(
      name: "aural",
      dependencies: [
        // other dependencies
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
        .product(name: "JMESPath", package: "jmespath.swift")
      ],
      resources: [.process("Resources/AudioUnits.plist")]
    ),
    .testTarget(
      name: "auralTests",
      dependencies: [
        "aural",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
      ],
      resources: [.process("Resources/AudioUnits.plist")]
    ),
  ]
)
