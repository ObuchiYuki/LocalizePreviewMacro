import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct LocalizeCall {
    let key: StringLiteralExprSyntax
    let table: ExprSyntax?
    let bundle: ExprSyntax?
    let locale: ExprSyntax?
    let comment: StringLiteralExprSyntax?
}

public struct LocalizeMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        print("Hello World!!!")
        print(node.debugDescription)
        
        let localizeCall = try self.parseArguments(node: node)
        
        return self.buildLocalizeCall(localizeCall, in: context)
    }
    
    private static func buildLocalizeCall(
        _ localizeCall: LocalizeCall,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        """
{ (locale: Locale) -> String in

    func __preview_localizedString(for key: String) -> String {
        guard let path = \(localizeCall.bundle ?? "Bundle.main").path(forResource: locale.identifier, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return key
        }
        
        return NSLocalizedString(
            key, 
            tableName: \(localizeCall.table ?? "nil"), 
            bundle: bundle, 
            value: "", 
            \((localizeCall.comment != nil ? "comment: \(localizeCall.comment!)" : "comment: \"\""))
        )
    }

    if (ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1") {
        return __preview_localizedString(for: \(localizeCall.key))
    } else {
        return String(
            localized: \(localizeCall.key), 
            table: \(localizeCall.table ?? "nil"), 
            bundle: \(localizeCall.bundle ?? "nil"), 
            locale: locale, 
            \(localizeCall.comment != nil ? "comment: \(localizeCall.comment!)" : "")
        )
    }
}(\(localizeCall.locale ?? "Locale.current"))
"""
    }
    
    private static func parseArguments(node: some FreestandingMacroExpansionSyntax) throws -> LocalizeCall {
        var arguments = node.arguments.reversed().map { $0 }
        
        guard let keyArgument = arguments.popLast() else {
            throw MacroExpansionErrorMessage("Missing localization key")
        }
        guard let keyValue = keyArgument.expression.as(StringLiteralExprSyntax.self) else {
            throw MacroExpansionErrorMessage("Localization key must be a string literal")
        }
        
        var table: ExprSyntax?
        var bundle: ExprSyntax?
        var locale: ExprSyntax?
        var comment: StringLiteralExprSyntax?
        
        while let argument = arguments.popLast() {
            if argument.label?.text == "table" {
                table = argument.expression
            } else if argument.label?.text == "bundle" {
                if
                    var bundleArgument = argument.expression.as(MemberAccessExprSyntax.self),
                    bundleArgument.base == nil
                { // Bundle.[module] like syntax
                    bundleArgument.base = "Bundle"
                    bundle = ExprSyntax(bundleArgument)
                } else {
                    bundle = argument.expression
                }
            } else if argument.label?.text == "locale" {
                if
                    var localeArgument = argument.expression.as(MemberAccessExprSyntax.self),
                    localeArgument.base == nil
                { // Locale.[identifier] like syntax
                    localeArgument.base = "Locale"
                    locale = ExprSyntax(localeArgument)
                } else {
                    locale = argument.expression
                }
            } else if argument.label?.text == "comment" {
                if let commentValue = argument.expression.as(StringLiteralExprSyntax.self) {
                    comment = commentValue
                } else {
                    throw MacroExpansionErrorMessage("Comment must be a string literal")
                }
            }
        }
        
        return LocalizeCall(
            key: keyValue,
            table: table,
            bundle: bundle,
            locale: locale,
            comment: comment
        )
    }
}

@main
struct LocalizePreviewMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        LocalizeMacro.self,
    ]
}
