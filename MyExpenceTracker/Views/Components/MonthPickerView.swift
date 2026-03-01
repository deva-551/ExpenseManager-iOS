//
//  MonthPickerView.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import SwiftUI

struct MonthPickerView: View {
    @EnvironmentObject var transactionVM: TransactionViewModel
    
    /// Whether the currently selected month is the current calendar month (or future).
    private var isCurrentOrFutureMonth: Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        if transactionVM.selectedYear > currentYear { return true }
        if transactionVM.selectedYear == currentYear && transactionVM.selectedMonth >= currentMonth { return true }
        return false
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
                withAnimation(.easeInOut(duration: 0.2)) {
                    transactionVM.goToPreviousMonth()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            
            Text(transactionVM.monthYearString())
                .font(.headline)
                .foregroundColor(.primary)
                .frame(minWidth: 140)
            
            Button {
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
                withAnimation(.easeInOut(duration: 0.2)) {
                    transactionVM.goToNextMonth()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundColor(isCurrentOrFutureMonth ? .secondary.opacity(0.3) : .accentColor)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .disabled(isCurrentOrFutureMonth)
        }
    }
}
