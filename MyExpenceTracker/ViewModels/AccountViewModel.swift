//
//  AccountViewModel.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import Foundation
import CoreData
import Combine

class AccountViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    
    @Published var accounts: [Account] = []
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
        fetchAccounts()
        ensureDefaultAccounts()
    }
    
    func fetchAccounts() {
        let fetchRequest: NSFetchRequest<Account> = Account.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Account.createdDate, ascending: true)]
        
        do {
            accounts = try context.fetch(fetchRequest)
        } catch {
            print("Error fetching accounts: \(error)")
        }
    }
    
    func addAccount(name: String, type: String, initialBalance: Double) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AccountError.emptyName
        }
        
        guard initialBalance >= 0 else {
            throw AccountError.invalidBalance
        }
        
        // Check for duplicate name
        let fetchRequest: NSFetchRequest<Account> = Account.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name ==[c] %@", name.trimmingCharacters(in: .whitespacesAndNewlines))
        
        do {
            let existing = try context.fetch(fetchRequest)
            if !existing.isEmpty {
                throw AccountError.duplicateName
            }
        } catch let error as AccountError {
            throw error
        } catch {
            throw AccountError.saveFailed
        }
        
        let account = Account(context: context)
        account.id = UUID()
        account.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        account.type = type
        account.initialBalance = initialBalance
        account.createdDate = Date()
        
        do {
            try context.save()
            fetchAccounts()
        } catch {
            context.rollback()
            throw AccountError.saveFailed
        }
    }
    
    /// Deletes an account. If `reassignTo` is provided, all transactions from the deleted account
    /// are moved to that account. Otherwise, the transactions' account is set to nil (unknown).
    func deleteAccount(_ account: Account, reassignTo replacement: Account? = nil) {
        let txSet = account.transactions as? Set<Transaction> ?? []
        
        for transaction in txSet {
            transaction.account = replacement
        }
        
        context.delete(account)
        
        do {
            try context.save()
            fetchAccounts()
        } catch {
            context.rollback()
            print("Error deleting account: \(error)")
        }
    }
    
    func ensureDefaultAccounts() {
        if accounts.isEmpty {
            let cashAccount = Account(context: context)
            cashAccount.id = UUID()
            cashAccount.name = "Cash"
            cashAccount.type = "cash"
            cashAccount.initialBalance = 0
            cashAccount.createdDate = Date()
            
            let bankAccount = Account(context: context)
            bankAccount.id = UUID()
            bankAccount.name = "Bank Account"
            bankAccount.type = "bank"
            bankAccount.initialBalance = 0
            bankAccount.createdDate = Date()
            
            do {
                try context.save()
                fetchAccounts()
            } catch {
                print("Error creating default accounts: \(error)")
            }
        }
    }
}

enum AccountError: LocalizedError {
    case emptyName
    case invalidBalance
    case duplicateName
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Account name cannot be empty."
        case .invalidBalance:
            return "Initial balance cannot be negative."
        case .duplicateName:
            return "An account with this name already exists."
        case .saveFailed:
            return "Failed to save the account. Please try again."
        }
    }
}
