//
//  GrowthChartView.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import SwiftUI
import Charts

struct GrowthChartView: View {
    let data: [GrowthPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Growth Over Time")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(data) { point in
                LineMark(
                    x: .value("Month", point.month),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                AreaMark(
                    x: .value("Month", point.month),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(.blue.opacity(0.1))
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let month = value.as(Int.self) {
                            Text("\(month)m")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text(formatChartValue(val))
                                .font(.caption)
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func formatChartValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        
        if value >= 1_000_000 {
            return "$\(formatter.string(from: NSNumber(value: value / 1_000_000)) ?? "0")M"
        } else if value >= 1_000 {
            return "$\(formatter.string(from: NSNumber(value: value / 1_000)) ?? "0")K"
        } else {
            return "$\(formatter.string(from: NSNumber(value: value)) ?? "0")"
        }
    }
} 