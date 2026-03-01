//
//  DefaultCategories.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import Foundation
import CoreData

struct DefaultCategories {
    static let expenseCategories: [(name: String, icon: String, color: String)] = [
        ("Food", "fork.knife", "#FF6B6B"),
        ("Transport", "car.fill", "#4ECDC4"),
        ("Shopping", "bag.fill", "#45B7D1"),
        ("Bills", "doc.text.fill", "#FFA07A"),
        ("Entertainment", "tv.fill", "#98D8C8"),
        ("Healthcare", "cross.case.fill", "#F7DC6F"),
        ("Education", "book.fill", "#BB8FCE"),
        ("Travel", "airplane", "#85C1E2"),
        ("Other", "ellipsis.circle.fill", "#95A5A6")
    ]
    
    static let incomeCategories: [(name: String, icon: String, color: String)] = [
        ("Salary", "banknote.fill", "#2ECC71"),
        ("Freelance", "laptopcomputer", "#3498DB"),
        ("Investments", "chart.line.uptrend.xyaxis", "#F39C12"),
        ("Rental Income", "house.fill", "#9B59B6"),
        ("Gifts", "gift.fill", "#E74C3C"),
        ("Other Income", "ellipsis.circle.fill", "#1ABC9C")
    ]
    
    static func createDefaultCategories(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isDefault == YES")
        
        do {
            let existingCategories = try context.fetch(fetchRequest)
            if !existingCategories.isEmpty {
                return // Default categories already exist
            }
        } catch {
            print("Error checking for default categories: \(error)")
        }
        
        for categoryData in expenseCategories {
            let category = Category(context: context)
            category.id = UUID()
            category.name = categoryData.name
            category.icon = categoryData.icon
            category.color = categoryData.color
            category.categoryType = "expense"
            category.isDefault = true
            category.createdDate = Date()
        }
        
        for categoryData in incomeCategories {
            let category = Category(context: context)
            category.id = UUID()
            category.name = categoryData.name
            category.icon = categoryData.icon
            category.color = categoryData.color
            category.categoryType = "income"
            category.isDefault = true
            category.createdDate = Date()
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving default categories: \(error)")
        }
    }
}
