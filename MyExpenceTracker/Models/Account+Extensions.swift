//
//  Account+Extensions.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import Foundation
import CoreData

extension Account {
    var wrappedName: String {
        return name ?? "Unknown"
    }
    
    var wrappedType: String {
        return type ?? "bank"
    }
    
    var isCash: Bool {
        return wrappedType == "cash"
    }
    
    var isBank: Bool {
        return wrappedType == "bank"
    }
    
    var accountIcon: String {
        return isCash ? "banknote.fill" : "building.columns.fill"
    }
    
    var transactionsArray: [Transaction] {
        let set = transactions as? Set<Transaction> ?? []
        return set.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
    }
    
    var currentBalance: Double {
        let incomeTotal = transactionsArray
            .filter { $0.type == "income" }
            .reduce(0) { $0 + $1.amount }
        
        let expenseTotal = transactionsArray
            .filter { $0.type == "expense" }
            .reduce(0) { $0 + $1.amount }
        
        return initialBalance + incomeTotal - expenseTotal
    }
    
    func spendingForMonth(month: Int, year: Int) -> Double {
        let calendar = Calendar.current
        return transactionsArray
            .filter { transaction in
                let components = calendar.dateComponents([.month, .year], from: transaction.wrappedDate)
                return components.month == month && components.year == year && transaction.type == "expense"
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    func incomeForMonth(month: Int, year: Int) -> Double {
        let calendar = Calendar.current
        return transactionsArray
            .filter { transaction in
                let components = calendar.dateComponents([.month, .year], from: transaction.wrappedDate)
                return components.month == month && components.year == year && transaction.type == "income"
            }
            .reduce(0) { $0 + $1.amount }
    }
}
