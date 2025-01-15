import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(LocalizePreviewMacroMacros)
import LocalizePreviewMacroMacros

let testMacros: [String: Macro.Type] = [
    "__localize": LocalizeMacro.self,
]
#endif

final class LocalizePreviewMacroTests: XCTestCase {
    func testMacro() throws {
        #if canImport(LocalizePreviewMacroMacros)
        assertMacroExpansion(
            #"""
            #__localize("Hello World \(12)", bundle: Bundle.module, locale: locale, comment: "Hello! Comment!")
            
            #__localize("Hello World \(12)", bundle: Bundle.module, locale: locale)
            """#,
            expandedSource: """
            1
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

}

//│ ├─[1]: LabeledExprSyntax
//│ │ ├─label: identifier("bundle")
//│ │ ├─colon: colon
//│ │ ├─expression: MemberAccessExprSyntax
//│ │ │ ├─period: period
//│ │ │ ╰─declName: DeclReferenceExprSyntax
//│ │ │   ╰─baseName: identifier("module")
//│ │ ╰─trailingComma: comma
