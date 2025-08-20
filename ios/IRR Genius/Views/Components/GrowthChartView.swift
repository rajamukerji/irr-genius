//
//  GrowthChartView.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import Charts
import SwiftUI

struct GrowthChartView: View {
    let data: [GrowthPoint]
    @State private var dragLocation: CGFloat? = nil
    @State private var selectedPoint: GrowthPoint? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Growth Over Time")
                .font(.headline)
                .foregroundColor(.primary)
            

            GeometryReader { geo in
                ZStack {
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
                    .chartXScale(domain: (data.map { $0.month }.min() ?? 0)...(data.map { $0.month }.max() ?? 1))
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
                    .chartYScale(domain: 0...(data.map { $0.value }.max() ?? 1))
                    .frame(height: 200)

                    // Draggable overlay
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    dragLocation = value.location.x
                                    let relativeX = max(0, min(value.location.x, geo.size.width))
                                    let minMonth = data.map { $0.month }.min() ?? 0
                                    let maxMonth = data.map { $0.month }.max() ?? 1
                                    let monthAtLocation = minMonth + Int((relativeX / geo.size.width) * CGFloat(maxMonth - minMonth))
                                    if let closest = data.min(by: { abs($0.month - monthAtLocation) < abs($1.month - monthAtLocation) }) {
                                        selectedPoint = closest
                                    }
                                }
                                .onEnded { _ in
                                    dragLocation = nil
                                    selectedPoint = nil
                                }
                        )
                        .frame(width: geo.size.width, height: geo.size.height)
                        .allowsHitTesting(true)

                    // Tooltip and vertical line
                    if let dragX = dragLocation, let point = selectedPoint {
                        let xPos = max(0, min(dragX, geo.size.width))
                        let maxValue = data.map { $0.value }.max() ?? 1
                        let yRatio = 1 - (point.value / maxValue)
                        let yPos = yRatio * geo.size.height

                        // Vertical line
                        Path { path in
                            path.move(to: CGPoint(x: xPos, y: 0))
                            path.addLine(to: CGPoint(x: xPos, y: geo.size.height))
                        }
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 1, dash: [5]))

                        // Tooltip with X and Y values
                        VStack(spacing: 2) {
                            Text("\(point.month)m")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(formatChartValue(point.value, decimals: 2))
                                .font(.caption)
                                .padding(6)
                                .background(Color.white)
                                .cornerRadius(6)
                                .shadow(radius: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.blue, lineWidth: 1)
                                )
                            Spacer()
                        }
                        .frame(width: 80)
                        .position(x: xPos, y: max(20, yPos - 24))
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

    private func formatChartValue(_ value: Double, decimals: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = decimals
        formatter.minimumFractionDigits = decimals
        formatter.groupingSeparator = ","

        if value >= 1_000_000 {
            return "$\(formatter.string(from: NSNumber(value: value / 1_000_000)) ?? "0")M"
        } else if value >= 1000 {
            return "$\(formatter.string(from: NSNumber(value: value / 1000)) ?? "0")K"
        } else {
            return "$\(formatter.string(from: NSNumber(value: value)) ?? "0")"
        }
    }
}
