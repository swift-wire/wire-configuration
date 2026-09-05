// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 the wire-configuration project authors

import Configuration
import Testing
import Wire

@testable import WireConfiguration

/// The wrapper owns everything configuration-specific, so these test it directly — no graph involved.
/// Wire's side (recognising the annotation, synthesising the producer) is tested in swift-wire.
@Suite("ConfigProperty")
struct ConfigPropertyTests {
    /// Typed values, since a provider stores `ConfigValue` — a string does not stand in for an int.
    private func reader(_ values: [String: ConfigValue]) -> ConfigReader {
        let keyed = Dictionary(
            uniqueKeysWithValues: values.map { (AbsoluteConfigKey([$0.key]), $0.value) }
        )
        return ConfigReader(provider: InMemoryProvider(values: keyed))
    }

    @Test func defaultedFormFallsBackWhenAbsent() throws {
        #expect(try ConfigProperty<Int>.wireValue(from: reader([:]), forKey: "port", default: 8080) == 8080)
    }

    @Test func defaultedFormReadsThePresentValue() throws {
        #expect(try ConfigProperty<Int>.wireValue(from: reader(["port": 9090]), forKey: "port", default: 8080) == 9090)
    }

    /// The required form is what makes a missing key a startup failure rather than a silent fallback —
    /// the reason `@ConfigProperty(forKey:)` with no default maps to the reader's `required*` family.
    @Test func requiredFormThrowsWhenAbsent() {
        #expect(throws: (any Error).self) {
            try ConfigProperty<String>.wireValue(from: reader([:]), forKey: "dsn")
        }
    }

    @Test func requiredFormReadsThePresentValue() throws {
        #expect(
            try ConfigProperty<String>.wireValue(from: reader(["dsn": "postgres://"]), forKey: "dsn") == "postgres://"
        )
    }

    /// The attachment form is what a user writes; `wrappedValue` is the value the compiler passed through.
    /// The attachment role is separate: an initialiser carries the value the compiler passed, and has
    /// nothing to do with reading configuration.
    @Test func attachmentFormCarriesTheValue() {
        let wrapper = ConfigProperty(wrappedValue: 42, forKey: "port", default: 8080)
        #expect(wrapper.wrappedValue == 42)
    }

    // MARK: - The three no-default/defaulted forms

    /// The optional form: absence is `nil`, not an error. Told apart from the required form purely by the
    /// site's type, which is what lets both exist.
    @Test func optionalFormYieldsNilWhenAbsent() throws {
        #expect(try ConfigProperty<String?>.wireValue(from: reader([:]), forKey: "dsn") == nil)
    }

    @Test func optionalFormYieldsThePresentValue() throws {
        #expect(
            try ConfigProperty<String?>.wireValue(from: reader(["dsn": "postgres://"]), forKey: "dsn") == "postgres://"
        )
    }

    // MARK: - The attachment role

    /// The wrapper is parameter-only now, so its one job is carrying the value the compiler passed.
    @Test func attachmentCarriesTheValue() {
        func take(@ConfigProperty(forKey: "port", default: 8080) port: Int) -> Int { port }
        #expect(take(port: 42) == 42)
    }

    // MARK: - Selecting which reader to read from

    /// `reader:` names which `ConfigReader` binding a site reads from, for a graph binding more than one.
    /// It is compiled here, not asserted: the value never reaches this package. Wire lifts the argument
    /// out of the annotation to key the synthesised producer's dependency, so `wireValue` is handed an
    /// already-resolved reader either way — which is why there is no `wireValue` overload taking one.
    ///
    /// What this pins is that both spellings type-check at a parameter site against the *same*
    /// initialiser, so the selector costs no overloads.
    ///
    /// That the label here matches the one in `.labelled("reader")` cannot be checked from this package:
    /// the capability is a phantom argument Wire reads from source syntax and never executes, so there is
    /// no stored value to assert against. A rename touching only one of the two would compile here and
    /// fail at a consumer, which is what swift-wire's `InjectionRewriteHarness` exists to catch.
    @Test func theSelectorIsAcceptedAndDoesNotReachResolution() {
        enum Keys {
            static let overrides = BindingKey<ConfigReader>()
        }
        func take(
            @ConfigProperty(forKey: "port", default: 8080) plain: Int,
            @ConfigProperty(reader: Keys.overrides, forKey: "port", default: 8080) selected: Int
        ) -> Int { plain + selected }
        #expect(take(plain: 1, selected: 2) == 3)
    }
}
