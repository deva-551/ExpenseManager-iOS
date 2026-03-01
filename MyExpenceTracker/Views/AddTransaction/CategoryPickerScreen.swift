//
//  CategoryPickerScreen.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import SwiftUI
import CoreData

struct CategoryPickerScreen: View {
    @EnvironmentObject var categoryVM: CategoryViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: Category?
    let transactionType: String
    
    @State private var showAddCategory = false
    @State private var categoryToDelete: Category?
    @State private var showDeleteConfirmation = false
    @State private var showReassignPicker = false
    
    private var filteredCategories: [Category] {
        categoryVM.categoriesForType(transactionType)
    }
    
    private var otherCategoriesForReassign: [Category] {
        guard let cat = categoryToDelete else { return [] }
        return categoryVM.categoriesForType(cat.wrappedCategoryType).filter { $0.objectID != cat.objectID }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filteredCategories.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No categories yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Tap the + button to add a new category")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                } else {
                    let defaultCategories = filteredCategories.filter { $0.isDefault }
                    let customCategories = filteredCategories.filter { !$0.isDefault }
                    
                    if !defaultCategories.isEmpty {
                        Section("Default Categories") {
                            ForEach(defaultCategories, id: \.objectID) { category in
                                categoryRow(category)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            handleCategoryDelete(category)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    
                    if !customCategories.isEmpty {
                        Section("My Categories") {
                            ForEach(customCategories, id: \.objectID) { category in
                                categoryRow(category)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            handleCategoryDelete(category)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddCategory = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategorySheet(categoryType: transactionType)
            }
            .alert("Delete Category", isPresented: $showDeleteConfirmation) {
                if !otherCategoriesForReassign.isEmpty {
                    Button("Switch to Another") {
                        showReassignPicker = true
                    }
                }
                Button("Make Unknown") {
                    if let cat = categoryToDelete {
                        if selectedCategory == cat {
                            selectedCategory = nil
                        }
                        try? categoryVM.deleteCategory(cat, reassignTo: nil)
                        categoryToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    categoryToDelete = nil
                }
            } message: {
                if let cat = categoryToDelete {
                    let txCount = (cat.transactions as? Set<Transaction>)?.count ?? 0
                    if txCount > 0 {
                        Text("'\(cat.wrappedName)' has \(txCount) transaction\(txCount == 1 ? "" : "s"). What would you like to do with them?")
                    } else {
                        Text("Are you sure you want to delete '\(cat.wrappedName)'?")
                    }
                } else {
                    Text("Are you sure you want to delete this category?")
                }
            }
            .sheet(isPresented: $showReassignPicker) {
                ReassignCategoryPickerSheet(
                    categoryToDelete: $categoryToDelete,
                    selectedCategory: $selectedCategory,
                    otherCategories: otherCategoriesForReassign
                )
            }
        }
    }
    
    private func handleCategoryDelete(_ category: Category) {
        let txCount = (category.transactions as? Set<Transaction>)?.count ?? 0
        if txCount == 0 {
            // No transactions — delete directly
            if selectedCategory == category {
                selectedCategory = nil
            }
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            try? categoryVM.deleteCategory(category, reassignTo: nil)
        } else {
            // Has transactions — show reassign alert
            categoryToDelete = category
            showDeleteConfirmation = true
        }
    }
    
    private func categoryRow(_ category: Category) -> some View {
        Button(action: {
            selectedCategory = category
            dismiss()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(category.uiColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: category.wrappedIcon)
                        .font(.system(size: 16))
                        .foregroundColor(category.uiColor)
                }
                
                Text(category.wrappedName)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if selectedCategory == category {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.body.weight(.medium))
                }
            }
        }
    }
}

// MARK: - Reassign Category Picker Sheet (for CategoryPickerScreen)
struct ReassignCategoryPickerSheet: View {
    @EnvironmentObject var categoryVM: CategoryViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var categoryToDelete: Category?
    @Binding var selectedCategory: Category?
    let otherCategories: [Category]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Choose a category to move existing transactions to:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section("Available Categories") {
                    ForEach(otherCategories, id: \.objectID) { category in
                        Button(action: {
                            if let cat = categoryToDelete {
                                if selectedCategory == cat {
                                    selectedCategory = nil
                                }
                                try? categoryVM.deleteCategory(cat, reassignTo: category)
                                categoryToDelete = nil
                            }
                            dismiss()
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
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Switch Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        categoryToDelete = nil
                        dismiss()
                    }
                }
            }
        }
    }
}
