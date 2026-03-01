//
//  Transaction+Extensions.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import Foundation
import CoreData

extension Transaction {
    var isIncome: Bool {
        return type == "income"
    }
    
    var isExpense: Bool {
        return type == "expense"
    }
    
    var wrappedDate: Date {
        return date ?? Date()
    }
    
    var wrappedNotes: String {
        return notes ?? ""
    }
    
    var dayOfMonth: Int {
        let calendar = Calendar.current
        return calendar.component(.day, from: wrappedDate)
    }
}
