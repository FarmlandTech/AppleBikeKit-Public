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
            targets: ["CoreSDK", "FarmLandBikeKit"]),
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
        .binaryTarget(
            name: "FarmLandBikeKit",
            path: "Sources/FarmLandBikeKit/AppleBikeKitSourceCode.xcframework"),
        .testTarget(
            name: "AppleBikeKitTests",
            dependencies: ["FarmLandBikeKit"]),
    ],
    swiftLanguageVersions: [.v5]
)
