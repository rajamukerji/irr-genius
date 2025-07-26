//
//  PDFExportService.swift
//  IRR Genius
//
//  Created by Kiro on 7/24/25.
//

import Foundation
import PDFKit
import SwiftUI
import Charts

// MARK: - PDF Export Service Protocol
protocol PDFExportService {
    func exportToPDF(_ calculation: SavedCalculation) async throws -> URL
    func exportMultipleCalculationsToPDF(_ calculations: [SavedCalculation]) async throws -> URL
}

// MARK: - PDF Export Errors
enum PDFExportError: LocalizedError {
    case invalidCalculation
    case pdfGenerationFailed
    case fileWriteFailed(Error)
    case chartRenderingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCalculation:
            return "Invalid calculation data for PDF export"
        case .pdfGenerationFailed:
            return "Failed to generate PDF document"
        case .fileWriteFailed(let error):
            return "Failed to write PDF file: \(error.localizedDescription)"
        case .chartRenderingFailed:
            return "Failed to render chart in PDF"
        }
    }
}

// MARK: - PDF Export Service Implementation
class PDFExportServiceImpl: PDFExportService {
    
    private let pageSize = CGSize(width: 612, height: 792) // US Letter size
    private let margin: CGFloat = 50
    
    func exportToPDF(_ calculation: SavedCalculation) async throws -> URL {
        let pdfData = try await generatePDFData(for: [calculation], title: calculation.name)
        return try savePDFToFile(pdfData, filename: "\(calculation.name).pdf")
    }
    
    func exportMultipleCalculationsToPDF(_ calculations: [SavedCalculation]) async throws -> URL {
        let title = "IRR Genius Calculations Export"
        let pdfData = try await generatePDFData(for: calculations, title: title)
        let filename = "IRR_Calculations_\(DateFormatter.filenameDateFormatter.string(from: Date())).pdf"
        return try savePDFToFile(pdfData, filename: filename)
    }
    
    // MARK: - Private Methods
    
    private func generatePDFData(for calculations: [SavedCalculation], title: String) async throws -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "IRR Genius",
            kCGPDFContextAuthor: "IRR Genius App",
            kCGPDFContextTitle: title,
            kCGPDFContextSubject: "Financial IRR Calculations"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)
        
        let pdfData = renderer.pdfData { context in
            for (index, calculation) in calculations.enumerated() {
                if index > 0 {
                    context.beginPage()
                }
                try? drawCalculationPage(calculation, in: context.cgContext)
            }
        }
        
        return pdfData
    }
    
    private func drawCalculationPage(_ calculation: SavedCalculation, in context: CGContext) throws {
        let contentRect = CGRect(
            x: margin,
            y: margin,
            width: pageSize.width - 2 * margin,
            height: pageSize.height - 2 * margin
        )
        
        var currentY: CGFloat = margin
        
        // Draw header
        currentY = drawHeader(calculation, in: context, startY: currentY, contentWidth: contentRect.width)
        currentY += 20
        
        // Draw calculation details
        currentY = drawCalculationDetails(calculation, in: context, startY: currentY, contentWidth: contentRect.width)
        currentY += 20
        
        // Draw results
        currentY = drawResults(calculation, in: context, startY: currentY, contentWidth: contentRect.width)
        currentY += 20
        
        // Draw chart if available
        if let growthPoints = calculation.growthPoints, !growthPoints.isEmpty {
            currentY = try drawChart(growthPoints, in: context, startY: currentY, contentWidth: contentRect.width)
            currentY += 20
        }
        
        // Draw follow-on investments if available
        if let followOns = calculation.followOnInvestments, !followOns.isEmpty {
            currentY = drawFollowOnInvestments(followOns, in: context, startY: currentY, contentWidth: contentRect.width)
        }
        
        // Draw footer
        drawFooter(in: context, contentRect: contentRect)
    }
    
    private func drawHeader(_ calculation: SavedCalculation, in context: CGContext, startY: CGFloat, contentWidth: CGFloat) -> CGFloat {
        var currentY = startY
        
        // App title
        let appTitle = "IRR Genius"
        currentY = drawText(appTitle, font: .boldSystemFont(ofSize: 24), color: .systemBlue, 
                           in: context, at: CGPoint(x: margin, y: currentY), maxWidth: contentWidth)
        currentY += 10
        
        // Calculation name
        currentY = drawText(calculation.name, font: .boldSystemFont(ofSize: 18), color: .black,
                           in: context, at: CGPoint(x: margin, y: currentY), maxWidth: contentWidth)
        currentY += 5
        
        // Calculation type
        let typeText = "Type: \(calculation.calculationType.displayName)"
        currentY = drawText(typeText, font: .systemFont(ofSize: 14), color: .darkGray,
                           in: context, at: CGPoint(x: margin, y: currentY), maxWidth: contentWidth)
        currentY += 5
        
        // Date
        let dateText = "Generated: \(DateFormatter.displayDateFormatter.string(from: Date()))"
        currentY = drawText(dateText, font: .systemFont(ofSize: 12), color: .darkGray,
                           in: context, at: CGPoint(x: margin, y: currentY), maxWidth: contentWidth)
        
        // Draw separator line
        currentY += 15
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: margin, y: currentY))
        context.addLine(to: CGPoint(x: margin + contentWidth, y: currentY))
        context.strokePath()
        
        return currentY + 10
    }
    
    private func drawCalculationDetails(_ calculation: SavedCalculation, in context: CGContext, startY: CGFloat, contentWidth: CGFloat) -> CGFloat {
        var currentY = startY
        
        // Section title
        currentY = drawText("Calculation Details", font: .boldSystemFont(ofSize: 16), color: .black,
                           in: context, at: CGPoint(x: margin, y: currentY), maxWidth: contentWidth)
        currentY += 15
        
        // Input parameters based on calculation type
        let details = getCalculationDetails(calculation)
        for detail in details {
            currentY = drawText("• \(detail)", font: .systemFont(ofSize: 12), color: .black,
                               in: context, at: CGPoint(x: margin + 10, y: currentY), maxWidth: contentWidth - 10)
            currentY += 5
        }
        
        // Notes if available
        if let notes = calculation.notes, !notes.isEmpty {
            currentY += 10
            currentY = drawText("Notes:", font: .boldSystemFont(ofSize: 14), color: .black,
                               in: context, at: CGPoint(x: margin, y: currentY), maxWidth: contentWidth)
            currentY += 5
            currentY = drawText(notes, font: .systemFont(ofSize: 12), color: .darkGray,
                               in: context, at: CGPoint(x: margin, y: currentY), maxWidth: contentWidth)
        }
        
        return currentY + 10
    }
    
    private func drawResults(_ calculation: SavedCalculation, in context: CGContext, startY: CGFloat, contentWidth: CGFloat) -> CGFloat {
        var currentY = startY
        
        // Section title
        currentY = drawText("Results", font: .boldSystemFont(ofSize: 16), color: .black,
                           in: context, at: CGPoint(x: margin, y: currentY), maxWidth: contentWidth)
        currentY += 15
        
        // Main result
        if let result = calculation.calculatedResult {
            let resultText = getResultText(calculation, result: result)
            currentY = drawText(resultText, font: .boldSystemFont(ofSize: 14), color: .systemBlue,
                               in: context, at: CGPoint(x: margin, y: currentY), maxWidth: contentWidth)
            currentY += 10
        }
        
        // Summary
        let summaryText = calculation.summary
        currentY = drawText(summaryText, font: .systemFont(ofSize: 12), color: .darkGray,
                           in: context, at: CGPoint(x: margin, y: currentY), maxWidth: contentWidth)
        
        return currentY + 10
    }
    
    private func drawChart(_ growthPoints: [GrowthPoint], in context: CGContext, startY: CGFloat, contentWidth: CGFloat) throws -> CGFloat {
        var currentY = startY
        
        // Section title
        currentY = drawText("Growth Chart", font: .boldSystemFont(ofSize: 16), color: .black,
                           in: context, at: CGPoint(x: margin, y: currentY), maxWidth: contentWidth)
        currentY += 15
        
        let chartHeight: CGFloat = 200
        let chartRect = CGRect(x: margin, y: currentY, width: contentWidth, height: chartHeight)
        
        // Draw chart background
        context.setFillColor(UIColor.systemGray6.cgColor)
        context.fill(chartRect)
        
        // Draw chart border
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(1)
        context.stroke(chartRect)
        
        // Draw chart content
        try drawChartContent(growthPoints, in: context, rect: chartRect)
        
        return currentY + chartHeight + 10
    }
    
    private func drawChartContent(_ growthPoints: [GrowthPoint], in context: CGContext, rect: CGRect) throws {
        guard !growthPoints.isEmpty else { return }
        
        let padding: CGFloat = 20
        let chartArea = CGRect(
            x: rect.minX + padding,
            y: rect.minY + padding,
            width: rect.width - 2 * padding,
            height: rect.height - 2 * padding
        )
        
        // Find min/max values
        let minMonth = growthPoints.map { $0.month }.min() ?? 0
        let maxMonth = growthPoints.map { $0.month }.max() ?? 1
        let minValue = growthPoints.map { $0.value }.min() ?? 0
        let maxValue = growthPoints.map { $0.value }.max() ?? 1
        
        let monthRange = maxMonth - minMonth
        let valueRange = maxValue - minValue
        
        guard monthRange > 0 && valueRange > 0 else { return }
        
        // Draw grid lines
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(0.5)
        
        // Vertical grid lines
        for i in 0...4 {
            let x = chartArea.minX + (CGFloat(i) / 4.0) * chartArea.width
            context.move(to: CGPoint(x: x, y: chartArea.minY))
            context.addLine(to: CGPoint(x: x, y: chartArea.maxY))
        }
        
        // Horizontal grid lines
        for i in 0...4 {
            let y = chartArea.minY + (CGFloat(i) / 4.0) * chartArea.height
            context.move(to: CGPoint(x: chartArea.minX, y: y))
            context.addLine(to: CGPoint(x: chartArea.maxX, y: y))
        }
        context.strokePath()
        
        // Draw data line
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(2)
        
        let path = CGMutablePath()
        for (index, point) in growthPoints.enumerated() {
            let x = chartArea.minX + (CGFloat(point.month - minMonth) / CGFloat(monthRange)) * chartArea.width
            let y = chartArea.maxY - (CGFloat(point.value - minValue) / CGFloat(valueRange)) * chartArea.height
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        context.addPath(path)
        context.strokePath()
        
        // Draw data points
        context.setFillColor(UIColor.systemBlue.cgColor)
        for point in growthPoints {
            let x = chartArea.minX + (CGFloat(point.month - minMonth) / CGFloat(monthRange)) * chartArea.width
            let y = chartArea.maxY - (CGFloat(point.value - minValue) / CGFloat(valueRange)) * chartArea.height
            
            context.fillEllipse(in: CGRect(x: x - 3, y: y - 3, width: 6, height: 6))
        }
        
        // Draw axis labels
        drawChartLabels(minMonth: minMonth, maxMonth: maxMonth, minValue: minValue, maxValue: maxValue,
                       in: context, chartArea: chartArea)
    }
    
    private func drawChartLabels(minMonth: Int, maxMonth: Int, minValue: Double, maxValue: Double,
                                in context: CGContext, chartArea: CGRect) {
        // X-axis labels (months)
        for i in 0...4 {
            let month = minMonth + Int(Double(i) / 4.0 * Double(maxMonth - minMonth))
            let x = chartArea.minX + (CGFloat(i) / 4.0) * chartArea.width
            let y = chartArea.maxY + 15
            
            let text = "\(month)m"
            drawText(text, font: .systemFont(ofSize: 10), color: .darkGray,
                    in: context, at: CGPoint(x: x - 10, y: y), maxWidth: 20, alignment: .center)
        }
        
        // Y-axis labels (values)
        for i in 0...4 {
            let value = minValue + (Double(i) / 4.0) * (maxValue - minValue)
            let x = chartArea.minX - 5
            let y = chartArea.maxY - (CGFloat(i) / 4.0) * chartArea.height - 5
            
            let text = NumberFormatter.currency.string(from: NSNumber(value: value)) ?? "$0"
            drawText(text, font: .systemFont(ofSize: 10), color: .darkGray,
                    in: context, at: CGPoint(x: x - 50, y: y), maxWidth: 45, alignment: .right)
        }
    }
    
    private func drawFollowOnInvestments(_ investments: [FollowOnInvestment], in context: CGContext, startY: CGFloat, contentWidth: CGFloat) -> CGFloat {
        var currentY = startY
        
        // Section title
        currentY = drawText("Follow-On Investments", font: .boldSystemFont(ofSize: 16), color: .black,
                           in: context, at: CGPoint(x: margin, y: currentY), maxWidth: contentWidth)
        currentY += 15
        
        for (index, investment) in investments.enumerated() {
            let investmentText = "Investment \(index + 1): \(NumberFormatter.currency.string(from: NSNumber(value: investment.amount)) ?? "$0")"
            currentY = drawText(investmentText, font: .systemFont(ofSize: 12), color: .black,
                               in: context, at: CGPoint(x: margin + 10, y: currentY), maxWidth: contentWidth - 10)
            currentY += 5
        }
        
        return currentY + 10
    }
    
    private func drawFooter(in context: CGContext, contentRect: CGRect) {
        let footerY = contentRect.maxY - 20
        
        // Draw separator line
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: margin, y: footerY - 10))
        context.addLine(to: CGPoint(x: margin + contentRect.width, y: footerY - 10))
        context.strokePath()
        
        // Footer text
        let footerText = "Generated by IRR Genius - Professional IRR Calculator"
        drawText(footerText, font: .systemFont(ofSize: 10), color: .darkGray,
                in: context, at: CGPoint(x: margin, y: footerY), maxWidth: contentRect.width, alignment: .center)
    }
    
    @discardableResult
    private func drawText(_ text: String, font: UIFont, color: UIColor, in context: CGContext,
                         at point: CGPoint, maxWidth: CGFloat, alignment: NSTextAlignment = .left) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.boundingRect(with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
                                                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                    context: nil).size
        
        var drawPoint = point
        if alignment == .center {
            drawPoint.x = point.x + (maxWidth - textSize.width) / 2
        } else if alignment == .right {
            drawPoint.x = point.x + maxWidth - textSize.width
        }
        
        let textRect = CGRect(origin: drawPoint, size: textSize)
        attributedString.draw(in: textRect)
        
        return point.y + textSize.height + 5
    }
    
    private func getCalculationDetails(_ calculation: SavedCalculation) -> [String] {
        var details: [String] = []
        
        switch calculation.calculationType {
        case .calculateIRR:
            if let initial = calculation.initialInvestment {
                details.append("Initial Investment: \(NumberFormatter.currency.string(from: NSNumber(value: initial)) ?? "$0")")
            }
            if let outcome = calculation.outcomeAmount {
                details.append("Outcome Amount: \(NumberFormatter.currency.string(from: NSNumber(value: outcome)) ?? "$0")")
            }
            if let time = calculation.timeInMonths {
                details.append("Time Period: \(Int(time)) months")
            }
            
        case .calculateOutcome:
            if let initial = calculation.initialInvestment {
                details.append("Initial Investment: \(NumberFormatter.currency.string(from: NSNumber(value: initial)) ?? "$0")")
            }
            if let irr = calculation.irr {
                details.append("Target IRR: \(String(format: "%.2f", irr))%")
            }
            if let time = calculation.timeInMonths {
                details.append("Time Period: \(Int(time)) months")
            }
            
        case .calculateInitial:
            if let outcome = calculation.outcomeAmount {
                details.append("Target Outcome: \(NumberFormatter.currency.string(from: NSNumber(value: outcome)) ?? "$0")")
            }
            if let irr = calculation.irr {
                details.append("Target IRR: \(String(format: "%.2f", irr))%")
            }
            if let time = calculation.timeInMonths {
                details.append("Time Period: \(Int(time)) months")
            }
            
        case .calculateBlendedIRR:
            if let initial = calculation.initialInvestment {
                details.append("Initial Investment: \(NumberFormatter.currency.string(from: NSNumber(value: initial)) ?? "$0")")
            }
            if let outcome = calculation.outcomeAmount {
                details.append("Final Outcome: \(NumberFormatter.currency.string(from: NSNumber(value: outcome)) ?? "$0")")
            }
            if let time = calculation.timeInMonths {
                details.append("Time Period: \(Int(time)) months")
            }
            if let followOns = calculation.followOnInvestments {
                details.append("Follow-On Investments: \(followOns.count)")
            }
            
        case .portfolioUnitInvestment:
            if let initial = calculation.initialInvestment {
                details.append("Investment Amount: \(NumberFormatter.currency.string(from: NSNumber(value: initial)) ?? "$0")")
            }
            if let unitPrice = calculation.unitPrice {
                details.append("Unit Price: \(NumberFormatter.currency.string(from: NSNumber(value: unitPrice)) ?? "$0")")
            }
            if let successRate = calculation.successRate {
                details.append("Success Rate: \(String(format: "%.1f", successRate))%")
            }
            if let outcomePerUnit = calculation.outcomePerUnit {
                details.append("Outcome Per Unit: \(NumberFormatter.currency.string(from: NSNumber(value: outcomePerUnit)) ?? "$0")")
            }
            if let investorShare = calculation.investorShare {
                details.append("Investor Share: \(String(format: "%.1f", investorShare))%")
            }
            if let time = calculation.timeInMonths {
                details.append("Time Period: \(Int(time)) months")
            }
        }
        
        return details
    }
    
    private func getResultText(_ calculation: SavedCalculation, result: Double) -> String {
        switch calculation.calculationType {
        case .calculateIRR, .calculateBlendedIRR, .portfolioUnitInvestment:
            return "IRR: \(String(format: "%.2f", result))%"
        case .calculateOutcome:
            return "Outcome: \(NumberFormatter.currency.string(from: NSNumber(value: result)) ?? "$0")"
        case .calculateInitial:
            return "Initial Investment: \(NumberFormatter.currency.string(from: NSNumber(value: result)) ?? "$0")"
        }
    }
    
    private func savePDFToFile(_ pdfData: Data, filename: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try pdfData.write(to: pdfURL)
            return pdfURL
        } catch {
            throw PDFExportError.fileWriteFailed(error)
        }
    }
}

// MARK: - Extensions
extension CalculationMode {
    var displayName: String {
        switch self {
        case .calculateIRR:
            return "Calculate IRR"
        case .calculateOutcome:
            return "Calculate Outcome"
        case .calculateInitial:
            return "Calculate Initial Investment"
        case .calculateBlendedIRR:
            return "Calculate Blended IRR"
        case .portfolioUnitInvestment:
            return "Portfolio Unit Investment"
        }
    }
}

extension DateFormatter {
    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}

extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}