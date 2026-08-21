import Configuration
import Testing

@testable import WireConfiguration

/// The wrapper owns everything configuration-specific, so these test it directly — no graph involved.
/// Wire's side (recognising the annotation, synthesising the producer) is tested in swift-wire.
@Suite("Configuration wrapper")
struct ConfigurationTests {
    /// Typed values, since a provider stores `ConfigValue` — a string does not stand in for an int.
    private func reader(_ values: [String: ConfigValue]) -> ConfigReader {
        let keyed = Dictionary(
            uniqueKeysWithValues: values.map { (AbsoluteConfigKey([$0.key]), $0.value) }
        )
        return ConfigReader(provider: InMemoryProvider(values: keyed))
    }

    @Test func defaultedFormFallsBackWhenAbsent() throws {
        #expect(try Configuration<Int>.wireValue(from: reader([:]), forKey: "port", default: 8080) == 8080)
    }

    @Test func defaultedFormReadsThePresentValue() throws {
        #expect(try Configuration<Int>.wireValue(from: reader(["port": 9090]), forKey: "port", default: 8080) == 9090)
    }

    /// The required form is what makes a missing key a startup failure rather than a silent fallback —
    /// the reason `@Configuration(forKey:)` with no default maps to the reader's `required*` family.
    @Test func requiredFormThrowsWhenAbsent() {
        #expect(throws: (any Error).self) {
            try Configuration<String>.wireValue(from: reader([:]), forKey: "dsn")
        }
    }

    @Test func requiredFormReadsThePresentValue() throws {
        #expect(
            try Configuration<String>.wireValue(from: reader(["dsn": "postgres://"]), forKey: "dsn") == "postgres://"
        )
    }

    /// The attachment form is what a user writes; `wrappedValue` is the value the compiler passed through.
    /// The attachment role is separate: an initialiser carries the value the compiler passed, and has
    /// nothing to do with reading configuration.
    @Test func attachmentFormCarriesTheValue() {
        let wrapper = Configuration(wrappedValue: 42, forKey: "port", default: 8080)
        #expect(wrapper.wrappedValue == 42)
    }

    // MARK: - The three no-default/defaulted forms

    /// The optional form: absence is `nil`, not an error. Told apart from the required form purely by the
    /// site's type, which is what lets both exist.
    @Test func optionalFormYieldsNilWhenAbsent() throws {
        #expect(try Configuration<String?>.wireValue(from: reader([:]), forKey: "dsn") == nil)
    }

    @Test func optionalFormYieldsThePresentValue() throws {
        #expect(
            try Configuration<String?>.wireValue(from: reader(["dsn": "postgres://"]), forKey: "dsn") == "postgres://"
        )
    }

    // MARK: - The attachment role

    /// The wrapper is parameter-only now, so its one job is carrying the value the compiler passed.
    @Test func attachmentCarriesTheValue() {
        func take(@Configuration(forKey: "port", default: 8080) port: Int) -> Int { port }
        #expect(take(port: 42) == 42)
    }
}
