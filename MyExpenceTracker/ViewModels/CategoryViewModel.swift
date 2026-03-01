//
//  CategoryViewModel.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import Foundation
import CoreData
import Combine

class CategoryViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    
    @Published var categories: [Category] = []
    
    var incomeCategories: [Category] {
        categories.filter { $0.wrappedCategoryType == "income" }
    }
    
    var expenseCategories: [Category] {
        categories.filter { $0.wrappedCategoryType == "expense" }
    }
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
        fetchCategories()
    }
    
    func fetchCategories() {
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Category.isDefault, ascending: false),
            NSSortDescriptor(keyPath: \Category.name, ascending: true)
        ]
        
        do {
            categories = try context.fetch(fetchRequest)
        } catch {
            print("Error fetching categories: \(error)")
        }
    }
    
    func categoriesForType(_ type: String) -> [Category] {
        categories.filter { $0.wrappedCategoryType == type }
    }
    
    func addCategory(name: String, icon: String, color: String, categoryType: String = "expense") throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CategoryError.emptyName
        }
        
        // Check for duplicate name within the same category type
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name ==[c] %@ AND categoryType == %@",
                                             name.trimmingCharacters(in: .whitespacesAndNewlines),
                                             categoryType)
        
        do {
            let existing = try context.fetch(fetchRequest)
            if !existing.isEmpty {
                throw CategoryError.duplicateName
            }
        } catch let error as CategoryError {
            throw error
        } catch {
            throw CategoryError.saveFailed
        }
        
        let category = Category(context: context)
        category.id = UUID()
        category.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        category.icon = icon
        category.color = color
        category.categoryType = categoryType
        category.isDefault = false
        category.createdDate = Date()
        
        do {
            try context.save()
            fetchCategories()
        } catch {
            context.rollback()
            throw CategoryError.saveFailed
        }
    }
    
    /// Deletes a category. If `reassignTo` is provided, all transactions from the deleted category
    /// are moved to that category. Otherwise, the transactions' category is set to nil (unknown).
    func deleteCategory(_ category: Category, reassignTo replacement: Category? = nil) throws {
        let txSet = category.transactions as? Set<Transaction> ?? []
        
        for transaction in txSet {
            transaction.category = replacement
        }
        
        context.delete(category)
        
        do {
            try context.save()
            fetchCategories()
        } catch {
            context.rollback()
            throw CategoryError.saveFailed
        }
    }
    
    func ensureDefaultCategories() {
        DefaultCategories.createDefaultCategories(context: context)
        fetchCategories()
    }
}

enum CategoryError: LocalizedError {
    case emptyName
    case duplicateName
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Category name cannot be empty."
        case .duplicateName:
            return "A category with this name already exists."
        case .saveFailed:
            return "Failed to save the category. Please try again."
        }
    }
}
