//
//  ExpenseListView.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import SwiftUI

struct ExpenseListView: View {
    let transactions: [Transaction]
    let onDelete: (Transaction) -> Void
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        List {
            ForEach(groupedTransactions, id: \.date) { group in
                Section {
                    ForEach(group.transactions, id: \.objectID) { transaction in
                        TransactionRowView(transaction: transaction)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    onDelete(transaction)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                    }
                } header: {
                    HStack {
                        Text(Self.sectionDateFormatter.string(from: group.date))
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                            .textCase(nil)
                        
                        Spacer()
                        
                        let dayTotal = dayExpenseTotal(group.transactions)
                        Text(currencyManager.format(abs(dayTotal)))
                            .font(.caption.weight(.medium))
                            .foregroundColor(dayTotal >= 0 ? .green : .red)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var groupedTransactions: [(date: Date, transactions: [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { transaction in
            calendar.startOfDay(for: transaction.wrappedDate)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, transactions: $0.value.sorted { $0.wrappedDate > $1.wrappedDate }) }
    }
    
    // MARK: - Cached DateFormatter
    private static let sectionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    private func dayExpenseTotal(_ transactions: [Transaction]) -> Double {
        let income = transactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
        let expense = transactions.filter { $0.isExpense }.reduce(0) { $0 + $1.amount }
        return income - expense
    }
}
