// swift-tools-version:5.5

import PackageDescription

let isLocalDebug = true

let package = Package(
    name: "DevJourneyBlog",
    platforms: [.macOS(.v12)],
    products: [
        .executable(
            name: "DevJourneyBlog",
            targets: ["DevJourneyBlog"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Splash", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "DevJourneyBlog",
            dependencies: [
                "Publish",
                "Splash",
            ],
            path: "Sources"
        )
    ]
)

if isLocalDebug {
    package.dependencies += [
        .package(path: "../Publish"),
    ]
} else {
    package.dependencies += [
        .package(url: "https://github.com/hanleylee/Publish", .branchItem("master")),
    ]
}