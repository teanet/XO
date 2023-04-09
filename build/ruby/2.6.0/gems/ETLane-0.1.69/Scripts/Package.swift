// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Scripts",
	platforms: [.macOS(.v10_15)],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
		.target(
			name: "Common",
			dependencies: []),
		.target(
			name: "Resources",
			dependencies: [
				"Common",
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			]
		),
    ]
)
