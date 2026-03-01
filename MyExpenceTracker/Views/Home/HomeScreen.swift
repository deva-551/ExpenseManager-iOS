//
//  HomeScreen.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var transactionVM: TransactionViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var currencyManager: CurrencyManager
    
    @State private var showAddTransaction = false
    @State private var showTextExpense = false
    @State private var showImageExpense = false
    @State private var showFilter = false
    @State private var isFABExpanded = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    // Summary Cards
                    summarySection
                    
                    // Filter Active Banner
                    if transactionVM.isFilterActive {
                        filterBanner
                    }
                    
                    // Transaction List
                    if transactionVM.transactions.isEmpty {
                        emptyStateView
                    } else {
                        transactionListView
                    }
                }
                .background(Color(.systemGroupedBackground))
                
                // Full-screen dim overlay when FAB expanded
                if isFABExpanded {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                isFABExpanded = false
                            }
                        }
                        .transition(.opacity)
                }
                
                // Expandable FAB
                expandableFAB
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(isFABExpanded ? .hidden : .visible, for: .tabBar)
            .animation(.easeInOut(duration: 0.25), value: isFABExpanded)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showFilter = true }) {
                        Image(systemName: transactionVM.isFilterActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                    }
                    .disabled(isFABExpanded)
                }
                
                ToolbarItem(placement: .principal) {
                    MonthPickerView()
                        .allowsHitTesting(!isFABExpanded)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CategoriesManagementView()) {
                        Image(systemName: "square.grid.2x2")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                    }
                    .disabled(isFABExpanded)
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionScreen()
            }
            .sheet(isPresented: $showTextExpense) {
                TextToExpenseView()
            }
            .sheet(isPresented: $showImageExpense) {
                ImageToExpenseView()
            }
            .sheet(isPresented: $showFilter) {
                FilterView()
            }
        }
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Income",
                amount: transactionVM.totalIncome(),
                color: .green,
                icon: "arrow.down.circle.fill"
            )
            
            SummaryCard(
                title: "Expense",
                amount: transactionVM.totalExpense(),
                color: .red,
                icon: "arrow.up.circle.fill"
            )
            
            SummaryCard(
                title: "Balance",
                amount: transactionVM.netSavings(),
                color: transactionVM.netSavings() >= 0 ? .blue : .orange,
                icon: "equal.circle.fill"
            )
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    // MARK: - Filter Active Banner
    private var filterBanner: some View {
        Button(action: { showFilter = true }) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text("Filters applied")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.85))
            .cornerRadius(20)
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.4))
            Text("No Transactions")
                .font(.title3.weight(.medium))
                .foregroundColor(.secondary)
            Text("Tap the + button to add your first transaction")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Transaction List
    private var transactionListView: some View {
        List {
            ForEach(transactionVM.groupedTransactions, id: \.date) { group in
                Section {
                    ForEach(group.transactions, id: \.objectID) { transaction in
                        NavigationLink(destination: TransactionDetailScreen(transaction: transaction)) {
                            TransactionRowView(transaction: transaction)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                transactionVM.deleteTransaction(transaction)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(Self.sectionDateFormatter.string(from: group.date))
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                            .textCase(nil)
                        
                        Spacer()
                        
                        let dayTotal = dayTotal(group.transactions)
                        Text(currencyManager.format(abs(dayTotal)))
                            .font(.caption.weight(.medium))
                            .foregroundColor(dayTotal >= 0 ? .green : .red)
                            .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Expandable FAB
    private var expandableFAB: some View {
        VStack(alignment: .trailing, spacing: 14) {
            if isFABExpanded {
                fabOption(icon: "camera.viewfinder", color: .purple) {
                    showImageExpense = true
                }
                
                fabOption(icon: "text.bubble.fill", color: .indigo) {
                    showTextExpense = true
                }
                
                fabOption(icon: "square.and.pencil", color: .green) {
                    showAddTransaction = true
                }
            }
            
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isFABExpanded.toggle()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isFABExpanded ? 45 : 0))
                    .frame(width: 56, height: 56)
                    .background(isFABExpanded ? Color(.systemGray2) : Color.accentColor)
                    .clipShape(Circle())
                    .shadow(
                        color: (isFABExpanded ? Color(.systemGray2) : Color.accentColor).opacity(0.4),
                        radius: 8, x: 0, y: 4
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
    
    private func fabOption(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                isFABExpanded = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                action()
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(color.gradient)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .transition(.scale(scale: 0.5, anchor: .bottomTrailing).combined(with: .opacity))
    }
    
    // MARK: - Cached DateFormatter
    private static let sectionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    private func dayTotal(_ transactions: [Transaction]) -> Double {
        let income = transactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
        let expense = transactions.filter { $0.isExpense }.reduce(0) { $0 + $1.amount }
        return income - expense
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(currencyManager.format(abs(amount)))
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Add Category Sheet
struct AddCategorySheet: View {
    @EnvironmentObject var categoryVM: CategoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    var categoryType: String = "expense"
    
    @State private var name = ""
    @State private var selectedIcon = "tag.fill"
    @State private var pickedColor: Color = Color(hex: "#FF6B6B") ?? .red
    @State private var selectedType: String = "expense"
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let icons = [
        "tag.fill", "cart.fill", "fork.knife", "car.fill", "house.fill",
        "heart.fill", "book.fill", "gift.fill", "airplane", "tv.fill",
        "gamecontroller.fill", "music.note", "phone.fill", "wifi",
        "bolt.fill", "drop.fill", "leaf.fill", "pawprint.fill",
        "dumbbell.fill", "cross.case.fill", "graduationcap.fill",
        "briefcase.fill", "banknote.fill", "creditcard.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category Name") {
                    TextField("Enter category name", text: $name)
                        .autocorrectionDisabled()
                }
                
                Section("Type") {
                    Picker("Category Type", selection: $selectedType) {
                        Text("Expense").tag("expense")
                        Text("Income").tag("income")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: {
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                                selectedIcon = icon
                            }) {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color.accentColor : Color(.systemGray5))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Color") {
                    ColorPicker("Category Color", selection: $pickedColor, supportsOpacity: false)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try categoryVM.addCategory(name: name, icon: selectedIcon, color: pickedColor.toHex(), categoryType: selectedType)
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            dismiss()
                        } catch {
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.error)
                            alertMessage = error.localizedDescription
                            showAlert = true
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                selectedType = categoryType
            }
        }
    }
}
