// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppleBikeKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AppleBikeKit",
            targets: ["CoreSDK", "CoreSDKService", "CoreBLEService", "AppleBikeKit", "FarmLandBikeKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .binaryTarget(
            name: "CoreSDK",
            path: "Sources/CoreSDK/CoreSDKSourceCode.xcframework"),
        .target(
            name: "CoreSDKService",
            dependencies: ["CoreSDK"],
            path: "Sources/CoreSDKService"),
        .binaryTarget(
            name: "CoreBLEService",
            path: "Sources/CoreBLEService/CoreBLEServiceSourceCode.xcframework"),
        .binaryTarget(
            name: "AppleBikeKitSourceCode",
            path: "Sources/AppleBikeKitSourceCode/AppleBikeKitSourceCode.xcframework"),
        .target(
            name: "AppleBikeKit",
            dependencies: ["CoreSDK", "CoreSDKService", "CoreBLEService", "AppleBikeKitSourceCode"],
            path: "Sources/AppleBikeKit",
            swiftSettings: [
                .define("APPLICATION_EXTENSION_API_ONLY=YES"),
                .unsafeFlags(["-application-extension"])
            ],
            linkerSettings: [
                .linkedFramework("SwiftUI", .when(platforms: [.iOS])),
                .linkedFramework("AppKit", .when(platforms: [.macOS]))
            ]),
        .target(
            name: "FarmLandBikeKit",
            dependencies: ["AppleBikeKit"],
            path: "Sources/FarmLandBikeKit",
            swiftSettings: [
                .define("APPLICATION_EXTENSION_API_ONLY=YES"),
                .unsafeFlags(["-application-extension"])
            ]),
        .testTarget(
            name: "AppleBikeKitTests",
            dependencies: ["AppleBikeKit"],
            swiftSettings: [.unsafeFlags(["-suppress-warnings"])]),
    ],
    swiftLanguageVersions: [.v5]
)
