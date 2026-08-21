public import Configuration
public import Wire

// `@Configuration` — read a value from configuration at an injection site, instead of injecting a
// `ConfigReader` and calling it.
//
//     @Provides static func couchDB(
//         @Configuration(forKey: "couchdb.host", default: "localhost") host: String
//     ) -> Client
//
// The value becomes the binding, so a consumer depends on `String` rather than on a collaborator it has to
// call, the key is visible in the signature, and a test substitutes a value rather than a configured
// reader. Wire synthesises the producer:
//
//     private func _wireRewrite_…(_wireProvider: Configuration<String>.Provider) throws -> String {
//         try Configuration<String>(forKey: "couchdb.host", default: "localhost").wireValue(from: _wireProvider)
//     }
//
// — copying the argument list verbatim. Everything configuration-specific is below: which reader method a
// type is read with, and what happens when a key is absent.
//
// **The reader is an ordinary binding.** Bind one however the app already does — most naturally as a
// `@GraphInputs` value built before the graph (configuration is pre-graph work in any app that also
// bootstraps swift-log), or as a plain `@Provides`.

/// Reads a value from a `ConfigReader` binding in the graph.
///
/// Supported value types are those with an initialiser below — `Int`, `String`, `Bool`, `Double`, and their
/// array forms. An unsupported type fails to compile *at the annotation*, listing what is supported. To add
/// your own, extend this type with initialisers in the same shape.
@propertyWrapper
public struct Configuration<Value> {
    /// The *attachment* role, and all of it. Immutable, and never absent: the wrapper is only ever applied
    /// to a **parameter**, where the compiler always has a value to pass. A property site resolves to the
    /// macro below instead — for a `let` because a property wrapper cannot attach to one, and for a `var`
    /// because the macro applies there too and Swift prefers it. So no declaration constructs this without
    /// a value, and nothing has to stand in for one.
    ///
    /// Backed by a private stored property rather than being one: a `public let wrappedValue` would make
    /// Swift synthesise an internal memberwise `init(wrappedValue:)`, which a public property wrapper may
    /// not have — and which would also accept a `Value` the constrained initialisers below reject, letting
    /// an unsupported type through.
    private let value: Value
    public var wrappedValue: Value { value }
}

// Attachment and resolution are kept apart deliberately: the initialisers carry the value the compiler
// passes at a parameter site, and the static `wireValue(from:…)` reads a value given a provider. Wire
// constructs no instance to resolve. Three forms per type, told apart by the site's own type and whether a
// default is written:
//
//   • defaulted — `@Configuration(forKey:default:) x: T`  → absent yields the default
//   • optional  — `@Configuration(forKey:) x: T?`         → absent yields nil
//   • required  — `@Configuration(forKey:) x: T`          → absent is a startup failure
//
// swift-configuration has all three reads; splitting them this way is what lets an app say which it means,
// while Wire knows that none of the three concepts exist.

extension Configuration {
    // MARK: Int

    public init(wrappedValue: Value, forKey key: String, default value: Value, isSecret: Bool = false)
    where Value == Int {
        self.value = wrappedValue
    }
    public init(wrappedValue: Value, forKey key: String, isSecret: Bool = false) where Value == Int? {
        self.value = wrappedValue
    }
    public init(wrappedValue: Value, forKey key: String, isSecret: Bool = false) where Value == Int {
        self.value = wrappedValue
    }

    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        default value: Value,
        isSecret: Bool = false
    ) -> Value where Value == Int {
        config.int(forKey: ConfigKey(key), isSecret: isSecret, default: value)
    }
    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        isSecret: Bool = false
    )
        -> Value
    where Value == Int? {
        config.int(forKey: ConfigKey(key), isSecret: isSecret)
    }
    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        isSecret: Bool = false
    )
        throws -> Value
    where Value == Int {
        try config.requiredInt(forKey: ConfigKey(key), isSecret: isSecret)
    }

    // MARK: String

    public init(wrappedValue: Value, forKey key: String, default value: Value, isSecret: Bool = false)
    where Value == String {
        self.value = wrappedValue
    }
    public init(wrappedValue: Value, forKey key: String, isSecret: Bool = false) where Value == String? {
        self.value = wrappedValue
    }
    public init(wrappedValue: Value, forKey key: String, isSecret: Bool = false) where Value == String {
        self.value = wrappedValue
    }

    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        default value: Value,
        isSecret: Bool = false
    ) -> Value where Value == String {
        config.string(forKey: ConfigKey(key), isSecret: isSecret, default: value)
    }
    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        isSecret: Bool = false
    )
        -> Value
    where Value == String? {
        config.string(forKey: ConfigKey(key), isSecret: isSecret)
    }
    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        isSecret: Bool = false
    )
        throws -> Value
    where Value == String {
        try config.requiredString(forKey: ConfigKey(key), isSecret: isSecret)
    }

    // MARK: Bool

    public init(wrappedValue: Value, forKey key: String, default value: Value, isSecret: Bool = false)
    where Value == Bool {
        self.value = wrappedValue
    }
    public init(wrappedValue: Value, forKey key: String, isSecret: Bool = false) where Value == Bool? {
        self.value = wrappedValue
    }
    public init(wrappedValue: Value, forKey key: String, isSecret: Bool = false) where Value == Bool {
        self.value = wrappedValue
    }

    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        default value: Value,
        isSecret: Bool = false
    ) -> Value where Value == Bool {
        config.bool(forKey: ConfigKey(key), isSecret: isSecret, default: value)
    }
    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        isSecret: Bool = false
    )
        -> Value
    where Value == Bool? {
        config.bool(forKey: ConfigKey(key), isSecret: isSecret)
    }
    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        isSecret: Bool = false
    )
        throws -> Value
    where Value == Bool {
        try config.requiredBool(forKey: ConfigKey(key), isSecret: isSecret)
    }

    // MARK: Double

    public init(wrappedValue: Value, forKey key: String, default value: Value, isSecret: Bool = false)
    where Value == Double {
        self.value = wrappedValue
    }
    public init(wrappedValue: Value, forKey key: String, isSecret: Bool = false) where Value == Double? {
        self.value = wrappedValue
    }
    public init(wrappedValue: Value, forKey key: String, isSecret: Bool = false) where Value == Double {
        self.value = wrappedValue
    }

    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        default value: Value,
        isSecret: Bool = false
    ) -> Value where Value == Double {
        config.double(forKey: ConfigKey(key), isSecret: isSecret, default: value)
    }
    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        isSecret: Bool = false
    )
        -> Value
    where Value == Double? {
        config.double(forKey: ConfigKey(key), isSecret: isSecret)
    }
    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        isSecret: Bool = false
    )
        throws -> Value
    where Value == Double {
        try config.requiredDouble(forKey: ConfigKey(key), isSecret: isSecret)
    }

    // MARK: [String]

    public init(wrappedValue: Value, forKey key: String, default value: Value, isSecret: Bool = false)
    where Value == [String] {
        self.value = wrappedValue
    }
    public init(wrappedValue: Value, forKey key: String, isSecret: Bool = false) where Value == [String]? {
        self.value = wrappedValue
    }
    public init(wrappedValue: Value, forKey key: String, isSecret: Bool = false) where Value == [String] {
        self.value = wrappedValue
    }

    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        default value: Value,
        isSecret: Bool = false
    ) -> Value where Value == [String] {
        config.stringArray(forKey: ConfigKey(key), isSecret: isSecret, default: value)
    }
    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        isSecret: Bool = false
    )
        -> Value
    where Value == [String]? {
        config.stringArray(forKey: ConfigKey(key), isSecret: isSecret)
    }
    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        isSecret: Bool = false
    )
        throws -> Value
    where Value == [String] {
        try config.requiredStringArray(forKey: ConfigKey(key), isSecret: isSecret)
    }

    // MARK: [Int]

    public init(wrappedValue: Value, forKey key: String, default value: Value, isSecret: Bool = false)
    where Value == [Int] {
        self.value = wrappedValue
    }
    public init(wrappedValue: Value, forKey key: String, isSecret: Bool = false) where Value == [Int]? {
        self.value = wrappedValue
    }
    public init(wrappedValue: Value, forKey key: String, isSecret: Bool = false) where Value == [Int] {
        self.value = wrappedValue
    }

    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        default value: Value,
        isSecret: Bool = false
    ) -> Value where Value == [Int] {
        config.intArray(forKey: ConfigKey(key), isSecret: isSecret, default: value)
    }
    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        isSecret: Bool = false
    )
        -> Value
    where Value == [Int]? {
        config.intArray(forKey: ConfigKey(key), isSecret: isSecret)
    }
    public static func wireValue(
        from config: ConfigReader,
        forKey key: String,
        isSecret: Bool = false
    )
        throws -> Value
    where Value == [Int] {
        try config.requiredIntArray(forKey: ConfigKey(key), isSecret: isSecret)
    }
}

extension Configuration: Sendable where Value: Sendable {}

/// Declares `@Configuration` to Wire. `provider:` is the one thing Wire cannot derive — it matches
/// dependencies by canonical type text, so it cannot see through `Configuration<Value>.Provider`.
public let wireConfigurationAnnotation = WireAdapterAnnotationV1(
    annotation: "Configuration",
    capability: .rewritesInjection(provider: "ConfigReader")
)

// The *macro* half of `@Configuration`, sharing the wrapper's name. Swift resolves each use site to
// whichever declaration can apply there: a parameter takes the property wrapper (a macro cannot attach to
// one), and a `let` property takes a macro (a property wrapper "can only be applied to a 'var'"). The
// macro generates nothing — Wire reads the attribute syntactically either way — so the two forms below are
// equivalent, and the property form need not give up immutability:
//
//     @Inject @Configuration(forKey: "maxConnections", default: 10) let maxConnections: Int
//     @Inject init(@Configuration(forKey: "maxConnections", default: 10) max: Int) { … }
//
// One overload per shape, mirroring the initialisers, so a property site accepts exactly what a parameter
// site does.

@attached(peer)
public macro Configuration(forKey: String, default: Int, isSecret: Bool = false) =
    #externalMacro(module: "WireConfigurationMacros", type: "ConfigurationMacro")

@attached(peer)
public macro Configuration(forKey: String, default: String, isSecret: Bool = false) =
    #externalMacro(module: "WireConfigurationMacros", type: "ConfigurationMacro")

@attached(peer)
public macro Configuration(forKey: String, default: Bool, isSecret: Bool = false) =
    #externalMacro(module: "WireConfigurationMacros", type: "ConfigurationMacro")

@attached(peer)
public macro Configuration(forKey: String, default: Double, isSecret: Bool = false) =
    #externalMacro(module: "WireConfigurationMacros", type: "ConfigurationMacro")

@attached(peer)
public macro Configuration(forKey: String, default: [String], isSecret: Bool = false) =
    #externalMacro(module: "WireConfigurationMacros", type: "ConfigurationMacro")

@attached(peer)
public macro Configuration(forKey: String, default: [Int], isSecret: Bool = false) =
    #externalMacro(module: "WireConfigurationMacros", type: "ConfigurationMacro")

@attached(peer)
public macro Configuration(forKey: String, isSecret: Bool = false) =
    #externalMacro(module: "WireConfigurationMacros", type: "ConfigurationMacro")
