//
//  TransactionRowView.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        HStack(spacing: 14) {
            // Category Icon
            ZStack {
                Circle()
                    .fill((transaction.category?.uiColor ?? .gray).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: transaction.category?.wrappedIcon ?? "questionmark.circle")
                    .font(.system(size: 18))
                    .foregroundColor(transaction.category?.uiColor ?? .gray)
            }
            
            // Details — Amount, Account, Category
            VStack(alignment: .leading, spacing: 4) {
                // Line 1: Amount
                Text("\(transaction.isIncome ? "+" : "-")\(currencyManager.format(transaction.amount))")
                    .font(.body.weight(.semibold))
                    .foregroundColor(transaction.isIncome ? .green : .red)
                
                // Line 2: Account (bank/cash)
                HStack(spacing: 4) {
                    Image(systemName: transaction.account?.accountIcon ?? "building.columns.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(transaction.account?.wrappedName ?? "Unknown")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Line 3: Category
                HStack(spacing: 4) {
                    Circle()
                        .fill(transaction.category?.uiColor ?? .gray)
                        .frame(width: 8, height: 8)
                    Text(transaction.category?.wrappedName ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
