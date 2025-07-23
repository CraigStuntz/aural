import AVFoundation
import Foundation
import Testing

@testable import aural

struct ArchitectureMustMatchTests {
  @Test("Should pass with Apple Graphic EQ effect")
  func ruleShouldPassWithSystemAU() async throws {
    let actual = try await executeFor(
      componentType: kAudioUnitType_Effect, componentSubType: kAudioUnitSubType_GraphicEQ,
      componentManufacturer: kAudioUnitManufacturer_Apple)

    #expect(actual.isEmpty, "Should not have returned any errors, returned \(actual)")
  }

  @Test("Should fail with incompatible architecture instrument")
  func ruleShouldFailWithIncompatibleArchitecture() async throws {
    // Pick an instrument with an incompatible architecture.
    let componentSubType =
      ArchitectureMustMatch.currentArchitecture.starts(with: "arm64")
      ? "wari".toFourCharCode()
      : "wara".toFourCharCode()
    let actual = try await executeFor(
      componentType: "ausp".toFourCharCode(),
      componentSubType: componentSubType,
      componentManufacturer: kAudioUnitManufacturer_Apple)

    #expect(!actual.isEmpty, "Should have returned at least one error. Returned nothing.")
    let error = actual[0]
    #expect(error.description.starts(with: "Component does not support current host architecture"))
  }

  private func executeFor(
    componentType: FourCharCode,
    componentSubType: FourCharCode,
    componentManufacturer: FourCharCode
  ) async throws -> [RuleError] {
    let rule = ArchitectureMustMatch()
    let componentDescription = AudioComponentDescription(
      componentType: componentType,
      componentSubType: componentSubType,
      componentManufacturer: componentManufacturer,
      componentFlags: 0,
      componentFlagsMask: 0
    )
    let components = AVAudioUnitComponentManager.shared().components(matching: componentDescription)
    guard let component = components.first else {
      Issue.record(
        "Failed to find component \(componentType.toString()) \(componentSubType.toString()) \(componentManufacturer.toString())"
      )
      return []
    }
    let actual = rule.testComponent(component: component, config: nil)
    return actual
  }
}
