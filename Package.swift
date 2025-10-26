// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// NOTE: This Package.swift is provided for convenience but is not the primary build system.
// LogLineOS is an iOS application that must be built using Xcode with an iOS App target.
// This file allows some development workflows but will not fully compile on non-Apple platforms.

import PackageDescription

let package = Package(
    name: "LogLineOS",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "LogLineOS",
            targets: ["LogLineOS"]
        ),
    ],
    targets: [
        .target(
            name: "LogLineOS",
            path: "LogLineOS",
            exclude: ["Tests", "Config", "Info.plist"],
            sources: [
                "App",
                "Features",
                "Services"
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),
        .testTarget(
            name: "LogLineOSTests",
            dependencies: ["LogLineOS"],
            path: "LogLineOS/Tests"
        ),
    ]
)
