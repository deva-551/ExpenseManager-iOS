//
//  TransactionDetailScreen.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 24/02/26.
//

import SwiftUI

struct TransactionDetailScreen: View {
    let transaction: Transaction
    @EnvironmentObject var currencyManager: CurrencyManager
    @EnvironmentObject var transactionVM: TransactionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    
    var body: some View {
        List {
            // MARK: - Header
            Section {
                VStack(spacing: 12) {
                    // Type Badge
                    Text(transaction.isIncome ? "Income" : "Expense")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(transaction.isIncome ? Color.green : Color.red)
                        .cornerRadius(12)
                    
                    // Amount
                    Text("\(transaction.isIncome ? "+" : "-")\(currencyManager.format(transaction.amount))")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundColor(transaction.isIncome ? .green : .red)
                    
                    // Date
                    Text(Self.longDateFormatter.string(from: transaction.wrappedDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
            }
            
            // MARK: - Details
            Section("Details") {
                // Account
                DetailRow(
                    icon: transaction.account?.accountIcon ?? "building.columns.fill",
                    iconColor: .accentColor,
                    title: "Account",
                    value: transaction.account?.wrappedName ?? "Unknown",
                    subtitle: (transaction.account?.wrappedType ?? "bank").capitalized
                )
                
                // Category
                DetailRow(
                    icon: transaction.category?.wrappedIcon ?? "questionmark.circle",
                    iconColor: transaction.category?.uiColor ?? .gray,
                    title: "Category",
                    value: transaction.category?.wrappedName ?? "Unknown",
                    subtitle: nil
                )
                
                // Date
                DetailRow(
                    icon: "calendar",
                    iconColor: .orange,
                    title: "Date",
                    value: Self.detailDateFormatter.string(from: transaction.wrappedDate),
                    subtitle: nil
                )
            }
            
            // MARK: - Notes
            if !transaction.wrappedNotes.isEmpty {
                Section("Notes") {
                    Text(transaction.wrappedNotes)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            
            // MARK: - Delete
            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Delete Transaction", systemImage: "trash")
                            .font(.body.weight(.medium))
                        Spacer()
                    }
                }
            }
            
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showEditSheet = true
                }
                .fontWeight(.medium)
            }
        }
        .alert("Delete Transaction", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                transactionVM.deleteTransaction(transaction)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this transaction? This action cannot be undone.")
        }
        .sheet(isPresented: $showEditSheet) {
            EditTransactionScreen(transaction: transaction)
        }
    }
    
    // MARK: - Cached DateFormatters
    private static let longDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    private static let detailDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter
    }()
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String?
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Edit Transaction Screen
struct EditTransactionScreen: View {
    let transaction: Transaction
    @EnvironmentObject var transactionVM: TransactionViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var accountVM: AccountViewModel
    @EnvironmentObject var currencyManager: CurrencyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var transactionType: String
    @State private var amountString: String
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    @State private var date: Date
    @State private var notes: String
    @State private var showCategoryPicker = false
    @State private var showAccountPicker = false
    @State private var showAddAccount = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @FocusState private var amountFocused: Bool
    
    init(transaction: Transaction) {
        self.transaction = transaction
        _transactionType = State(initialValue: transaction.type ?? "expense")
        _amountString = State(initialValue: String(format: "%.2f", transaction.amount))
        _selectedCategory = State(initialValue: transaction.category)
        _selectedAccount = State(initialValue: transaction.account)
        _date = State(initialValue: transaction.wrappedDate)
        _notes = State(initialValue: transaction.wrappedNotes)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Segment Control
                Section {
                    Picker("Type", selection: $transactionType) {
                        Text("Expense").tag("expense")
                        Text("Income").tag("income")
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .onChange(of: transactionType) { _, _ in
                        // Reset category if type changes
                        let categoriesForType = categoryVM.categoriesForType(transactionType)
                        if let current = selectedCategory, current.wrappedCategoryType == transactionType {
                            return
                        }
                        selectedCategory = categoriesForType.first
                    }
                }
                
                // Amount
                Section("Amount") {
                    HStack {
                        Text(currencyManager.symbol())
                            .font(.title2.weight(.medium))
                            .foregroundColor(.secondary)
                        
                        TextField("0.00", text: $amountString)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .keyboardType(.decimalPad)
                            .foregroundColor(transactionType == "income" ? .green : .primary)
                            .focused($amountFocused)
                            .onChange(of: amountString) { _, newValue in
                                amountString = sanitizeAmount(newValue)
                            }
                    }
                }
                
                // Account Selection
                Section(transactionType == "income" ? "Received In" : "Paid From") {
                    if accountVM.accounts.isEmpty {
                        Button(action: {
                            amountFocused = false
                            showAddAccount = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .frame(width: 36, height: 36)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("No accounts yet")
                                        .foregroundColor(.primary)
                                    Text("Tap to add one")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Button(action: {
                            amountFocused = false
                            showAccountPicker = true
                        }) {
                            HStack {
                                if let account = selectedAccount {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.accentColor.opacity(0.12))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: account.accountIcon)
                                            .foregroundColor(.accentColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(account.wrappedName)
                                            .foregroundColor(.primary)
                                        Text(account.wrappedType.capitalized)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Image(systemName: "building.columns")
                                        .foregroundColor(.secondary)
                                        .frame(width: 36, height: 36)
                                    
                                    Text("Select Account")
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
                
                // Category Selection
                Section("Category") {
                    Button(action: {
                        amountFocused = false
                        showCategoryPicker = true
                    }) {
                        HStack {
                            if let category = selectedCategory {
                                ZStack {
                                    Circle()
                                        .fill(category.uiColor.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: category.wrappedIcon)
                                        .foregroundColor(category.uiColor)
                                }
                                
                                Text(category.wrappedName)
                                    .foregroundColor(.primary)
                            } else {
                                Image(systemName: "square.grid.2x2")
                                    .foregroundColor(.secondary)
                                    .frame(width: 36, height: 36)
                                
                                Text("Select Category")
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Date
                Section("Date") {
                    DatePicker("Transaction Date", selection: $date, in: ...Date(), displayedComponents: [.date])
                        .datePickerStyle(.compact)
                }
                
                // Notes
                Section("Notes (Optional)") {
                    TextField("Add a note...", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            amountFocused = false
                        }
                    }
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerScreen(selectedCategory: $selectedCategory, transactionType: transactionType)
            }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerScreen(selectedAccount: $selectedAccount)
            }
            .sheet(isPresented: $showAddAccount, onDismiss: {
                if selectedAccount == nil {
                    selectedAccount = accountVM.accounts.first
                }
            }) {
                AddAccountSheet()
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
    
    private func saveChanges() {
        let sanitized = amountString.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(sanitized), amount > 0 else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            alertMessage = TransactionError.invalidAmount.localizedDescription
            showAlert = true
            return
        }
        
        guard let category = selectedCategory else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            alertMessage = TransactionError.missingCategory.localizedDescription
            showAlert = true
            return
        }
        
        guard let account = selectedAccount else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            alertMessage = TransactionError.missingAccount.localizedDescription
            showAlert = true
            return
        }
        
        do {
            try transactionVM.updateTransaction(
                transaction,
                amount: amount,
                type: transactionType,
                date: date,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category,
                account: account
            )
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            dismiss()
        } catch {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
