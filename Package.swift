// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotchCloset",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-collections.git",
            from: "1.3.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "NotchCloset",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections")
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
