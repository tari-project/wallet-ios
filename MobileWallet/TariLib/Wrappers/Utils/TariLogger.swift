//  TariLogger.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/03/21
	Using Swift 5.0
	Running on macOS 10.15

    Used for logging from Swift code. Protocol logging happens in the Tari library.
 
	Adapted from https://github.com/LN-Zap/zap-iOS/blob/master/Logger/Logger.swift
*/

import Foundation

// Called TariLogger because it should be included when TariLib is moved into its own pod
public class TariLogger {
    /// Used for crash reporting
    public static var breadcrumbCallback: ((String, Level) -> Void?)?

    public enum Level: String {
        case info = "INFO"
        case verbose = "DEBUG"
        case warning = "WARN"
        case error = "ERROR"
        case tor = "ONION"

        var emoji: String {
            switch self {
            case .info:
                return "ℹ️"
            case .verbose:
                return "🤫"
            case .warning:
                return "⚠️"
            case .error:
                return "❌"
            case .tor:
                return "🧅"
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        return dateFormatter
    }()

    private static var time: String {
        return dateFormatter.string(from: Date())
    }

    public static func info(_ message: Any, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }

    public static func verbose(_ message: Any, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .verbose, message: message, file: file, function: function, line: line)
    }

    public static func warn(_ message: Any, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(
            level: .warning,
            message: error != nil ? "\(message) ❗\(String(describing: error!.localizedDescription))❗" : message,
            file: file,
            function: function,
            line: line
        )
    }

    public static func error(_ message: Any, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(
            level: .error,
            message: error != nil ? "\(message) ❗\(String(describing: error!.localizedDescription))❗" : message,
            file: file,
            function: function,
            line: line
        )
    }

    public static func tor(_ message: Any, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(
            level: .tor,
            message: error != nil ? "\(message) ❗\(String(describing: error!.localizedDescription))❗" : message,
            file: file,
            function: function,
            line: line
        )
    }

    private static func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.last?.components(separatedBy: ".").first ?? ""
    }

    private static func log(level: Level = .info, message: Any, file: String = #file, function: String = #function, line: Int = #line) {
        let logMessage = "\(message) - (\(sourceFileName(filePath: file)).\(function):\(line))".trimmingCharacters(in: .whitespacesAndNewlines)

        TariLogger.logToFile("SWIFT (\(level.rawValue)): \(logMessage)")

        if let breadcrumb = breadcrumbCallback {
            breadcrumb(logMessage, level)
        }

        // xcode debugger gets flooded without this check
        if let msg = message as? String {
            guard !msg.contains("[Tor") else {
                return
            }
        }

       print("\(time) \(level.emoji) \(logMessage)")
    }

    private static func logToFile(_ message: String) {
        
        var errorCode: Int32 = -1
        
        withUnsafeMutablePointer(to: &errorCode) { errorCodePointer in
            message.withCString { log_debug_message($0, errorCodePointer) }
        }
    }
}
