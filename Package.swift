// swift-tools-version: 6.4

// swiftlint:disable explicit_acl explicit_top_level_acl

import PackageDescription

// Syncs Apple OS, Xcode, Swift, SDK and simulator release data into CloudKit
// with MistKit. The records themselves live in SwoopKit.
let swiftSettings: [SwiftSetting] = [
  // SE-0335: Introduce existential `any`
  .enableUpcomingFeature("ExistentialAny"),
  // SE-0409: Access-level modifiers on import declarations
  .enableUpcomingFeature("InternalImportsByDefault"),
]

let package = Package(
  name: "SwoopMistKit",
  platforms: [
    .macOS(.v15),
    .iOS(.v18),
    .watchOS(.v11),
    .tvOS(.v18),
    .visionOS(.v2),
  ],
  products: [
    .library(name: "SwoopMistKit", targets: ["SwoopMistKit"]),
    .executable(name: "swoopmist", targets: ["SwoopMistKitCLI"]),
  ],
  dependencies: [
    // TODO: from: "1.0.0-beta.6" once tagged
    .package(url: "https://github.com/brightdigit/MistKit.git", from: "1.0.0-beta.6"),
    .package(url: "https://github.com/brightdigit/ConfigKeyKit.git", from: "1.0.0-beta.2"),
    .package(url: "https://github.com/brightdigit/FelinePine.git", from: "1.0.0"),
    .package(url: "https://github.com/brightdigit/FelinePineSwift.git", from: "1.0.0"),
    .package(url: "https://github.com/brightdigit/SwoopKit.git", from: "1.0.0-beta.2"),
    .package(url: "https://github.com/brightdigit/IPSWDownloads.git", from: "1.0.0"),
    .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
    .package(
      url: "https://github.com/apple/swift-configuration.git",
      from: "1.0.0",
      traits: ["CommandLineArguments"]
    ),
  ],
  targets: [
    .target(
      name: "SwoopMistKit",
      dependencies: [
        .product(name: "ConfigKeyKit", package: "ConfigKeyKit"),
        .product(name: "MistKit", package: "MistKit"),
        .product(name: "FelinePine", package: "FelinePine"),
        .product(
          name: "FelinePineSwift",
          package: "FelinePineSwift",
          condition: .when(platforms: [.android, .linux, .openbsd, .wasi, .windows])
        ),
        .product(name: "SwoopKit", package: "SwoopKit"),
        .product(name: "IPSWDownloads", package: "IPSWDownloads"),
        .product(name: "SwiftSoup", package: "SwiftSoup"),
        .product(name: "Configuration", package: "swift-configuration"),
      ],
      swiftSettings: swiftSettings
    ),
    .executableTarget(
      name: "SwoopMistKitCLI",
      dependencies: [
        .target(name: "SwoopMistKit")
      ],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "SwoopMistKitTests",
      dependencies: [
        .target(name: "SwoopMistKit")
      ],
      resources: [
        .copy("Fixtures")
      ],
      swiftSettings: swiftSettings
    ),
  ],
  swiftLanguageModes: [.v6]
)
// swiftlint:enable explicit_acl explicit_top_level_acl
