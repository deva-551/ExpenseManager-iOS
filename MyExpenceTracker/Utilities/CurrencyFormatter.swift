//
//  CurrencyFormatter.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import Foundation
import Combine

class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    @Published var selectedCurrencyCode: String {
        didSet {
            UserDefaults.standard.set(selectedCurrencyCode, forKey: "selectedCurrency")
        }
    }
    
    static let availableCurrencies: [(code: String, name: String, symbol: String)] = [
        ("USD", "US Dollar", "$"),
        ("EUR", "Euro", "€"),
        ("GBP", "British Pound", "£"),
        ("INR", "Indian Rupee", "₹"),
        ("JPY", "Japanese Yen", "¥"),
        ("AUD", "Australian Dollar", "A$"),
        ("CAD", "Canadian Dollar", "C$"),
        ("CHF", "Swiss Franc", "CHF"),
        ("CNY", "Chinese Yuan", "¥"),
        ("SGD", "Singapore Dollar", "S$"),
        ("AED", "UAE Dirham", "د.إ"),
        ("SAR", "Saudi Riyal", "﷼")
    ]
    
    private init() {
        self.selectedCurrencyCode = UserDefaults.standard.string(forKey: "selectedCurrency") ?? "USD"
    }
    
    func format(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    func symbol() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrencyCode
        return formatter.currencySymbol ?? "$"
    }
}
