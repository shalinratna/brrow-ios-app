// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Brrow",
    platforms: [
        .iOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/OneSignal/OneSignal-iOS-SDK", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "Brrow",
            dependencies: [
                .product(name: "OneSignalFramework", package: "OneSignal-iOS-SDK"),
                .product(name: "OneSignalInAppMessages", package: "OneSignal-iOS-SDK"),
                .product(name: "OneSignalLocation", package: "OneSignal-iOS-SDK")
            ]
        )
    ]
)