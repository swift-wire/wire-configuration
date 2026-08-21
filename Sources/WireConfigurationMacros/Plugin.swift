import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

/// `@Configuration` on a *property* is a marker peer macro generating nothing, exactly as `@Container` is.
///
/// It exists so the attribute is legal on a `let`. A property wrapper "can only be applied to a 'var'", so
/// without this the property form would force every consumer to give up immutability — while the
/// initialiser-parameter form, which *must* be a property wrapper (a macro cannot attach to a parameter),
/// keeps its stored property a `let`. Two declarations sharing one name let Swift resolve each use site to
/// whichever can apply there, so both forms are expressible and equivalent.
///
/// Wire reads the attribute syntactically, before expansion, so the two look identical to it.
public struct ConfigurationMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}

@main
struct WireConfigurationPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [ConfigurationMacro.self]
}
