import SwiftUI

struct BridgeHistory: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var store = BridgeStore.shared
    @State private var selectedTransaction: BridgeTransaction?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.combinedTransactions) { transaction in
                    BridgeTransactionRow(transaction: transaction)
                        .onTapGesture {
                            selectedTransaction = transaction
                        }
                }
            }
            .navigationTitle("Bridge History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedTransaction) { transaction in
                BridgeTransactionDetails(transaction: transaction)
            }
            .onFirstAppear {
                Task {
                    try? await BridgeService.shared.refreshTransactions()
                }
            }
        }
    }
}

struct BridgeTransactionRow: View {
    let transaction: BridgeTransaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.type == .wrap ? "Wrap to Ethereum" : "Unwrap to Tari")
                    .font(.headline)
                
                Text(formatAddress(transaction.destinationAddress))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatDate(transaction.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatAmount(transaction.tokenAmount))
                    .font(.headline)
                
                statusBadge
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusBadge: some View {
        Text(transaction.status.rawValue)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }
    
    private var statusColor: Color {
        switch transaction.status {
        case .success:
            return .green
        case .pending, .processing, .tokensReceived:
            return .orange
        case .timeout, .error:
            return .red
        }
    }
    
    private func formatAddress(_ address: String) -> String {
        if address.hasPrefix("0x") {
            return "\(address.prefix(6))...\(address.suffix(4))"
        }
        return "\(address.prefix(8))...\(address.suffix(8))"
    }
    
    private func formatAmount(_ microXtm: String) -> String {
        guard let micro = UInt64(microXtm) else { return "0 XTM" }
        let xtm = Double(micro) / 1_000_000.0
        return String(format: "%.6f XTM", xtm)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .short
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

struct BridgeTransactionDetails: View {
    @Environment(\.dismiss) var dismiss
    let transaction: BridgeTransaction
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    detailRow("Type", transaction.type == .wrap ? "Wrap to Ethereum" : "Unwrap to Tari")
                    detailRow("Status", transaction.status.rawValue)
                    detailRow("Amount", formatAmount(transaction.tokenAmount))
                    detailRow("Amount After Fee", formatAmount(transaction.amountAfterFee))
                    detailRow("Destination", transaction.destinationAddress)
                    if let source = transaction.sourceAddress {
                        detailRow("Source", source)
                    }
                    detailRow("Payment ID", transaction.paymentId)
                    if let hash = transaction.transactionHash {
                        detailRow("Transaction Hash", hash)
                    }
                    detailRow("Created", formatDate(transaction.createdAt))
                }
                .padding()
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
    
    private func formatAmount(_ microXtm: String) -> String {
        guard let micro = UInt64(microXtm) else { return "0 XTM" }
        let xtm = Double(micro) / 1_000_000.0
        return String(format: "%.6f XTM", xtm)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .medium
        return displayFormatter.string(from: date)
    }
}
