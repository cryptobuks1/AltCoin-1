// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "altcoin_simulator",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
		.package(url: "https://github.com/OpenKitten/BSON", .branch("master/6.0")),
		.package(url: "https://github.com/evgenyneu/SigmaSwiftStatistics.git", from: "9.0.0"),
		.package(url: "https://github.com/scinfu/SwiftSoup.git", from: "1.7.4"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "altcoin_simulator",
            dependencies: ["BSON", "SigmaSwiftStatistics", "SwiftSoup"]
	),
        .testTarget(
            name: "altcoin_simulatorTests",
            dependencies: ["altcoin_simulator"]),
    ]
)
