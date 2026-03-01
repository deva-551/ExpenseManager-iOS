//
//  Category+Extensions.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import Foundation
import SwiftUI

extension Category {
    var wrappedName: String {
        return name ?? "Unknown"
    }
    
    var wrappedIcon: String {
        return icon ?? "questionmark.circle"
    }
    
    var wrappedColor: String {
        return color ?? "#95A5A6"
    }
    
    var wrappedCategoryType: String {
        return categoryType ?? "expense"
    }
    
    var uiColor: Color {
        return Color(hex: wrappedColor) ?? .gray
    }
    
    var transactionsArray: [Transaction] {
        let set = transactions as? Set<Transaction> ?? []
        return set.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    func toHex() -> String {
        // Convert to sRGB first so we always get 3+ components
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        // getRed handles any color space (grayscale, P3, etc.)
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return "#95A5A6"
        }
        
        let ri = Int(min(max(r, 0), 1) * 255.0)
        let gi = Int(min(max(g, 0), 1) * 255.0)
        let bi = Int(min(max(b, 0), 1) * 255.0)
        
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
