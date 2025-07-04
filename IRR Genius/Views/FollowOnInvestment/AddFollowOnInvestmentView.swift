//
//  AddFollowOnInvestmentView.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import SwiftUI

struct AddFollowOnInvestmentView: View {
    @Binding var isPresented: Bool
    @Binding var followOnInvestments: [FollowOnInvestment]
    let initialInvestmentDate: Date
    
    @State private var timingType: TimingType = .relativeTime
    @State private var date: Date = Date()
    @State private var relativeAmount: String = ""
    @State private var relativeUnit: TimeUnit = .months
    @State private var investmentType: InvestmentType = .buy
    @State private var amount: String = ""
    @State private var valuationMode: ValuationMode = .tagAlong
    @State private var valuationType: ValuationType = .computed
    @State private var valuation: String = ""
    @State private var irr: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Investment Details") {
                    Picker("Investment Type", selection: $investmentType) {
                        ForEach(InvestmentType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    InputField(
                        title: "Amount",
                        placeholder: "Enter investment amount",
                        text: $amount,
                        formatType: .currency
                    )
                }
                
                Section("Timing") {
                    Picker("Timing Type", selection: $timingType) {
                        ForEach(TimingType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    if timingType == .absoluteDate {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                    } else {
                        HStack {
                            InputField(
                                title: "Time Amount",
                                placeholder: "Enter amount",
                                text: $relativeAmount,
                                formatType: .number
                            )
                            
                            Picker("Unit", selection: $relativeUnit) {
                                ForEach(TimeUnit.allCases, id: \.self) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                }
                
                Section("Valuation") {
                    Picker("Valuation Mode", selection: $valuationMode) {
                        ForEach(ValuationMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    
                    if valuationMode == .custom {
                        Picker("Valuation Type", selection: $valuationType) {
                            ForEach(ValuationType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        
                        if valuationType == .computed {
                            InputField(
                                title: "IRR for Computation (%)",
                                placeholder: "Enter IRR percentage",
                                text: $irr,
                                formatType: .number
                            )
                        } else {
                            InputField(
                                title: "Specified Valuation",
                                placeholder: "Enter valuation amount",
                                text: $valuation,
                                formatType: .currency
                            )
                        }
                    }
                }
            }
            .navigationTitle("Add Follow-on Investment")
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
                    .disabled(amount.isEmpty)
                }
            }
        }
    }
    
    private func addInvestment() {
        let newInvestment = FollowOnInvestment(
            timingType: timingType,
            date: date,
            relativeAmount: relativeAmount,
            relativeUnit: relativeUnit,
            investmentType: investmentType,
            amount: amount,
            valuationMode: valuationMode,
            valuationType: valuationType,
            valuation: valuation,
            irr: irr,
            initialInvestmentDate: initialInvestmentDate
        )
        
        followOnInvestments.append(newInvestment)
        isPresented = false
    }
} 