// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "DeclarativeCombine",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "DeclarativeCombine",
            targets: [
                "DeclarativeCombine"
            ]
        )
    ],
    targets: [
        .target(
            name: "DeclarativeCombine"
        )
    ]
)
