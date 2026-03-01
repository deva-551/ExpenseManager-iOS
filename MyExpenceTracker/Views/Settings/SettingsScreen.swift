//
//  SettingsScreen.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import SwiftUI
import CoreData

struct SettingsScreen: View {
    @EnvironmentObject var currencyManager: CurrencyManager
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var accountVM: AccountViewModel
    @EnvironmentObject var transactionVM: TransactionViewModel
    @EnvironmentObject var budgetVM: BudgetViewModel
    
    @State private var showClearDataAlert = false
    @State private var showClearSuccess = false
    @State private var showDummyDataConfirm = false
    @State private var showDummyDataSuccess = false
    
    var body: some View {
        NavigationStack {
            List {
                // Currency Section
                Section {
                    NavigationLink {
                        CurrencySelectionView()
                    } label: {
                        HStack {
                            SettingsIcon(icon: "dollarsign.circle.fill", color: .green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Currency")
                                Text(currencyManager.selectedCurrencyCode)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Preferences")
                }
                
                // Categories Management
                Section {
                    NavigationLink {
                        CategoriesManagementView()
                    } label: {
                        HStack {
                            SettingsIcon(icon: "square.grid.2x2.fill", color: .purple)
                            Text("Manage Categories")
                        }
                    }
                    
                    NavigationLink {
                        AccountsManagementView()
                    } label: {
                        HStack {
                            SettingsIcon(icon: "building.columns.fill", color: .blue)
                            Text("Manage Accounts")
                        }
                    }
                } header: {
                    Text("Data Management")
                }
                
                // Data Actions
                Section {
                    Button {
                        showDummyDataConfirm = true
                    } label: {
                        HStack {
                            SettingsIcon(icon: "wand.and.stars", color: .orange)
                            Text("Populate Dummy Data")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(role: .destructive) {
                        showClearDataAlert = true
                    } label: {
                        HStack {
                            SettingsIcon(icon: "trash.fill", color: .red)
                            Text("Clear All Data")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("Actions")
                } footer: {
                    Text("'Populate Dummy Data' creates ~30 sample transactions. 'Clear All Data' will permanently delete all transactions, accounts, budgets, and custom categories.")
                }
                
                // About Section
                Section {
                    HStack {
                        SettingsIcon(icon: "info.circle.fill", color: .gray)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        SettingsIcon(icon: "swift", color: .orange)
                        Text("Built with")
                        Spacer()
                        Text("SwiftUI")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Clear All Data", isPresented: $showClearDataAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("Are you sure you want to delete all data? This action cannot be undone.")
            }
            .alert("Success", isPresented: $showClearSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("All data has been cleared successfully.")
            }
            .alert("Populate Dummy Data?", isPresented: $showDummyDataConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Populate") {
                    populateDummyData()
                }
            } message: {
                Text("This will create ~30 sample transactions across the current and previous month. Your existing data will not be affected.")
            }
            .alert("Dummy Data Added", isPresented: $showDummyDataSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("~30 sample transactions have been created.")
            }
        }
    }
    
    private func populateDummyData() {
        let context = CoreDataStack.shared.viewContext
        let calendar = Calendar.current
        let now = Date()
        
        // Make sure we have categories and accounts
        categoryVM.ensureDefaultCategories()
        accountVM.ensureDefaultAccounts()
        
        let expCats = categoryVM.expenseCategories
        let incCats = categoryVM.incomeCategories
        let allAccounts = accountVM.accounts
        
        guard !expCats.isEmpty, !allAccounts.isEmpty else { return }
        
        let expenseNotes: [String?] = [
            "Lunch with friends", "Uber ride", "Groceries", "Electric bill",
            "Netflix subscription", "Doctor visit", "Online course", "Weekend trip",
            "Coffee", "New shoes", "Phone bill", "Gas station",
            "Restaurant dinner", "Pharmacy", "Gym membership", nil, nil, nil
        ]
        
        let incomeNotes: [String?] = [
            "Monthly salary", "Freelance project", "Dividend payout",
            "Rent received", "Birthday gift", nil, nil
        ]
        
        // Create ~20 expense transactions
        for i in 0..<20 {
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.type = "expense"
            transaction.amount = (Double.random(in: 5...500) * 100).rounded() / 100
            
            let monthOffset = i < 12 ? 0 : -1
            let dayOfMonth = Int.random(in: 1...28)
            var components = calendar.dateComponents([.year, .month], from: now)
            components.month = (components.month ?? 1) + monthOffset
            components.day = dayOfMonth
            transaction.date = calendar.date(from: components) ?? now
            
            transaction.notes = expenseNotes[Int.random(in: 0..<expenseNotes.count)]
            transaction.category = expCats[Int.random(in: 0..<expCats.count)]
            transaction.account = allAccounts[Int.random(in: 0..<allAccounts.count)]
        }
        
        // Create ~10 income transactions
        for i in 0..<10 {
            let transaction = Transaction(context: context)
            transaction.id = UUID()
            transaction.type = "income"
            transaction.amount = (Double.random(in: 500...5000) * 100).rounded() / 100
            
            let monthOffset = i < 6 ? 0 : -1
            let dayOfMonth = Int.random(in: 1...28)
            var components = calendar.dateComponents([.year, .month], from: now)
            components.month = (components.month ?? 1) + monthOffset
            components.day = dayOfMonth
            transaction.date = calendar.date(from: components) ?? now
            
            transaction.notes = incomeNotes[Int.random(in: 0..<incomeNotes.count)]
            transaction.category = incCats.isEmpty ? expCats[Int.random(in: 0..<expCats.count)] : incCats[Int.random(in: 0..<incCats.count)]
            transaction.account = allAccounts[Int.random(in: 0..<allAccounts.count)]
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving dummy data: \(error)")
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Refresh all ViewModels
        transactionVM.fetchTransactions()
        categoryVM.fetchCategories()
        accountVM.fetchAccounts()
        budgetVM.fetchBudgets()
        
        showDummyDataSuccess = true
    }
    
    private func clearAllData() {
        let context = CoreDataStack.shared.viewContext
        let coordinator = CoreDataStack.shared.persistentContainer.persistentStoreCoordinator
        
        let entityNames = ["Transaction", "Budget", "Account", "Category"]
        
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            // Request the deleted object IDs so we can merge into the context
            deleteRequest.resultType = .resultTypeObjectIDs
            
            do {
                let result = try coordinator.execute(deleteRequest, with: context) as? NSBatchDeleteResult
                if let objectIDs = result?.result as? [NSManagedObjectID] {
                    // Merge the deletions into the in-memory context
                    let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                }
            } catch {
                print("Error deleting \(entityName): \(error)")
            }
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Recreate defaults
        DefaultCategories.createDefaultCategories(context: context)
        accountVM.ensureDefaultAccounts()
        
        // Refresh all view models
        transactionVM.fetchTransactions()
        categoryVM.fetchCategories()
        accountVM.fetchAccounts()
        budgetVM.fetchBudgets()
        
        showClearSuccess = true
    }
}

// MARK: - Settings Icon
struct SettingsIcon: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 14))
            .foregroundColor(.white)
            .frame(width: 28, height: 28)
            .background(color)
            .cornerRadius(6)
    }
}

// MARK: - Currency Selection View
struct CurrencySelectionView: View {
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        List {
            ForEach(CurrencyManager.availableCurrencies, id: \.code) { currency in
                Button(action: {
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                    currencyManager.selectedCurrencyCode = currency.code
                }) {
                    HStack {
                        Text(currency.symbol)
                            .font(.title2)
                            .frame(width: 44)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currency.code)
                                .font(.body.weight(.medium))
                                .foregroundColor(.primary)
                            Text(currency.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if currencyManager.selectedCurrencyCode == currency.code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                                .font(.body.weight(.medium))
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Categories Management View
struct CategoriesManagementView: View {
    @EnvironmentObject var categoryVM: CategoryViewModel
    @State private var showAddCategory = false
    @State private var categoryToDelete: Category?
    @State private var showDeleteConfirmation = false
    @State private var showReassignPicker = false
    
    private var otherCategoriesForReassign: [Category] {
        guard let cat = categoryToDelete else { return [] }
        return categoryVM.categoriesForType(cat.wrappedCategoryType).filter { $0.objectID != cat.objectID }
    }
    
    var body: some View {
        List {
            // Expense Categories
            Section("Expense Categories") {
                if categoryVM.expenseCategories.isEmpty {
                    Text("No expense categories")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(categoryVM.expenseCategories, id: \.objectID) { category in
                        categoryRow(category)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    handleCategoryDelete(category)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                    }
                }
            }
            
            // Income Categories
            Section("Income Categories") {
                if categoryVM.incomeCategories.isEmpty {
                    Text("No income categories")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(categoryVM.incomeCategories, id: \.objectID) { category in
                        categoryRow(category)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    handleCategoryDelete(category)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddCategory = true }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategorySheet()
        }
        .alert("Delete Category", isPresented: $showDeleteConfirmation) {
            if !otherCategoriesForReassign.isEmpty {
                Button("Switch to Another") {
                    showReassignPicker = true
                }
            }
            Button("Make Unknown") {
                if let cat = categoryToDelete {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    try? categoryVM.deleteCategory(cat, reassignTo: nil)
                    categoryToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                categoryToDelete = nil
            }
        } message: {
            if let cat = categoryToDelete {
                let txCount = (cat.transactions as? Set<Transaction>)?.count ?? 0
                if txCount > 0 {
                    Text("'\(cat.wrappedName)' has \(txCount) transaction\(txCount == 1 ? "" : "s"). What would you like to do with them?")
                } else {
                    Text("Are you sure you want to delete '\(cat.wrappedName)'?")
                }
            } else {
                Text("Are you sure you want to delete this category?")
            }
        }
        .sheet(isPresented: $showReassignPicker) {
            ReassignCategorySheet(
                categoryToDelete: $categoryToDelete,
                otherCategories: otherCategoriesForReassign
            )
        }
    }
    
    private func handleCategoryDelete(_ category: Category) {
        let txCount = (category.transactions as? Set<Transaction>)?.count ?? 0
        if txCount == 0 {
            // No transactions — delete directly
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            try? categoryVM.deleteCategory(category, reassignTo: nil)
        } else {
            // Has transactions — show reassign alert
            categoryToDelete = category
            showDeleteConfirmation = true
        }
    }
    
    private func categoryRow(_ category: Category) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(category.uiColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: category.wrappedIcon)
                    .font(.system(size: 14))
                    .foregroundColor(category.uiColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.wrappedName)
                    .font(.body)
                
                let txCount = (category.transactions as? Set<Transaction>)?.count ?? 0
                if txCount > 0 {
                    Text("\(txCount) transaction\(txCount == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if category.isDefault {
                Text("Default")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - Reassign Category Sheet
struct ReassignCategorySheet: View {
    @EnvironmentObject var categoryVM: CategoryViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var categoryToDelete: Category?
    let otherCategories: [Category]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Choose a category to move existing transactions to:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section("Available Categories") {
                    ForEach(otherCategories, id: \.objectID) { category in
                        Button(action: {
                            if let cat = categoryToDelete {
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                                try? categoryVM.deleteCategory(cat, reassignTo: category)
                                categoryToDelete = nil
                            }
                            dismiss()
                        }) {
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
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Switch Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        categoryToDelete = nil
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Accounts Management View
struct AccountsManagementView: View {
    @EnvironmentObject var accountVM: AccountViewModel
    @EnvironmentObject var transactionVM: TransactionViewModel
    @EnvironmentObject var currencyManager: CurrencyManager
    @State private var showAddAccount = false
    @State private var accountToDelete: Account?
    @State private var showDeleteConfirmation = false
    @State private var showReassignPicker = false
    
    private var otherAccounts: [Account] {
        guard let acct = accountToDelete else { return [] }
        return accountVM.accounts.filter { $0.objectID != acct.objectID }
    }
    
    var body: some View {
        List {
            if accountVM.accounts.isEmpty {
                Section {
                    Text("No accounts yet. Tap + to add one.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                ForEach(accountVM.accounts, id: \.objectID) { account in
                    HStack {
                        Image(systemName: account.accountIcon)
                            .font(.title3)
                            .foregroundColor(.accentColor)
                            .frame(width: 36)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.wrappedName)
                                .font(.body.weight(.medium))
                            HStack(spacing: 4) {
                                Text(account.wrappedType.capitalized)
                                
                                let txCount = (account.transactions as? Set<Transaction>)?.count ?? 0
                                if txCount > 0 {
                                    Text("• \(txCount) txn\(txCount == 1 ? "" : "s")")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(currencyManager.format(account.currentBalance))
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(account.currentBalance >= 0 ? .primary : .red)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            handleAccountDelete(account)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddAccount = true }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showAddAccount) {
            AddAccountSheet()
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            if !otherAccounts.isEmpty {
                Button("Switch to Another") {
                    showReassignPicker = true
                }
            }
            Button("Make Unknown") {
                if let acct = accountToDelete {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    accountVM.deleteAccount(acct, reassignTo: nil)
                    transactionVM.fetchTransactions()
                    accountToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                accountToDelete = nil
            }
        } message: {
            if let acct = accountToDelete {
                let txCount = (acct.transactions as? Set<Transaction>)?.count ?? 0
                if txCount > 0 {
                    Text("'\(acct.wrappedName)' has \(txCount) transaction\(txCount == 1 ? "" : "s"). What would you like to do with them?")
                } else {
                    Text("Are you sure you want to delete '\(acct.wrappedName)'?")
                }
            } else {
                Text("Are you sure you want to delete this account?")
            }
        }
        .sheet(isPresented: $showReassignPicker) {
            ReassignAccountSheet(
                accountToDelete: $accountToDelete,
                otherAccounts: otherAccounts
            )
        }
    }
    
    private func handleAccountDelete(_ account: Account) {
        let txCount = (account.transactions as? Set<Transaction>)?.count ?? 0
        if txCount == 0 {
            // No transactions — delete directly
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            accountVM.deleteAccount(account, reassignTo: nil)
            transactionVM.fetchTransactions()
        } else {
            // Has transactions — show reassign alert
            accountToDelete = account
            showDeleteConfirmation = true
        }
    }
}

// MARK: - Reassign Account Sheet
struct ReassignAccountSheet: View {
    @EnvironmentObject var accountVM: AccountViewModel
    @EnvironmentObject var transactionVM: TransactionViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var accountToDelete: Account?
    let otherAccounts: [Account]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Choose an account to move existing transactions to:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section("Available Accounts") {
                    ForEach(otherAccounts, id: \.objectID) { account in
                        Button(action: {
                            if let acct = accountToDelete {
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                                accountVM.deleteAccount(acct, reassignTo: account)
                                transactionVM.fetchTransactions()
                                accountToDelete = nil
                            }
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: account.accountIcon)
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 36)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.wrappedName)
                                        .font(.body.weight(.medium))
                                        .foregroundColor(.primary)
                                    Text(account.wrappedType.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Switch Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        accountToDelete = nil
                        dismiss()
                    }
                }
            }
        }
    }
}
