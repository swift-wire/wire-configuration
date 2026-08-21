// swift-tools-version: 6.0
import CompilerPluginSupport
import PackageDescription

// The swift-configuration adapter for Wire. It owns everything configuration-specific: the `@Configuration`
// property wrapper, which `ConfigReader` method each value type is read with, and the required-vs-defaulted
// choice. swift-wire itself learns none of that — it sees an annotation declaring `.rewritesInjection`, and
// emits a call to the wrapper's own `wireValue(from:)`.
//
// Its own package rather than a target in swift-wire (which depends on nothing but swift-syntax) or in
// wire-mvc (configuration is not HTTP-specific — a CLI or a worker wants it too), matching the
// wire-open-api / wire-hummingbird adapter convention.
let package = Package(
    name: "wire-configuration",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "WireConfiguration", targets: ["WireConfiguration"])
    ],
    dependencies: [
        .package(url: "https://github.com/tachyonics/swift-wire.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-configuration.git", from: "1.0.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax", "603.0.0"..<"604.0.0"),
    ],
    targets: [
        // The peer-macro half of `@Configuration`, so the attribute is legal on a `let` property. It
        // generates nothing; see ConfigurationMacro.
        .macro(
            name: "WireConfigurationMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "WireConfiguration",
            dependencies: [
                "WireConfigurationMacros",
                .product(name: "Wire", package: "swift-wire"),
                .product(name: "Configuration", package: "swift-configuration"),
            ]
        ),
        .testTarget(
            name: "WireConfigurationTests",
            dependencies: ["WireConfiguration"]
        ),
    ]
)
