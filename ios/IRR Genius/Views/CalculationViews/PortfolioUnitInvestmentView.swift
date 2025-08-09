//
//  PortfolioUnitInvestmentView.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/24/25.
//

import Foundation
import SwiftUI
import UIKit

struct PortfolioUnitInvestmentView: View {
    @Binding var initialInvestment: String
    @Binding var unitPrice: String
    @Binding var numberOfUnits: String
    @Binding var successRate: String
    @Binding var timeInMonths: String
    @Binding var followOnInvestments: [FollowOnInvestment]
    @Binding var calculatedResult: Double?
    @Binding var isCalculating: Bool
    @Binding var errorMessage: String?
    @Binding var showingAddInvestment: Bool
    let onCalculate: () -> Void

    // Enhanced validation states
    @State private var validationErrors: [String] = []
    @State private var showingValidationDetails = false
    @State private var showingBatchDetails = false
    @State private var selectedBatchIndex: Int? = nil

    // Computed properties for unit calculations
    private var totalUnits: Double {
        let units = Double(numberOfUnits) ?? 0
        let rate = (Double(successRate) ?? 100) / 100.0
        return units * rate
    }

    private var totalInvestment: Double {
        let initial = Double(initialInvestment.replacingOccurrences(of: ",", with: "")) ?? 0
        let followOnTotal = followOnInvestments.compactMap { investment in
            Double(investment.amount.replacingOccurrences(of: ",", with: ""))
        }.reduce(0, +)
        return initial + followOnTotal
    }

    private var totalFollowOnUnits: Double {
        return followOnInvestments.compactMap { investment in
            let amount = Double(investment.amount.replacingOccurrences(of: ",", with: "")) ?? 0
            let unitPrice = Double(investment.valuation.replacingOccurrences(of: ",", with: "")) ?? 0
            return unitPrice > 0 ? amount / unitPrice : 0
        }.reduce(0, +)
    }

    private var averageUnitPrice: Double {
        let totalUnitsIncludingFollowOn = totalUnits + totalFollowOnUnits
        return totalUnitsIncludingFollowOn > 0 ? totalInvestment / totalUnitsIncludingFollowOn : 0
    }

    private var isInputValid: Bool {
        return !initialInvestment.isEmpty &&
            !unitPrice.isEmpty &&
            !numberOfUnits.isEmpty &&
            !successRate.isEmpty &&
            !timeInMonths.isEmpty &&
            (Double(initialInvestment.replacingOccurrences(of: ",", with: "")) ?? 0) > 0 &&
            (Double(unitPrice.replacingOccurrences(of: ",", with: "")) ?? 0) > 0 &&
            (Double(numberOfUnits) ?? 0) > 0 &&
            (Double(successRate) ?? 0) > 0 &&
            (Double(successRate) ?? 0) <= 100 &&
            (Double(timeInMonths) ?? 0) > 0
    }

    private func validateInputs() -> [String] {
        var errors: [String] = []

        if initialInvestment.isEmpty {
            errors.append("Initial investment amount is required")
        } else if (Double(initialInvestment.replacingOccurrences(of: ",", with: "")) ?? 0) <= 0 {
            errors.append("Initial investment must be greater than 0")
        }

        if unitPrice.isEmpty {
            errors.append("Unit price is required")
        } else if (Double(unitPrice.replacingOccurrences(of: ",", with: "")) ?? 0) <= 0 {
            errors.append("Unit price must be greater than 0")
        }

        if numberOfUnits.isEmpty {
            errors.append("Number of units is required")
        } else if (Double(numberOfUnits) ?? 0) <= 0 {
            errors.append("Number of units must be greater than 0")
        }

        if successRate.isEmpty {
            errors.append("Success rate is required")
        } else {
            let rate = Double(successRate) ?? 0
            if rate <= 0 || rate > 100 {
                errors.append("Success rate must be between 0 and 100")
            }
        }

        if timeInMonths.isEmpty {
            errors.append("Time period is required")
        } else if (Double(timeInMonths) ?? 0) <= 0 {
            errors.append("Time period must be greater than 0")
        }

        // Validate follow-on investments
        for (index, investment) in followOnInvestments.enumerated() {
            do {
                try investment.validate()
            } catch {
                errors.append("Follow-on investment #\(index + 1): \(error.localizedDescription)")
            }
        }

        return errors
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Portfolio Unit Investment")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Input fields section
            PortfolioInputFieldsSection(
                initialInvestment: $initialInvestment,
                unitPrice: $unitPrice,
                numberOfUnits: $numberOfUnits,
                successRate: $successRate,
                timeInMonths: $timeInMonths
            )

            // Portfolio summary
            if !numberOfUnits.isEmpty && !successRate.isEmpty {
                PortfolioSummaryCard(
                    numberOfUnits: numberOfUnits,
                    totalUnits: totalUnits,
                    totalFollowOnUnits: totalFollowOnUnits,
                    totalInvestment: totalInvestment,
                    averageUnitPrice: averageUnitPrice,
                    followOnInvestments: followOnInvestments,
                    validationErrors: validationErrors,
                    showingValidationDetails: $showingValidationDetails
                )
            }

            // Follow-on investments section
            FollowOnInvestmentBatchSection(
                followOnInvestments: $followOnInvestments,
                showingBatchDetails: $showingBatchDetails,
                showingAddInvestment: $showingAddInvestment,
                selectedBatchIndex: $selectedBatchIndex
            )

            // Calculate button with validation
            CalculationButtonSection(
                title: "Calculate Portfolio IRR",
                isCalculating: isCalculating,
                isInputValid: isInputValid,
                showingValidationDetails: $showingValidationDetails,
                validateInputs: validateInputs,
                onCalculate: onCalculate
            )

            // Error and validation display
            ErrorDisplayView(errorMessage: errorMessage)

            ValidationFeedbackView(
                validationErrors: validationErrors,
                showingDetails: $showingValidationDetails
            )

            Spacer()
        }
        .padding()
        .onAppear {
            validationErrors = validateInputs()
        }
        .onChange(of: initialInvestment) {
            validationErrors = validateInputs()
        }
        .onChange(of: unitPrice) {
            validationErrors = validateInputs()
        }
        .onChange(of: numberOfUnits) {
            validationErrors = validateInputs()
        }
        .onChange(of: successRate) {
            validationErrors = validateInputs()
        }
        .onChange(of: timeInMonths) {
            validationErrors = validateInputs()
        }
        .onChange(of: followOnInvestments) {
            validationErrors = validateInputs()
        }
    }
}

/*
 // EXTRACTED COMPONENTS FOR FUTURE USE
 // These components contain the advanced functionality that was temporarily
 // removed to resolve compilation issues. They can be gradually re-added.

 // Extracted input fields section to reduce complexity
 struct PortfolioInputFieldsSection: View {
     @Binding var initialInvestment: String
     @Binding var unitPrice: String
     @Binding var numberOfUnits: String
     @Binding var successRate: String
     @Binding var timeInMonths: String

     var body: some View {
         VStack(spacing: 16) {
             Text("Initial Investment")
                 .font(.headline)
                 .frame(maxWidth: .infinity, alignment: .leading)

             InputField(
                 title: "Initial Investment Amount",
                 placeholder: "Enter initial investment amount",
                 text: $initialInvestment,
                 formatType: InputField.FormatType.currency
             )

             HStack(spacing: 12) {
                 InputField(
                     title: "Unit Price",
                     placeholder: "Price per unit",
                     text: $unitPrice,
                     formatType: .currency
                 )

                 InputField(
                     title: "Number of Units",
                     placeholder: "Units purchased",
                     text: $numberOfUnits,
                     formatType: .number
                 )
             }

             InputField(
                 title: "Success Rate (%)",
                 placeholder: "Expected success rate",
                 text: $successRate,
                 formatType: .number
             )

             InputField(
                 title: "Time Period (Months)",
                 placeholder: "Investment time horizon",
                 text: $timeInMonths,
                 formatType: .number
             )
         }
     }
 }

 // Extracted error display view to reduce complexity
 struct ErrorDisplayView: View {
     let errorMessage: String?

     var body: some View {
         if let errorMessage = errorMessage {
             VStack(alignment: .leading, spacing: 8) {
                 HStack {
                     Image(systemName: "exclamationmark.triangle.fill")
                         .foregroundColor(.red)
                     Text("Calculation Error")
                         .font(.headline)
                         .foregroundColor(.red)
                 }

                 Text(errorMessage)
                     .font(.caption)
                     .foregroundColor(.red)
             }
             .padding()
             .background(Color.red.opacity(0.1))
             .cornerRadius(8)
         }
     }
 }

 // Extracted calculation button section to reduce complexity
 struct CalculationButtonSection: View {
     let title: String
     let isCalculating: Bool
     let isInputValid: Bool
     @Binding var showingValidationDetails: Bool
     let validateInputs: () -> [String]
     let onCalculate: () -> Void

     var body: some View {
         CalculateButton(
             title: title,
             isLoading: isCalculating,
             action: {
                 let errors = validateInputs()
                 if errors.isEmpty {
                     onCalculate()
                 } else {
                     showingValidationDetails = true
                 }
             }
         )
         .disabled(!isInputValid)
     }
 }

 // Extracted portfolio summary card to reduce complexity
 struct PortfolioSummaryCard: View {
     let numberOfUnits: String
     let totalUnits: Double
     let totalFollowOnUnits: Double
     let totalInvestment: Double
     let averageUnitPrice: Double
     let followOnInvestments: [FollowOnInvestment]
     let validationErrors: [String]
     @Binding var showingValidationDetails: Bool

     var body: some View {
         VStack(spacing: 12) {
             HStack {
                 Text("Portfolio Summary")
                     .font(.headline)
                 Spacer()

                 if !validationErrors.isEmpty {
                     Button(action: { showingValidationDetails.toggle() }) {
                         Image(systemName: "exclamationmark.triangle.fill")
                             .foregroundColor(.orange)
                     }
                 }
             }

             VStack(spacing: 6) {
                 // Initial investment metrics
                 HStack {
                     Text("Initial Units:")
                     Spacer()
                     Text("\(NumberFormatting.formatNumber(Double(numberOfUnits) ?? 0))")
                         .fontWeight(.medium)
                 }

                 HStack {
                     Text("Expected Successful Units:")
                     Spacer()
                     Text("\(NumberFormatting.formatNumber(totalUnits))")
                         .fontWeight(.medium)
                         .foregroundColor(.green)
                 }

                 if !followOnInvestments.isEmpty {
                     HStack {
                         Text("Follow-on Units:")
                         Spacer()
                         Text("\(NumberFormatting.formatNumber(totalFollowOnUnits))")
                             .fontWeight(.medium)
                     }

                     HStack {
                         Text("Total Portfolio Units:")
                         Spacer()
                         Text("\(NumberFormatting.formatNumber(totalUnits + totalFollowOnUnits))")
                             .fontWeight(.bold)
                             .foregroundColor(.blue)
                     }
                 }

                 Divider()

                 HStack {
                     Text("Total Investment:")
                     Spacer()
                     Text(NumberFormatting.formatCurrency(totalInvestment))
                         .fontWeight(.medium)
                 }

                 if averageUnitPrice > 0 {
                     HStack {
                         Text("Average Unit Price:")
                         Spacer()
                         Text(NumberFormatting.formatCurrency(averageUnitPrice))
                             .fontWeight(.medium)
                     }
                 }

                 if !followOnInvestments.isEmpty {
                     HStack {
                         Text("Investment Batches:")
                         Spacer()
                         Text("\(followOnInvestments.count + 1)")
                             .fontWeight(.medium)
                     }
                 }
             }
             .font(.caption)
             .foregroundColor(.secondary)
         }
         .padding()
         .background(Color(.systemGray6))
         .cornerRadius(8)
     }
 }

 // Extracted follow-on investment batch section to reduce complexity
 struct FollowOnInvestmentBatchSection: View {
     @Binding var followOnInvestments: [FollowOnInvestment]
     @Binding var showingBatchDetails: Bool
     @Binding var showingAddInvestment: Bool
     @Binding var selectedBatchIndex: Int?

     var body: some View {
         VStack(spacing: 12) {
             HStack {
                 Text("Follow-on Investment Batches")
                     .font(.headline)

                 Spacer()

                 if !followOnInvestments.isEmpty {
                     Button(action: { showingBatchDetails.toggle() }) {
                         Image(systemName: showingBatchDetails ? "eye.slash" : "eye")
                             .font(.title3)
                             .foregroundColor(.secondary)
                     }
                 }

                 Button(action: { showingAddInvestment = true }) {
                     Image(systemName: "plus.circle.fill")
                         .font(.title2)
                         .foregroundColor(.blue)
                 }
             }

             if followOnInvestments.isEmpty {
                 EmptyFollowOnInvestmentView()
             } else {
                 FollowOnInvestmentContent(
                     followOnInvestments: $followOnInvestments,
                     showingBatchDetails: showingBatchDetails,
                     selectedBatchIndex: $selectedBatchIndex,
                     showingAddInvestment: $showingAddInvestment
                 )
             }
         }
     }
 }

 // Empty state for follow-on investments
 struct EmptyFollowOnInvestmentView: View {
     var body: some View {
         VStack(spacing: 8) {
             Image(systemName: "folder.badge.plus")
                 .font(.title2)
                 .foregroundColor(.secondary)
             Text("No follow-on investments added")
                 .font(.caption)
                 .foregroundColor(.secondary)
             Text("Tap + to add investment batches with different unit prices and timing")
                 .font(.caption2)
                 .foregroundColor(.secondary)
                 .multilineTextAlignment(.center)
         }
         .frame(maxWidth: .infinity)
         .padding()
         .background(Color(.systemGray6))
         .cornerRadius(8)
     }
 }

 // Content when follow-on investments exist
 struct FollowOnInvestmentContent: View {
     @Binding var followOnInvestments: [FollowOnInvestment]
     let showingBatchDetails: Bool
     @Binding var selectedBatchIndex: Int?
     @Binding var showingAddInvestment: Bool

     var body: some View {
         VStack(spacing: 12) {
             // Batch Summary Header
             HStack {
                 Text("Total Batches: \(followOnInvestments.count + 1)")
                     .font(.caption)
                     .foregroundColor(.secondary)

                 Spacer()

                 Text("Total Follow-on: \(NumberFormatting.formatCurrency(followOnInvestments.compactMap { Double($0.amount.replacingOccurrences(of: ",", with: "")) }.reduce(0, +)))")
                     .font(.caption)
                     .foregroundColor(.secondary)
             }

             FollowOnInvestmentList(
                 followOnInvestments: $followOnInvestments,
                 showingBatchDetails: showingBatchDetails,
                 selectedBatchIndex: $selectedBatchIndex,
                 showingAddInvestment: $showingAddInvestment
             )
         }
     }
 }

 // List of follow-on investments
 struct FollowOnInvestmentList: View {
     @Binding var followOnInvestments: [FollowOnInvestment]
     let showingBatchDetails: Bool
     @Binding var selectedBatchIndex: Int?
     @Binding var showingAddInvestment: Bool

     var body: some View {
         ForEach(followOnInvestments.indices, id: \.self) { index in
             PortfolioFollowOnInvestmentRow(
                 investment: $followOnInvestments[index],
                 batchNumber: index + 2, // +2 because initial is batch 1
                 showDetails: showingBatchDetails,
                 onDelete: {
                     withAnimation(.easeInOut(duration: 0.3)) {
                         followOnInvestments.remove(at: index)
                     }
                 },
                 onEdit: {
                     // For now, just show the add investment sheet
                     // In a full implementation, this would pre-populate the form
                     selectedBatchIndex = index
                     showingAddInvestment = true
                 }
             )
         }
     }
 }

 // Extracted validation feedback view to reduce complexity
 struct ValidationFeedbackView: View {
     let validationErrors: [String]
     @Binding var showingDetails: Bool

     var body: some View {
         if !validationErrors.isEmpty {
             VStack(alignment: .leading, spacing: 8) {
                 HStack {
                     Image(systemName: "info.circle.fill")
                         .foregroundColor(.orange)
                     Text("Input Validation")
                         .font(.headline)
                         .foregroundColor(.orange)

                     Spacer()

                     Button(showingDetails ? "Hide Details" : "Show Details") {
                         showingDetails.toggle()
                     }
                     .font(.caption)
                     .foregroundColor(.blue)
                 }

                 if showingDetails {
                     VStack(alignment: .leading, spacing: 4) {
                         ForEach(validationErrors, id: \.self) { error in
                             HStack(alignment: .top) {
                                 Text("•")
                                     .foregroundColor(.orange)
                                 Text(error)
                                     .font(.caption)
                                     .foregroundColor(.orange)
                             }
                         }
                     }
                 } else {
                     Text("\(validationErrors.count) validation issue\(validationErrors.count == 1 ? "" : "s") found")
                         .font(.caption)
                         .foregroundColor(.orange)
                 }
             }
             .padding()
             .background(Color.orange.opacity(0.1))
             .cornerRadius(8)
         }
     }
 }

 // Enhanced row component for portfolio follow-on investments
 struct PortfolioFollowOnInvestmentRow: View {
     @Binding var investment: FollowOnInvestment
     let batchNumber: Int
     let showDetails: Bool
     let onDelete: () -> Void
     let onEdit: () -> Void

     private var batchSummary: String {
         let amount = Double(investment.amount.replacingOccurrences(of: ",", with: "")) ?? 0
         let unitPrice = Double(investment.valuation.replacingOccurrences(of: ",", with: "")) ?? 0
         let units = unitPrice > 0 ? amount / unitPrice : 0.0
         return "\(NumberFormatting.formatNumber(units)) units @ \(NumberFormatting.formatCurrency(unitPrice))"
     }

     private var investmentAmount: Double {
         return Double(investment.amount.replacingOccurrences(of: ",", with: "")) ?? 0
     }

     private var unitPrice: Double {
         return Double(investment.valuation.replacingOccurrences(of: ",", with: "")) ?? 0
     }

     private var numberOfUnits: Double {
         return unitPrice > 0 ? investmentAmount / unitPrice : 0
     }

     private var dateDisplay: String {
         let formatter = DateFormatter()
         formatter.dateStyle = .medium

         switch investment.timingType {
         case .absoluteDate:
             return formatter.string(from: investment.date)
         case .relativeTime:
             return "\(investment.relativeAmount) \(investment.relativeUnit.rawValue.lowercased()) from initial"
         }
     }

     var body: some View {
         VStack(alignment: .leading, spacing: 12) {
             HStack {
                 VStack(alignment: .leading, spacing: 6) {
                     Text("Investment Batch")
                         .font(.headline)
                         .foregroundColor(.primary)

                     // Unit details
                     HStack {
                         VStack(alignment: .leading, spacing: 2) {
                             Text("Units")
                                 .font(.caption2)
                                 .foregroundColor(.secondary)
                             Text(NumberFormatting.formatNumber(numberOfUnits))
                                 .font(.subheadline)
                                 .fontWeight(.medium)
                         }

                         Spacer()

                         VStack(alignment: .trailing, spacing: 2) {
                             Text("Unit Price")
                                 .font(.caption2)
                                 .foregroundColor(.secondary)
                             Text(NumberFormatting.formatCurrency(unitPrice))
                                 .font(.subheadline)
                                 .fontWeight(.medium)
                         }

                         Spacer()

                         VStack(alignment: .trailing, spacing: 2) {
                             Text("Total Investment")
                                 .font(.caption2)
                                 .foregroundColor(.secondary)
                             Text(NumberFormatting.formatCurrency(investmentAmount))
                                 .font(.subheadline)
                                 .fontWeight(.medium)
                                 .foregroundColor(.blue)
                         }
                     }

                     // Timing information
                     HStack {
                         Image(systemName: "calendar")
                             .font(.caption)
                             .foregroundColor(.secondary)
                         Text(dateDisplay)
                             .font(.caption)
                             .foregroundColor(.secondary)
                     }

                     // Investment type badge
                     HStack {
                         Text(investment.investmentType.rawValue.capitalized)
                             .font(.caption2)
                             .padding(.horizontal, 8)
                             .padding(.vertical, 2)
                             .background(Color.blue.opacity(0.1))
                             .foregroundColor(.blue)
                             .cornerRadius(4)

                         Spacer()
                     }
                 }

                 Spacer()

                 VStack(spacing: 8) {
                     Button(action: onDelete) {
                         Image(systemName: "trash.fill")
                             .font(.title3)
                             .foregroundColor(.white)
                             .frame(width: 32, height: 32)
                             .background(Color.red)
                             .cornerRadius(8)
                     }
                     .buttonStyle(.plain)

                     Text("Delete")
                         .font(.caption2)
                         .foregroundColor(.red)
                 }
             }
         }
         .padding()
         .background(Color(UIColor.systemBackground))
         .cornerRadius(12)
         .overlay(
             RoundedRectangle(cornerRadius: 12)
                 .stroke(Color(UIColor.systemGray4), lineWidth: 1)
         )
         .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
     }
 }

 // Simple preview
 struct PortfolioUnitInvestmentView_Previews: PreviewProvider {
     static var previews: some View {
         PortfolioUnitInvestmentView(
             initialInvestment: .constant("100000"),
             unitPrice: .constant("10"),
             numberOfUnits: .constant("10000"),
             successRate: .constant("80"),
             timeInMonths: .constant("60"),
             followOnInvestments: .constant([]),
             calculatedResult: .constant(15.5),
             isCalculating: .constant(false),
             errorMessage: .constant(nil),
             showingAddInvestment: .constant(false),
             onCalculate: {}
         )
     }
 }
 */
