//
//  AccountsScreen.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import SwiftUI

struct AccountsScreen: View {
    @EnvironmentObject var accountVM: AccountViewModel
    @EnvironmentObject var transactionVM: TransactionViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var budgetVM: BudgetViewModel
    @EnvironmentObject var currencyManager: CurrencyManager
    
    @State private var showAddAccount = false
    @State private var showAddBudget = false
    
    var body: some View {
        NavigationStack {
            List {
                // Overall Summary (non-interactive cards)
                Section {
                    overallSummary
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                
                // Month Picker
                Section {
                    MonthPickerView()
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
                
                // Month Stats
                Section {
                    monthStatsRow
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                
                // Accounts Section
                accountsSection
                
                // Budget Section
                budgetSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showAddAccount = true }) {
                            Label("Add Account", systemImage: "building.columns.fill")
                        }
                        Button(action: { showAddBudget = true }) {
                            Label("Add Budget", systemImage: "chart.bar.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAddAccount) {
                AddAccountSheet()
            }
            .sheet(isPresented: $showAddBudget) {
                AddBudgetSheet()
            }
        }
    }
    
    // MARK: - Overall Summary
    private var overallSummary: some View {
        let totalBalance = accountVM.accounts.reduce(0) { $0 + $1.currentBalance }
        
        return VStack(spacing: 6) {
            Text("Total Balance")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(currencyManager.format(totalBalance))
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundColor(totalBalance >= 0 ? .primary : .red)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.top, 4)
    }
    
    // MARK: - Month Stats Row
    private var monthStatsRow: some View {
        let saved = monthlyTotalIncome() - monthlyTotalExpense()
        
        return HStack(spacing: 0) {
            monthStatColumn(title: "Income", amount: monthlyTotalIncome(), color: .green, icon: "arrow.down.circle.fill")
            
            Rectangle()
                .fill(Color(.separator).opacity(0.4))
                .frame(width: 0.5, height: 44)
            
            monthStatColumn(title: "Spent", amount: monthlyTotalExpense(), color: .red, icon: "arrow.up.circle.fill")
            
            Rectangle()
                .fill(Color(.separator).opacity(0.4))
                .frame(width: 0.5, height: 44)
            
            monthStatColumn(title: "Saved", amount: saved, color: saved >= 0 ? .blue : .orange, icon: "banknote.fill")
        }
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func monthStatColumn(title: String, amount: Double, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            
            Text(currencyManager.format(abs(amount)))
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Accounts Section
    private var accountsSection: some View {
        Group {
            if accountVM.accounts.isEmpty {
                Section("Accounts") {
                    Text("No accounts yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                ForEach(accountVM.accounts, id: \.objectID) { account in
                    Section {
                        accountRow(account)
                    } header: {
                        if account == accountVM.accounts.first {
                            Text("Accounts")
                        }
                    }
                }
            }
        }
    }
    
    private func accountRow(_ account: Account) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: account.accountIcon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.wrappedName)
                        .font(.subheadline.weight(.semibold))
                    Text(account.wrappedType.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(currencyManager.format(account.currentBalance))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(account.currentBalance >= 0 ? .primary : .red)
                    Text("Balance")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Income")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(currencyManager.format(account.incomeForMonth(
                        month: transactionVM.selectedMonth,
                        year: transactionVM.selectedYear
                    )))
                        .font(.caption.weight(.medium))
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("Spent")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(currencyManager.format(account.spendingForMonth(
                        month: transactionVM.selectedMonth,
                        year: transactionVM.selectedYear
                    )))
                        .font(.caption.weight(.medium))
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Saved")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    let saved = account.incomeForMonth(month: transactionVM.selectedMonth, year: transactionVM.selectedYear) - account.spendingForMonth(month: transactionVM.selectedMonth, year: transactionVM.selectedYear)
                    Text(currencyManager.format(saved))
                        .font(.caption.weight(.medium))
                        .foregroundColor(saved >= 0 ? .blue : .orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Budget Section
    private var budgetSection: some View {
        Section {
            if budgetVM.budgets.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No budgets set")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Set a Budget") {
                        showAddBudget = true
                    }
                    .font(.subheadline.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(budgetVM.budgets, id: \.objectID) { budget in
                    budgetRow(budget)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        budgetVM.deleteBudget(budgetVM.budgets[index])
                    }
                }
            }
        } header: {
            HStack {
                Text("Budgets")
                Spacer()
                if !budgetVM.budgets.isEmpty {
                    Button("Add") {
                        showAddBudget = true
                    }
                    .font(.subheadline)
                    .textCase(nil)
                }
            }
        }
    }
    
    private func budgetRow(_ budget: Budget) -> some View {
        let spent = budget.spentAmount(month: transactionVM.selectedMonth, year: transactionVM.selectedYear)
        let progress = budget.progress(month: transactionVM.selectedMonth, year: transactionVM.selectedYear)
        let remaining = budget.amount - spent
        let isOver = remaining < 0
        
        return VStack(spacing: 10) {
            HStack {
                if let category = budget.category {
                    ZStack {
                        Circle()
                            .fill(category.uiColor.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: category.wrappedIcon)
                            .font(.system(size: 13))
                            .foregroundColor(category.uiColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.wrappedName)
                            .font(.subheadline.weight(.medium))
                        if let account = budget.account {
                            Text(account.wrappedName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(currencyManager.format(budget.amount))
                        .font(.subheadline.weight(.semibold))
                    Text(isOver ? "Over budget" : "\(currencyManager.format(remaining)) left")
                        .font(.caption)
                        .foregroundColor(isOver ? .red : .green)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor(progress))
                        .frame(width: max(geometry.size.width * CGFloat(min(progress, 1.0)), 0), height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("Spent: \(currencyManager.format(spent))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", min(progress, 9.99) * 100))
                    .font(.caption.weight(.medium))
                    .foregroundColor(progressColor(progress))
            }
        }
        .padding(.vertical, 4)
    }
    
    private func progressColor(_ progress: Double) -> Color {
        if progress >= 1.0 { return .red }
        if progress >= 0.8 { return .orange }
        return .green
    }
    
    // MARK: - Helper Methods
    private func monthlyTotalIncome() -> Double {
        accountVM.accounts.reduce(0) {
            $0 + $1.incomeForMonth(month: transactionVM.selectedMonth, year: transactionVM.selectedYear)
        }
    }
    
    private func monthlyTotalExpense() -> Double {
        accountVM.accounts.reduce(0) {
            $0 + $1.spendingForMonth(month: transactionVM.selectedMonth, year: transactionVM.selectedYear)
        }
    }
}

// MARK: - Add Account Sheet
struct AddAccountSheet: View {
    @EnvironmentObject var accountVM: AccountViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var accountType = "bank"
    @State private var initialBalanceString = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Account Name") {
                    TextField("e.g. HDFC Bank, SBI", text: $name)
                        .autocorrectionDisabled()
                }
                
                Section("Account Type") {
                    Picker("Type", selection: $accountType) {
                        Label("Bank Account", systemImage: "building.columns.fill")
                            .tag("bank")
                        Label("Cash", systemImage: "banknote.fill")
                            .tag("cash")
                    }
                    .pickerStyle(.inline)
                }
                
                Section("Initial Balance") {
                    TextField("0.00", text: $initialBalanceString)
                        .keyboardType(.decimalPad)
                        .onChange(of: initialBalanceString) { _, newValue in
                            initialBalanceString = sanitizeAmount(newValue)
                        }
                }
            }
            .navigationTitle("New Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let balance = Double(initialBalanceString) ?? 0
                        do {
                            try accountVM.addAccount(name: name, type: accountType, initialBalance: balance)
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            dismiss()
                        } catch {
                            alertMessage = error.localizedDescription
                            showAlert = true
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func sanitizeAmount(_ input: String) -> String {
        var result = String(input.unicodeScalars.filter { CharacterSet(charactersIn: "0123456789.,").contains($0) })
        result = result.replacingOccurrences(of: ",", with: ".")
        if let firstDot = result.firstIndex(of: ".") {
            let afterDot = result[result.index(after: firstDot)...]
            result = String(result[...firstDot]) + afterDot.replacingOccurrences(of: ".", with: "")
        }
        return result
    }
}

// MARK: - Add Budget Sheet
struct AddBudgetSheet: View {
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var accountVM: AccountViewModel
    @EnvironmentObject var budgetVM: BudgetViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var amountString = ""
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    /// Only show expense categories for budgets
    private var budgetCategories: [Category] {
        categoryVM.expenseCategories
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Budget Amount") {
                    TextField("0.00", text: $amountString)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                        .onChange(of: amountString) { _, newValue in
                            amountString = sanitizeBudgetAmount(newValue)
                        }
                }
                
                Section("Category") {
                    if budgetCategories.isEmpty {
                        Text("No expense categories available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(budgetCategories, id: \.objectID) { category in
                            Button(action: { selectedCategory = category }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(category.uiColor.opacity(0.15))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: category.wrappedIcon)
                                            .font(.system(size: 14))
                                            .foregroundColor(category.uiColor)
                                    }
                                    
                                    Text(category.wrappedName)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedCategory == category {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section("Account") {
                    ForEach(accountVM.accounts, id: \.objectID) { account in
                        Button(action: { selectedAccount = account }) {
                            HStack {
                                Image(systemName: account.accountIcon)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 36)
                                
                                Text(account.wrappedName)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedAccount == account {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBudget()
                    }
                    .disabled(amountString.isEmpty || selectedCategory == nil || selectedAccount == nil)
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                selectedAccount = accountVM.accounts.first
            }
        }
    }
    
    private func sanitizeBudgetAmount(_ input: String) -> String {
        var result = String(input.unicodeScalars.filter { CharacterSet(charactersIn: "0123456789.,").contains($0) })
        result = result.replacingOccurrences(of: ",", with: ".")
        if let firstDot = result.firstIndex(of: ".") {
            let afterDot = result[result.index(after: firstDot)...]
            result = String(result[...firstDot]) + afterDot.replacingOccurrences(of: ".", with: "")
        }
        return result
    }
    
    private func saveBudget() {
        guard let amount = Double(amountString), amount > 0 else {
            alertMessage = "Please enter a valid amount."
            showAlert = true
            return
        }
        
        guard let category = selectedCategory else {
            alertMessage = "Please select a category."
            showAlert = true
            return
        }
        
        guard let account = selectedAccount else {
            alertMessage = "Please select an account."
            showAlert = true
            return
        }
        
        do {
            try budgetVM.addBudget(amount: amount, category: category, account: account)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
