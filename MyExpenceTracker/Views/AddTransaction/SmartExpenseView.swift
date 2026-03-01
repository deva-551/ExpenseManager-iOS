//
//  SmartExpenseView.swift
//  MyExpenceTracker
//

import SwiftUI
import PhotosUI

// MARK: - Shared State

private enum ProcessingState: Equatable {
    case idle
    case processing
    case preview([ParsedExpense])
    case error(String)
    
    static func == (lhs: ProcessingState, rhs: ProcessingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.processing, .processing):
            return true
        case (.error(let a), .error(let b)):
            return a == b
        case (.preview(let a), .preview(let b)):
            return a.count == b.count
        default:
            return false
        }
    }
}

// MARK: - Text to Expense

struct TextToExpenseView: View {
    @EnvironmentObject var transactionVM: TransactionViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var accountVM: AccountViewModel
    @EnvironmentObject var currencyManager: CurrencyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputText = ""
    @State private var state: ProcessingState = .idle
    @FocusState private var isTextFocused: Bool
    
    var body: some View {
        NavigationStack {
            Group {
                switch state {
                case .idle, .error:
                    inputView
                case .processing:
                    processingView
                case .preview(let expenses):
                    previewView(expenses)
                }
            }
            .navigationTitle("Text to Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private var inputView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.indigo.gradient)
                
                Text("Describe your transaction")
                    .font(.headline)
                
                Text("e.g. \"Spent 500 on groceries\" or \"Received 25000 salary\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 30)
            
            TextEditor(text: $inputText)
                .frame(minHeight: 100, maxHeight: 150)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .focused($isTextFocused)
                .padding(.horizontal)
            
            if case .error(let message) = state {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(message)
                        .font(.caption)
                }
                .foregroundColor(.red)
                .padding(.horizontal)
            }
            
            Button {
                processText()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Process with AI")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? Color.gray : Color.indigo
                )
                .cornerRadius(14)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Analyzing with on-device AI...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    private func previewView(_ expenses: [ParsedExpense]) -> some View {
        VStack(spacing: 0) {
            List {
                Section {
                    ForEach(Array(expenses.enumerated()), id: \.offset) { _, expense in
                        ParsedExpenseRow(expense: expense)
                    }
                } header: {
                    Text("AI extracted \(expenses.count) transaction\(expenses.count == 1 ? "" : "s")")
                }
            }
            .listStyle(.insetGrouped)
            
            VStack(spacing: 10) {
                Button {
                    addTransactions(expenses)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Add \(expenses.count) Transaction\(expenses.count == 1 ? "" : "s")")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(14)
                }
                
                Button("Try Again") {
                    withAnimation { state = .idle }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    private func processText() {
        isTextFocused = false
        withAnimation { state = .processing }
        
        Task {
            do {
                let expenseCats = categoryVM.expenseCategories.map { $0.wrappedName }
                let incomeCats = categoryVM.incomeCategories.map { $0.wrappedName }
                let result = try await AIExpenseService.parseExpenses(
                    from: inputText,
                    expenseCategories: expenseCats,
                    incomeCategories: incomeCats
                )
                await MainActor.run {
                    withAnimation { state = .preview(result) }
                }
            } catch {
                await MainActor.run {
                    withAnimation { state = .error(error.localizedDescription) }
                }
            }
        }
    }
    
    private func addTransactions(_ expenses: [ParsedExpense]) {
        let defaultAccount = accountVM.accounts.first
        
        for expense in expenses {
            let type = expense.type.lowercased() == "income" ? "income" : "expense"
            let categories = type == "income" ? categoryVM.incomeCategories : categoryVM.expenseCategories
            let matched = matchCategory(named: expense.categoryName, in: categories)
            
            guard let category = matched, let account = defaultAccount else { continue }
            
            try? transactionVM.addTransaction(
                amount: expense.amount,
                type: type,
                date: Date(),
                notes: expense.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : expense.notes,
                category: category,
                account: account
            )
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

// MARK: - Image to Expense

struct ImageToExpenseView: View {
    @EnvironmentObject var transactionVM: TransactionViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var accountVM: AccountViewModel
    @EnvironmentObject var currencyManager: CurrencyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var state: ProcessingState = .idle
    @State private var recognizedText = ""
    
    var body: some View {
        NavigationStack {
            Group {
                switch state {
                case .idle, .error:
                    imageSelectionView
                case .processing:
                    processingView
                case .preview(let expenses):
                    previewView(expenses)
                }
            }
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private var imageSelectionView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 44))
                    .foregroundStyle(.purple.gradient)
                
                Text("Scan a Receipt")
                    .font(.headline)
                
                Text("Select a receipt or bill image and AI will extract transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 30)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
            }
            
            if case .error(let message) = state {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(message)
                        .font(.caption)
                }
                .foregroundColor(.red)
                .padding(.horizontal)
            }
            
            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text(selectedImage == nil ? "Select Image" : "Change Image")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .cornerRadius(14)
            }
            .padding(.horizontal)
            .onChange(of: selectedItem) { _, newValue in
                loadImage(from: newValue)
            }
            
            if selectedImage != nil {
                Button {
                    processImage()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Process with AI")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.indigo)
                    .cornerRadius(14)
                }
                .padding(.horizontal)
            }
            
            if !recognizedText.isEmpty && state == .idle {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recognized Text")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                    
                    Text(recognizedText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(5)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Reading receipt & analyzing...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    private func previewView(_ expenses: [ParsedExpense]) -> some View {
        VStack(spacing: 0) {
            List {
                Section {
                    ForEach(Array(expenses.enumerated()), id: \.offset) { _, expense in
                        ParsedExpenseRow(expense: expense)
                    }
                } header: {
                    Text("AI extracted \(expenses.count) transaction\(expenses.count == 1 ? "" : "s")")
                }
            }
            .listStyle(.insetGrouped)
            
            VStack(spacing: 10) {
                Button {
                    addTransactions(expenses)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Add \(expenses.count) Transaction\(expenses.count == 1 ? "" : "s")")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(14)
                }
                
                Button("Try Again") {
                    withAnimation {
                        state = .idle
                        selectedImage = nil
                        selectedItem = nil
                        recognizedText = ""
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                }
            }
        }
    }
    
    private func processImage() {
        guard let image = selectedImage else { return }
        withAnimation { state = .processing }
        
        Task {
            do {
                let ocrText = try await AIExpenseService.recognizeText(in: image)
                await MainActor.run { recognizedText = ocrText }
                
                let expenseCats = categoryVM.expenseCategories.map { $0.wrappedName }
                let incomeCats = categoryVM.incomeCategories.map { $0.wrappedName }
                let result = try await AIExpenseService.parseExpenses(
                    from: "Receipt text:\n\(ocrText)\n\nExtract all transactions from this receipt.",
                    expenseCategories: expenseCats,
                    incomeCategories: incomeCats
                )
                await MainActor.run {
                    withAnimation { state = .preview(result) }
                }
            } catch {
                await MainActor.run {
                    withAnimation { state = .error(error.localizedDescription) }
                }
            }
        }
    }
    
    private func addTransactions(_ expenses: [ParsedExpense]) {
        let defaultAccount = accountVM.accounts.first
        
        for expense in expenses {
            let type = expense.type.lowercased() == "income" ? "income" : "expense"
            let categories = type == "income" ? categoryVM.incomeCategories : categoryVM.expenseCategories
            let matched = matchCategory(named: expense.categoryName, in: categories)
            
            guard let category = matched, let account = defaultAccount else { continue }
            
            try? transactionVM.addTransaction(
                amount: expense.amount,
                type: type,
                date: Date(),
                notes: expense.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : expense.notes,
                category: category,
                account: account
            )
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

// MARK: - Parsed Expense Preview Row

private struct ParsedExpenseRow: View {
    let expense: ParsedExpense
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var currencyManager: CurrencyManager
    
    private var isIncome: Bool { expense.type.lowercased() == "income" }
    
    private var matchedCategory: Category? {
        let categories = isIncome ? categoryVM.incomeCategories : categoryVM.expenseCategories
        return matchCategory(named: expense.categoryName, in: categories)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(isIncome ? "Income" : "Expense")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(isIncome ? Color.green : Color.red)
                    .cornerRadius(6)
                
                Spacer()
                
                Text(currencyManager.format(expense.amount))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundColor(isIncome ? .green : .red)
            }
            
            HStack(spacing: 8) {
                if let category = matchedCategory {
                    ZStack {
                        Circle()
                            .fill(category.uiColor.opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: category.wrappedIcon)
                            .font(.system(size: 12))
                            .foregroundColor(category.uiColor)
                    }
                }
                
                Text(expense.categoryName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !expense.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(expense.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Category Matching Helper

private func matchCategory(named name: String, in categories: [Category]) -> Category? {
    let lowered = name.lowercased()
    return categories.first { $0.wrappedName.lowercased() == lowered }
        ?? categories.first {
            $0.wrappedName.lowercased().contains(lowered) || lowered.contains($0.wrappedName.lowercased())
        }
        ?? categories.first
}
