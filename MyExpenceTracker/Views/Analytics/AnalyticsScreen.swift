//
//  AnalyticsScreen.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import SwiftUI
import Charts
import CoreData

struct AnalyticsScreen: View {
    @EnvironmentObject var transactionVM: TransactionViewModel
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    analyticsSummary
                    
                    // Income vs Expense Pie Chart
                    incomeExpensePieChart
                    
                    // Category Breakdown Pie Chart
                    categoryBreakdownChart
                    
                    // Category Details List
                    categoryDetailsList
                    
                    // Top Spending Categories
                    topSpendingSection
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MonthPickerView()
                }
            }
        }
    }
    
    // MARK: - Summary
    private var analyticsSummary: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                AnalyticsSummaryCard(
                    title: "Total Income",
                    amount: transactionVM.totalIncome(),
                    color: .green,
                    icon: "arrow.down.circle.fill"
                )
                
                AnalyticsSummaryCard(
                    title: "Total Expense",
                    amount: transactionVM.totalExpense(),
                    color: .red,
                    icon: "arrow.up.circle.fill"
                )
            }
            
            // Net Savings
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Net Savings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(currencyManager.format(transactionVM.netSavings()))
                        .font(.title2.weight(.bold))
                        .foregroundColor(transactionVM.netSavings() >= 0 ? .green : .red)
                }
                
                Spacer()
                
                Image(systemName: transactionVM.netSavings() >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(transactionVM.netSavings() >= 0 ? .green : .red)
                    .opacity(0.7)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Income vs Expense
    private var incomeExpensePieChart: some View {
        let slices: [PieSliceData] = {
            var data: [PieSliceData] = []
            let income = transactionVM.totalIncome()
            let expense = transactionVM.totalExpense()
            
            if income > 0 {
                data.append(PieSliceData(label: "Income", value: income, color: .green))
            }
            if expense > 0 {
                data.append(PieSliceData(label: "Expense", value: expense, color: .red))
            }
            return data
        }()
        
        return PieChartView(slices: slices, title: "Income vs Expense")
    }
    
    // MARK: - Category Breakdown
    private var categoryBreakdownChart: some View {
        let slices: [PieSliceData] = {
            let expenseTransactions = transactionVM.transactions.filter { $0.type == "expense" }
            let grouped = Dictionary(grouping: expenseTransactions) { $0.category?.wrappedName ?? "Other" }
            
            return grouped.map { key, transactions in
                let total = transactions.reduce(0) { $0 + $1.amount }
                let color = transactions.first?.category?.uiColor ?? .gray
                return PieSliceData(label: key, value: total, color: color)
            }.sorted { $0.value > $1.value }
        }()
        
        return PieChartView(slices: slices, title: "Expense by Category")
    }
    
    // MARK: - Category Details
    private var categoryDetailsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Details")
                .font(.headline)
                .foregroundColor(.primary)
            
            let categoryTotals = getCategoryTotals()
            
            if categoryTotals.isEmpty {
                HStack {
                    Spacer()
                    Text("No expense data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                ForEach(categoryTotals, id: \.name) { item in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(item.color.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: item.icon)
                                .font(.system(size: 16))
                                .foregroundColor(item.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.subheadline.weight(.medium))
                            Text("\(item.count) transaction\(item.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(currencyManager.format(item.total))
                                .font(.subheadline.weight(.semibold))
                            
                            let totalExpense = transactionVM.totalExpense()
                            if totalExpense > 0 {
                                Text(String(format: "%.1f%%", (item.total / totalExpense) * 100))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if item.name != categoryTotals.last?.name {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Top Spending
    private var topSpendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Trend")
                .font(.headline)
                .foregroundColor(.primary)
            
            let dailySpending = getDailySpending()
            
            if dailySpending.isEmpty {
                HStack {
                    Spacer()
                    Text("No spending data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                Chart(dailySpending, id: \.day) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .chartXAxisLabel("Day of Month")
                .chartYAxisLabel("Amount")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    private struct CategoryTotal {
        let name: String
        let icon: String
        let color: Color
        let total: Double
        let count: Int
    }
    
    private func getCategoryTotals() -> [CategoryTotal] {
        let expenses = transactionVM.transactions.filter { $0.type == "expense" }
        let grouped = Dictionary(grouping: expenses) { $0.category?.objectID }
        
        return grouped.compactMap { _, transactions in
            guard let first = transactions.first, let category = first.category else { return nil }
            let total = transactions.reduce(0) { $0 + $1.amount }
            return CategoryTotal(
                name: category.wrappedName,
                icon: category.wrappedIcon,
                color: category.uiColor,
                total: total,
                count: transactions.count
            )
        }
        .sorted { $0.total > $1.total }
    }
    
    private struct DailySpending {
        let day: Int
        let amount: Double
    }
    
    private func getDailySpending() -> [DailySpending] {
        let expenses = transactionVM.transactions.filter { $0.type == "expense" }
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: expenses) {
            calendar.component(.day, from: $0.wrappedDate)
        }
        
        return grouped.map { day, transactions in
            DailySpending(day: day, amount: transactions.reduce(0) { $0 + $1.amount })
        }
        .sorted { $0.day < $1.day }
    }
}

// MARK: - Analytics Summary Card
struct AnalyticsSummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(currencyManager.format(amount))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
