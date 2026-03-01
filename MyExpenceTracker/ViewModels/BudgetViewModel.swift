//
//  BudgetViewModel.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import Foundation
import CoreData
import Combine

class BudgetViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    
    @Published var budgets: [Budget] = []
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
        fetchBudgets()
    }
    
    func fetchBudgets() {
        let fetchRequest: NSFetchRequest<Budget> = Budget.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Budget.amount, ascending: false)]
        
        do {
            budgets = try context.fetch(fetchRequest)
        } catch {
            print("Error fetching budgets: \(error)")
        }
    }
    
    func addBudget(amount: Double, category: Category, account: Account) throws {
        guard amount > 0 else {
            throw BudgetError.invalidAmount
        }
        
        // Check if budget already exists for this category + account combination
        let fetchRequest: NSFetchRequest<Budget> = Budget.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@ AND account == %@", category, account)
        
        do {
            let existing = try context.fetch(fetchRequest)
            if !existing.isEmpty {
                throw BudgetError.duplicateBudget
            }
        } catch let error as BudgetError {
            throw error
        } catch {
            throw BudgetError.saveFailed
        }
        
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.amount = amount
        budget.period = "monthly"
        budget.category = category
        budget.account = account
        
        do {
            try context.save()
            fetchBudgets()
        } catch {
            context.rollback()
            throw BudgetError.saveFailed
        }
    }
    
    func updateBudget(_ budget: Budget, newAmount: Double) throws {
        guard newAmount > 0 else {
            throw BudgetError.invalidAmount
        }
        
        budget.amount = newAmount
        
        do {
            try context.save()
            fetchBudgets()
        } catch {
            context.rollback()
            throw BudgetError.saveFailed
        }
    }
    
    func deleteBudget(_ budget: Budget) {
        context.delete(budget)
        
        do {
            try context.save()
            fetchBudgets()
        } catch {
            context.rollback()
            print("Error deleting budget: \(error)")
        }
    }
}

enum BudgetError: LocalizedError {
    case invalidAmount
    case duplicateBudget
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Please enter a valid budget amount greater than zero."
        case .duplicateBudget:
            return "A budget already exists for this category and account combination."
        case .saveFailed:
            return "Failed to save the budget. Please try again."
        }
    }
}
