// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AltCoin",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(name: "AltCoin", targets: ["AltCoin"]),
        .executable(name: "AltCoin-Sim", targets: ["AltCoin-Sim"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
//		.package(url: "https://github.com/OpenKitten/BSON", from: "6.0.0"),
		.package(url: "https://github.com/evgenyneu/SigmaSwiftStatistics.git", from: "9.0.0"),
		.package(url: "https://github.com/scinfu/SwiftSoup.git", from: "1.7.4"),
		.package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.12.0"),
		.package(url: "https://github.com/timprepscius/sajson_swift.git", .branch("master")),
		.package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
		.package(url: "https://github.com/swift-server/async-http-client.git", .branch("master"))
	],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "AltCoin",
            dependencies: [
  //          	"BSON",
            	"SigmaSwiftStatistics",
            	"SwiftSoup",
            	"SQLite",
            	"sajson_swift",
            	"NIO",
            	"AsyncHTTPClient"
			]),
		
        .target(
            name: "AltCoin-Sim",
            dependencies: ["AltCoin"]),
        .testTarget(
            name: "AltCoinTests",
            dependencies: ["AltCoin"]),
    ]
)
