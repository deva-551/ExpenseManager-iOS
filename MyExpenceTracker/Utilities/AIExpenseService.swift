//
//  AIExpenseService.swift
//  MyExpenceTracker
//

import Foundation
import FoundationModels
import Vision
import UIKit

@Generable
struct ParsedExpense {
    @Guide(description: "The transaction amount as a positive number")
    var amount: Double
    
    @Guide(description: "Either 'expense' or 'income'")
    var type: String
    
    @Guide(description: "The category name from the available list that best matches this transaction")
    var categoryName: String
    
    @Guide(description: "A brief description of the transaction")
    var notes: String
}

@Generable
struct ParsedExpenseList {
    @Guide(description: "All transactions extracted from the text")
    var expenses: [ParsedExpense]
}

enum AIExpenseError: LocalizedError {
    case invalidImage
    case noTextFound
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not process the selected image."
        case .noTextFound:
            return "No text was found in the image."
        case .parsingFailed:
            return "Could not extract transaction details. Try rephrasing."
        }
    }
}

struct AIExpenseService {
    
    static func parseExpenses(from text: String, expenseCategories: [String], incomeCategories: [String]) async throws -> [ParsedExpense] {
        let instructions = """
        You are a financial transaction parser. Extract transaction details from the user's text.
        Available expense categories: \(expenseCategories.joined(separator: ", ")).
        Available income categories: \(incomeCategories.joined(separator: ", ")).
        Pick the closest matching category name exactly as listed.
        Set type to "income" for money received/earned, "expense" for money spent/paid.
        Always return a positive amount. If multiple transactions are described, extract all of them.
        """
        
        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: text, generating: ParsedExpenseList.self)
        let parsed = response.content
        
        guard !parsed.expenses.isEmpty else {
            throw AIExpenseError.parsingFailed
        }
        return parsed.expenses
    }
    
    static func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw AIExpenseError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest { request, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    let observations = request.results as? [VNRecognizedTextObservation] ?? []
                    let text = observations
                        .compactMap { $0.topCandidates(1).first?.string }
                        .joined(separator: "\n")
                    
                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        continuation.resume(throwing: AIExpenseError.noTextFound)
                    } else {
                        continuation.resume(returning: text)
                    }
                }
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
