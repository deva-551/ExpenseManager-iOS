//
//  TransactionViewModel.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import Foundation
import CoreData
import SwiftUI
import Combine

class TransactionViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    
    @Published var transactions: [Transaction] = []
    @Published var selectedMonth: Int
    @Published var selectedYear: Int
    @Published var filterCategories: [Category] = []
    @Published var filterAccounts: [Account] = []
    @Published var isFilterActive: Bool = false
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
        let calendar = Calendar.current
        let now = Date()
        self.selectedMonth = calendar.component(.month, from: now)
        self.selectedYear = calendar.component(.year, from: now)
        fetchTransactions()
    }
    
    func fetchTransactions() {
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        
        let calendar = Calendar.current
        var startComponents = DateComponents()
        startComponents.year = selectedYear
        startComponents.month = selectedMonth
        startComponents.day = 1
        
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            return
        }
        
        var predicates: [NSPredicate] = [
            NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, endDate as NSDate)
        ]
        
        if isFilterActive {
            if !filterCategories.isEmpty {
                predicates.append(NSPredicate(format: "category IN %@", filterCategories))
            }
            if !filterAccounts.isEmpty {
                predicates.append(NSPredicate(format: "account IN %@", filterAccounts))
            }
        }
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        
        do {
            transactions = try context.fetch(fetchRequest)
        } catch {
            print("Error fetching transactions: \(error)")
        }
    }
    
    func addTransaction(amount: Double, type: String, date: Date, notes: String?, category: Category, account: Account) throws {
        guard amount > 0 else {
            throw TransactionError.invalidAmount
        }
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.amount = amount
        transaction.type = type
        transaction.date = date
        transaction.notes = notes
        transaction.category = category
        transaction.account = account
        
        do {
            try context.save()
            fetchTransactions()
        } catch {
            context.rollback()
            throw TransactionError.saveFailed
        }
    }
    
    func updateTransaction(_ transaction: Transaction, amount: Double, type: String, date: Date, notes: String?, category: Category, account: Account) throws {
        guard amount > 0 else {
            throw TransactionError.invalidAmount
        }
        
        transaction.amount = amount
        transaction.type = type
        transaction.date = date
        transaction.notes = notes
        transaction.category = category
        transaction.account = account
        
        do {
            try context.save()
            fetchTransactions()
        } catch {
            context.rollback()
            throw TransactionError.saveFailed
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        context.delete(transaction)
        
        do {
            try context.save()
            fetchTransactions()
        } catch {
            context.rollback()
            print("Error deleting transaction: \(error)")
        }
    }
    
    func goToPreviousMonth() {
        if selectedMonth == 1 {
            selectedMonth = 12
            selectedYear -= 1
        } else {
            selectedMonth -= 1
        }
        fetchTransactions()
    }
    
    func goToNextMonth() {
        if selectedMonth == 12 {
            selectedMonth = 1
            selectedYear += 1
        } else {
            selectedMonth += 1
        }
        fetchTransactions()
    }
    
    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    func monthYearString() -> String {
        var components = DateComponents()
        components.month = selectedMonth
        components.year = selectedYear
        components.day = 1
        let date = Calendar.current.date(from: components) ?? Date()
        return Self.monthYearFormatter.string(from: date)
    }
    
    func totalIncome() -> Double {
        return transactions
            .filter { $0.type == "income" }
            .reduce(0) { $0 + $1.amount }
    }
    
    func totalExpense() -> Double {
        return transactions
            .filter { $0.type == "expense" }
            .reduce(0) { $0 + $1.amount }
    }
    
    func netSavings() -> Double {
        return totalIncome() - totalExpense()
    }
    
    func applyFilters(categories: [Category], accounts: [Account]) {
        filterCategories = categories
        filterAccounts = accounts
        isFilterActive = !categories.isEmpty || !accounts.isEmpty
        fetchTransactions()
    }
    
    func clearFilters() {
        filterCategories = []
        filterAccounts = []
        isFilterActive = false
        fetchTransactions()
    }
    
    var groupedTransactions: [(date: Date, transactions: [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { transaction in
            calendar.startOfDay(for: transaction.wrappedDate)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, transactions: $0.value.sorted { $0.wrappedDate > $1.wrappedDate }) }
    }
}

enum TransactionError: LocalizedError {
    case invalidAmount
    case saveFailed
    case missingCategory
    case missingAccount
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Please enter a valid amount greater than zero."
        case .saveFailed:
            return "Failed to save the transaction. Please try again."
        case .missingCategory:
            return "Please select a category."
        case .missingAccount:
            return "Please select an account."
        }
    }
}
