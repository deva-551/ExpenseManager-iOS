//
//  AddTransactionScreen.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import SwiftUI

struct AddTransactionScreen: View {
    @EnvironmentObject var transactionVM: TransactionViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var accountVM: AccountViewModel
    @EnvironmentObject var currencyManager: CurrencyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var transactionType: String = "expense"
    @State private var amountString: String = ""
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var showCategoryPicker = false
    @State private var showAccountPicker = false
    @State private var showAddCategory = false
    @State private var showAddAccount = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @FocusState private var amountFocused: Bool
    
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
                        selectDefaultCategory()
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
                        // No accounts exist — prompt user to add one
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
                    if categoryVM.categoriesForType(transactionType).isEmpty {
                        // No categories exist — prompt user to add one
                        Button(action: {
                            amountFocused = false
                            showAddCategory = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .frame(width: 36, height: 36)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("No categories yet")
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
            .navigationTitle(transactionType == "income" ? "Add Income" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTransaction()
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
            .sheet(isPresented: $showAddCategory, onDismiss: {
                // Auto-select the first matching category if none selected
                if selectedCategory == nil {
                    selectDefaultCategory()
                }
            }) {
                AddCategorySheet(categoryType: transactionType)
            }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerScreen(selectedAccount: $selectedAccount)
            }
            .sheet(isPresented: $showAddAccount, onDismiss: {
                // Auto-select the first account if none selected
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
            .onAppear {
                if selectedAccount == nil {
                    selectedAccount = accountVM.accounts.first
                }
                selectDefaultCategory()
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
    
    private func selectDefaultCategory() {
        let categoriesForType = categoryVM.categoriesForType(transactionType)
        // Only auto-select if current selection doesn't match the type
        if let current = selectedCategory, current.wrappedCategoryType == transactionType {
            return
        }
        selectedCategory = categoriesForType.first
    }
    
    private func saveTransaction() {
        // Sanitize amount string: accept comma as decimal separator
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
            try transactionVM.addTransaction(
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
