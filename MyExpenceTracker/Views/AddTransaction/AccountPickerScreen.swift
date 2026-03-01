//
//  AccountPickerScreen.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 25/02/26.
//

import SwiftUI
import CoreData

struct AccountPickerScreen: View {
    @EnvironmentObject var accountVM: AccountViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedAccount: Account?
    
    @State private var showAddAccount = false
    
    var body: some View {
        NavigationStack {
            List {
                if accountVM.accounts.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "building.columns")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No accounts yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Tap the + button to add a new account")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                } else {
                    Section {
                        ForEach(accountVM.accounts, id: \.objectID) { account in
                            accountRow(account)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddAccount = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddAccount) {
                AddAccountSheet()
            }
        }
    }
    
    private func accountRow(_ account: Account) -> some View {
        Button(action: {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            selectedAccount = account
            dismiss()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: account.accountIcon)
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.wrappedName)
                        .foregroundColor(.primary)
                    Text(account.wrappedType.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if selectedAccount == account {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.body.weight(.medium))
                }
            }
        }
    }
}
