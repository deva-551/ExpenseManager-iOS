//
//  FilterView.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import SwiftUI
import CoreData

struct FilterView: View {
    @EnvironmentObject var transactionVM: TransactionViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var accountVM: AccountViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategories: Set<NSManagedObjectID> = []
    @State private var selectedAccounts: Set<NSManagedObjectID> = []
    
    var body: some View {
        NavigationStack {
            List {
                // Categories Section
                Section("Categories") {
                    ForEach(categoryVM.categories, id: \.objectID) { category in
                        Button(action: {
                            toggleCategory(category)
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(category.uiColor.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: category.wrappedIcon)
                                        .font(.system(size: 14))
                                        .foregroundColor(category.uiColor)
                                }
                                
                                Text(category.wrappedName)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedCategories.contains(category.objectID) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary.opacity(0.5))
                                }
                            }
                        }
                    }
                }
                
                // Accounts Section
                Section("Accounts") {
                    ForEach(accountVM.accounts, id: \.objectID) { account in
                        Button(action: {
                            toggleAccount(account)
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: account.accountIcon)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 36)
                                
                                Text(account.wrappedName)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedAccounts.contains(account.objectID) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary.opacity(0.5))
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        transactionVM.clearFilters()
                        dismiss()
                    }
                    .disabled(!transactionVM.isFilterActive && selectedCategories.isEmpty && selectedAccounts.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        applyFilters()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Pre-select any active filters
                selectedCategories = Set(transactionVM.filterCategories.map { $0.objectID })
                selectedAccounts = Set(transactionVM.filterAccounts.map { $0.objectID })
            }
        }
    }
    
    private func toggleCategory(_ category: Category) {
        if selectedCategories.contains(category.objectID) {
            selectedCategories.remove(category.objectID)
        } else {
            selectedCategories.insert(category.objectID)
        }
    }
    
    private func toggleAccount(_ account: Account) {
        if selectedAccounts.contains(account.objectID) {
            selectedAccounts.remove(account.objectID)
        } else {
            selectedAccounts.insert(account.objectID)
        }
    }
    
    private func applyFilters() {
        let filteredCategories = categoryVM.categories.filter { selectedCategories.contains($0.objectID) }
        let filteredAccounts = accountVM.accounts.filter { selectedAccounts.contains($0.objectID) }
        transactionVM.applyFilters(categories: filteredCategories, accounts: filteredAccounts)
        dismiss()
    }
}
