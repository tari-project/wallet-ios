import Foundation

// MARK: - Shared Formatters

extension BridgeHistory {
    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
    
    static func formatAmount(_ microXtm: String) -> String {
        guard let micro = UInt64(microXtm) else { return "0 XTM" }
        let xtm = Double(micro) / 1_000_000.0
        return String(format: "%.6f XTM", xtm)
    }
    
    static func formatDate(_ dateString: String, style: DateFormatter.Style = .short) -> String {
        guard let date = iso8601Formatter.date(from: dateString) else { return dateString }
        let formatter = style == .short ? shortDateFormatter : mediumDateFormatter
        return formatter.string(from: date)
    }
}
