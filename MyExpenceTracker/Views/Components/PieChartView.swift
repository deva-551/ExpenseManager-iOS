//
//  PieChartView.swift
//  MyExpenceTracker
//
//  Created by Devendran A on 23/02/26.
//

import SwiftUI
import Charts

struct PieSliceData: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}

struct PieChartView: View {
    let slices: [PieSliceData]
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            if slices.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            } else {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value(slice.label, slice.value),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(slice.color)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                
                // Legend
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(slices) { slice in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(slice.color)
                                .frame(width: 8, height: 8)
                            Text(slice.label)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
