//
//  MainTabView.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var transactionVM = TransactionViewModel()
    @StateObject private var categoryVM = CategoryViewModel()
    @StateObject private var accountVM = AccountViewModel()
    @StateObject private var budgetVM = BudgetViewModel()
    @StateObject private var currencyManager = CurrencyManager.shared
    
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            AnalyticsScreen()
                .tabItem {
                    Label("Analytics", systemImage: "chart.pie.fill")
                }
            
            AccountsScreen()
                .tabItem {
                    Label("Accounts", systemImage: "creditcard.fill")
                }
            
            SettingsScreen()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .environmentObject(transactionVM)
        .environmentObject(categoryVM)
        .environmentObject(accountVM)
        .environmentObject(budgetVM)
        .environmentObject(currencyManager)
        .onAppear {
            categoryVM.ensureDefaultCategories()
        }
    }
}
