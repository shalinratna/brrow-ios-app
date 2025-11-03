// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BrrowAdmin",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "BrrowAdmin",
            targets: ["BrrowAdmin"]),
        .executable(
            name: "BrrowDB",
            targets: ["BrrowDB"])
    ],
    targets: [
        .executableTarget(
            name: "BrrowAdmin",
            path: ".",
            sources: [
                "BrrowAdminApp.swift",
                "Services/AdminAPIClient.swift",
                "Services/AdminAuthManager.swift",
                "Models/AdminModels.swift",
                "Views/AdminViews.swift"
            ]
        ),
        .executableTarget(
            name: "BrrowDB",
            path: ".",
            sources: [
                "BrrowDBApp.swift"
            ]
        )
    ]
)
