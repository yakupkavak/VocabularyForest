import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")

enum YakupMacroError<Model>: CustomStringConvertible, Error {
    case invalidSyntax
    
    var description: String {
        return switch self {
        case .invalidSyntax:
            "Macro can be apply for \(Model.self)"
        }
    }
}

public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }
        return "(\(argument), \(literal: argument.description))"
    }
}

public struct RaichuMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let expression = node.arguments.first?.expression,
              let value = expression.as(IntegerLiteralExprSyntax.self)?.literal.text,
              let count = Int(value) else {
            throw YakupMacroError<Int>.invalidSyntax
        }
        return ExprSyntax(stringLiteral: "\"Raichu loves you \(count) times\"")
    }
}

public struct DefaultInitMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        if let structDecl = declaration.as(StructDeclSyntax.self) {
            let members = structDecl.memberBlock.members
            let variables = members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
            var parameters: [(name: String, type: String)] = []
            
            for variable in variables {
                for binding in variable.bindings {
                    guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { continue }
                    guard let type = binding.typeAnnotation?.type.description else { continue }
                    parameters.append((name: name, type: type))
                }
            }
            
            let initParams = parameters.map { "\($0.name): \($0.type)" }.joined(separator: ", ")
            let initBody = parameters.map { "self.\($0.name) = \($0.name)" }.joined(separator: "\n    ")
            
            let initCode: DeclSyntax = """
            public init(\(raw: initParams)) {
                \(raw: initBody)
            }
            """
            return [initCode]
        }
        return []
    }
}

@main
struct YakoSwiftPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        DefaultInitMacro.self,
        RaichuMacro.self,
    ]
}
