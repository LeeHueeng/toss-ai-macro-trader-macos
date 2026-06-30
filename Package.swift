// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TossAIMacroTrader",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TossAIMacroTrader", targets: ["TossChart"])
    ],
    targets: [
        .executableTarget(name: "TossChart")
    ]
)
