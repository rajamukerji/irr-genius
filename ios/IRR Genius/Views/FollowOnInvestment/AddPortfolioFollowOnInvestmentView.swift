//
//  AddPortfolioFollowOnInvestmentView.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/24/25.
//

import SwiftUI

struct AddPortfolioFollowOnInvestmentView: View {
    @Binding var isPresented: Bool
    @Binding var followOnInvestments: [FollowOnInvestment]
    let initialInvestmentDate: Date

    @State private var investmentType: InvestmentType = .buy
    @State private var investmentAmount: String = ""
    @State private var unitPrice: String = ""
    @State private var timingType: TimingType = .absoluteDate
    @State private var date: Date = .init()
    @State private var relativeAmount: String = "1"
    @State private var relativeUnit: TimeUnit = .years
    @State private var errorMessage: String?

    // Computed property for number of units calculation
    private var calculatedUnits: Double {
        let amount = Double(investmentAmount.replacingOccurrences(of: ",", with: "")) ?? 0
        let price = Double(unitPrice.replacingOccurrences(of: ",", with: "")) ?? 0
        return price > 0 ? amount / price : 0
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Investment Details")) {
                    Picker("Investment Type", selection: $investmentType) {
                        ForEach(InvestmentType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Investment Amount")
                            .font(.headline)
                        TextField("Amount to invest", text: $investmentAmount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: investmentAmount) { _, newValue in
                                investmentAmount = NumberFormatting.formatCurrencyInput(newValue)
                            }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Unit Price")
                            .font(.headline)
                        TextField("Price per unit", text: $unitPrice)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: unitPrice) { _, newValue in
                                unitPrice = NumberFormatting.formatCurrencyInput(newValue)
                            }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Number of Units")
                            .font(.headline)
                        Text(NumberFormatting.formatNumber(calculatedUnits))
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }

                Section(header: Text("Timing")) {
                    Picker("Timing Type", selection: $timingType) {
                        ForEach(TimingType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    if timingType == .absoluteDate {
                        DatePicker("Investment Date", selection: $date, displayedComponents: .date)
                    } else {
                        HStack {
                            TextField("Time", text: $relativeAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)

                            Picker("Time Unit", selection: $relativeUnit) {
                                ForEach(TimeUnit.allCases, id: \.self) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(.menu)

                            Text("after initial investment")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Portfolio Investment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addInvestment()
                    }
                    .disabled(!isValidInput())
                }
            }
        }
    }


    private func isValidInput() -> Bool {
        guard let amount = Double(investmentAmount.replacingOccurrences(of: ",", with: "")), amount > 0,
              let price = Double(unitPrice.replacingOccurrences(of: ",", with: "")), price > 0
        else {
            return false
        }

        if timingType == .relativeTime {
            guard let relativeValue = Double(relativeAmount), relativeValue > 0 else {
                return false
            }
        } else {
            guard date > initialInvestmentDate else {
                return false
            }
        }

        return true
    }

    private func addInvestment() {
        guard isValidInput() else {
            errorMessage = "Please check all input values"
            return
        }

        // Get the clean numeric values for amount and valuation
        let cleanAmount = investmentAmount.replacingOccurrences(of: ",", with: "")
        let cleanUnitPrice = unitPrice.replacingOccurrences(of: ",", with: "")

        // Create the follow-on investment with unit price as the valuation
        let investment = FollowOnInvestment(
            timingType: timingType,
            date: date,
            relativeAmount: relativeAmount,
            relativeUnit: relativeUnit,
            investmentType: investmentType,
            amount: cleanAmount,
            valuationMode: .custom,
            valuationType: .specified,
            valuation: cleanUnitPrice,
            irr: "0",
            initialInvestmentDate: initialInvestmentDate
        )

        do {
            try investment.validate()
            followOnInvestments.append(investment)
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
