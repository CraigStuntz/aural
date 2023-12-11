// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "aural",
  dependencies: [
    // other dependencies
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .executableTarget(
      name: "aural",
      dependencies: [
        // other dependencies
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ],
      resources: [.process("Resources/AudioUnits.plist")]
    ),
    .testTarget(
      name: "auralTests",
      dependencies: [
        "aural",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      resources: [.process("Resources/AudioUnits.plist")]
    ),
  ]
)
