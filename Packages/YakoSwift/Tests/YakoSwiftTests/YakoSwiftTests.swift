import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(YakoSwiftMacros)
import YakoSwiftMacros

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
]

let testYakupMacros: [String: Macro.Type] = [
    "DefaultInit": DefaultInitMacro.self,
    "raichu": RaichuMacro.self
]
#endif

final class YakoMacroTests: XCTestCase {
    
    func testRaichuLoves() throws {
        assertMacroExpansion(
            """
            #raichu(4)
            """,
            expandedSource: """
            "Raichu loves you 4 times"
            """,
            macros: testYakupMacros
        )
    }
    
    func testDefaultInit() throws {
        assertMacroExpansion(
            """
            @DefaultInit
            struct User {
                var name: String
                let age: Int
            }
            """,
            expandedSource: """
            struct User {
                var name: String
                let age: Int

                public init(name: String, age: Int) {
                    self.name = name
                    self.age = age
                }
            }
            """,
            macros: testYakupMacros
        )
    }
    
    func testMacro() throws {
        #if canImport(YakoMacroMacros)
        assertMacroExpansion(
            """
            #stringify(a + b)
            """,
            expandedSource: """
            (a + b, "a + b")
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithStringLiteral() throws {
        #if canImport(YakoMacroMacros)
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
