//
//  Budget+Extensions.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import Foundation
import CoreData

extension Budget {
    var wrappedPeriod: String {
        return period ?? "monthly"
    }
    
    func spentAmount(month: Int, year: Int) -> Double {
        guard let category = category else { return 0 }
        let calendar = Calendar.current
        let transactionsSet = category.transactions as? Set<Transaction> ?? []
        
        return transactionsSet
            .filter { transaction in
                let components = calendar.dateComponents([.month, .year], from: transaction.wrappedDate)
                return components.month == month &&
                       components.year == year &&
                       transaction.type == "expense" &&
                       transaction.account == self.account
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    func remainingAmount(month: Int, year: Int) -> Double {
        return amount - spentAmount(month: month, year: year)
    }
    
    func progress(month: Int, year: Int) -> Double {
        guard amount > 0 else { return 0 }
        return min(spentAmount(month: month, year: year) / amount, 1.0)
    }
    
    var isOverBudget: Bool {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        return spentAmount(month: month, year: year) > amount
    }
}
