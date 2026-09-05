// swift-tools-version: 6.3
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 the swift-wire project authors

import CompilerPluginSupport
import PackageDescription

// The swift-configuration adapter for Wire. It owns everything configuration-specific: the `@ConfigProperty`
// property wrapper, which `ConfigReader` method each value type is read with, and the required-vs-defaulted
// choice. swift-wire itself learns none of that — it sees an annotation declaring `.rewritesInjection`, and
// emits a call to the wrapper's own `wireValue(from:)`.
//
// Its own package rather than a target in swift-wire (which depends on nothing but swift-syntax) or in
// wire-mvc (configuration is not HTTP-specific — a CLI or a worker wants it too), matching the
// wire-open-api / wire-hummingbird adapter convention.
let package = Package(
    name: "wire-configuration",
    // Inherited from swift-wire, which needs macOS 15 for `Synchronization`'s `Mutex`. Linux is unaffected.
    //
    // This package also requires a **recent macOS SDK**, which is a different axis and one SPM cannot
    // express: `platforms:` is the deployment *target*. swift-configuration's `FileProvider` calls
    // `Data.bytes` under `canImport(FoundationEssentials)`, and that call needs the declaration to exist in
    // the SDK being compiled against — it is not gated on the OS being deployed to. Measured: against the
    // Xcode 26 SDK it type-checks at deployment targets 13, 14 and 15 alike, while an older Xcode's SDK
    // fails it outright (apple/swift-configuration#178). So raising this to `.v26` would restrict every
    // consumer's runtime without preventing the failure. The requirement lives in CI's runner image and in
    // the README instead.
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
        // The peer-macro half of `@ConfigProperty`, so the attribute is legal on a `let` property. It
        // generates nothing; see ConfigPropertyMacro.
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
            // `Wire` directly, not just through `WireConfiguration`: the selector test names
            // `BindingKey`, and `MemberImportVisibility` requires the module that declares a type it
            // uses to be a direct dependency.
            dependencies: ["WireConfiguration", .product(name: "Wire", package: "swift-wire")]
        ),
    ]
)
