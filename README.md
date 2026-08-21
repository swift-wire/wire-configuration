# wire-configuration

`WireConfiguration` — a [swift-wire](https://github.com/tachyonics/swift-wire) adapter for
[swift-configuration](https://github.com/apple/swift-configuration).

It gives you `@ConfigProperty`, which reads a value from configuration **at the injection site**
instead of injecting a `ConfigReader` and calling it:

```swift
@Provides
func couchDBClient(
    @ConfigProperty(forKey: "couchdb.host", default: "localhost") host: String,
    @ConfigProperty(forKey: "couchdb.port", default: 5984) port: Int
) -> ConfiguredHTTPClient {
    ConfiguredHTTPClient(baseURL: "http://\(host):\(port)")
}
```

The *value* becomes the binding rather than the reader. So a consumer depends on `String` and `Int`
rather than on a collaborator it has to call, the configuration key is visible in the signature, and a
test substitutes a value rather than a configured reader.

swift-wire itself learns none of this. It sees an annotation declaring `.rewritesInjection(provider:)`
and synthesises a producer that calls back into this package, copying the annotation's arguments
verbatim:

```swift
private func _wireRewrite_…(_wireProvider: ConfigReader) throws -> String {
    try ConfigProperty<String>.wireValue(from: _wireProvider, forKey: "couchdb.host", default: "localhost")
}
```

Which method reads which type, and what an absent key means, live here.

## Requirements

Swift 6.3+, and — on macOS — a **recent SDK**: Xcode 26 or later. swift-configuration calls `Data.bytes`
under `canImport(FoundationEssentials)`, which needs that declaration in the SDK you compile against.
Pairing a swift.org toolchain with an older Xcode gives

```
error: value of type 'Data' has no member 'bytes'
```

inside swift-configuration rather than in your own code (apple/swift-configuration#178). It is not a
deployment-target constraint — the same call type-checks for macOS 13 against a current SDK — so it cannot
be expressed in `Package.swift`, and `swift build` will not tell you which SDK it used. If you see that
error, check `xcodebuild -version`.

## Bind a `ConfigReader`

The synthesised producer depends on a `ConfigReader` like any other binding, so the graph has to have
one. The idiomatic place is a **graph input**, because reading configuration is pre-graph work in any
app that also bootstraps swift-log (which captures its handler at first access):

```swift
@GraphInputs
struct AppInputs: Sendable {
    let config: ConfigReader
}

let graph = try await Wire.bootstrap(inputs: AppInputs(config: reader))
```

Under `@WireMVCBootstrap`, that is what the `prepare()` pre-step is for. A plain `@Provides` works too:

```swift
@Provides let configReader = ConfigReader(providers: [EnvironmentVariablesProvider()])
```

## Three forms

Which form you get is decided by the site's own type and whether you write a default:

| Written | Absent key |
| --- | --- |
| `@ConfigProperty(forKey: "port", default: 8080) port: Int` | the default |
| `@ConfigProperty(forKey: "dsn") dsn: String?` | `nil` |
| `@ConfigProperty(forKey: "dsn") dsn: String` | a startup failure — the binding throws |

The last is what makes a missing required value fail at construction rather than silently fall back.

`isSecret:` is available on every form, and governs redaction in logging and debugging:

```swift
@ConfigProperty(forKey: "db.password", isSecret: true) password: String
```

## Where you can write it

All three injection sites, and the property form takes `var` or `let`:

```swift
@Singleton
struct Config {
    @Inject @ConfigProperty(forKey: "maxConnections", default: 10) let maxConnections: Int
}

@Singleton
struct Config {
    let maxConnections: Int
    @Inject init(@ConfigProperty(forKey: "maxConnections", default: 10) max: Int) {
        self.maxConnections = max
    }
}
```

Those are equivalent. `@ConfigProperty` ships as two declarations sharing one name — a property wrapper,
the only mechanism that can attach to a *parameter*, and a peer macro, the only one that can attach to a
`let` *property* (a property wrapper "can only be applied to a 'var'"). Swift resolves each use site to
whichever applies, so you never have to think about it.

## Supported types

`Int`, `String`, `Bool`, `Double`, `[String]`, `[Int]`.

An unsupported type fails to compile **at the annotation**, listing what is supported — dispatch is by
constrained overload, not a runtime lookup. To add your own, extend `ConfigProperty` with an initialiser
and a `wireValue` overload in the same shape.

## Consumers depend on this package directly

Wire activates a dependency's annotations only when it is a *direct* dependency:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "WireConfiguration", package: "wire-configuration"),
        .product(name: "Wire", package: "swift-wire"),
    ],
    plugins: [.plugin(name: "WireBuildPlugin", package: "swift-wire")]
)
```

Any Wire build plugin works — swift-wire's `WireBuildPlugin`, or an adapter's such as
wire-mvc's `WireMVCBuildPlugin`. The rewrite happens in `WireGen`, which all of them run.

## Selecting which reader

An app that binds more than one `ConfigReader` names which one a site reads from:

```swift
enum ConfigKeys {
    static let overrides = BindingKey<ConfigReader>()
}

@Provides(ConfigKeys.overrides)
func overrideReader() -> ConfigReader { ConfigReader(providers: [...]) }

@Provides
func client(
    @ConfigProperty(forKey: "couchdb.host", default: "localhost") host: String,
    @ConfigProperty(reader: ConfigKeys.overrides, forKey: "couchdb.port", default: 5984) port: Int
) -> Client
```

Omit `reader:` and the reader resolves by type, as every site above does.

`reader:` is the one argument Wire does not copy verbatim. It lifts it out and uses it to key the
synthesised producer's dependency, so `wireValue` is handed an already-resolved reader either way — which
is why no `wireValue` overload takes one. It costs no extra initialisers: the parameter is defaulted, so
one initialiser admits both spellings.

Two sites with identical keys reading *different* readers are different bindings, not one.
