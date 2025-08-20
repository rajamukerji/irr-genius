package com.irrgenius.android.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.irrgenius.android.data.AutoSaveManager
import com.irrgenius.android.data.models.*
import com.irrgenius.android.domain.calculator.IRRCalculator
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate

data class MainUiState(
    val calculationMode: CalculationMode = CalculationMode.CALCULATE_IRR,
    val isCalculating: Boolean = false,
    
    // IRR Calculation inputs
    val irrInitialInvestment: String = "",
    val irrOutcome: String = "",
    val irrYears: String = "",
    val irrResult: Double? = null,
    
    // Outcome Calculation inputs
    val outcomeInitialInvestment: String = "",
    val outcomeIRR: String = "",
    val outcomeYears: String = "",
    val outcomeResult: Double? = null,
    
    // Initial Calculation inputs
    val initialOutcome: String = "",
    val initialIRR: String = "",
    val initialYears: String = "",
    val initialResult: Double? = null,
    
    // Blended IRR inputs
    val blendedInitialInvestment: String = "",
    val blendedOutcome: String = "",
    val blendedYears: String = "",
    val blendedInitialDate: LocalDate = LocalDate.now(),
    val blendedFollowOnInvestments: List<FollowOnInvestment> = emptyList(),
    val blendedResult: Double? = null,
    
    // Portfolio Unit Investment inputs
    val portfolioInitialInvestment: String = "",
    val portfolioUnitPrice: String = "",
    val portfolioNumberOfUnits: String = "",  // This will be auto-calculated
    val portfolioSuccessRate: String = "100",
    val portfolioTimeInMonths: String = "",
    val portfolioOutcomePerUnit: String = "",  // New: Expected outcome per successful unit
    val portfolioTopLineFees: String = "0",    // New: MDL/top-line fees
    val portfolioManagementFees: String = "40", // New: Plaintiff counsel fees
    val portfolioInvestorShare: String = "42.5", // New: Investor's share
    val portfolioInvestmentType: String = "litigation", // New: Investment type
    val portfolioInitialDate: LocalDate = LocalDate.now(),
    val portfolioFollowOnInvestments: List<FollowOnInvestment> = emptyList(),
    val portfolioResult: Double? = null,
    val showingAddPortfolioInvestment: Boolean = false,
    
    // Growth chart data
    val growthPoints: List<GrowthPoint> = emptyList()
)

class MainViewModel : ViewModel() {
    private val calculator = IRRCalculator()
    val autoSaveManager = AutoSaveManager()
    
    private val _uiState = MutableStateFlow(MainUiState())
    val uiState: StateFlow<MainUiState> = _uiState.asStateFlow()
    
    fun setCalculationMode(mode: CalculationMode) {
        _uiState.value = _uiState.value.copy(calculationMode = mode)
    }
    
    fun updateIRRInputs(initial: String? = null, outcome: String? = null, years: String? = null) {
        _uiState.value = _uiState.value.copy(
            irrInitialInvestment = initial ?: _uiState.value.irrInitialInvestment,
            irrOutcome = outcome ?: _uiState.value.irrOutcome,
            irrYears = years ?: _uiState.value.irrYears
        )
        updateInputTracking()
    }
    
    fun updateOutcomeInputs(initial: String? = null, irr: String? = null, years: String? = null) {
        _uiState.value = _uiState.value.copy(
            outcomeInitialInvestment = initial ?: _uiState.value.outcomeInitialInvestment,
            outcomeIRR = irr ?: _uiState.value.outcomeIRR,
            outcomeYears = years ?: _uiState.value.outcomeYears
        )
        updateInputTracking()
    }
    
    fun updateInitialInputs(outcome: String? = null, irr: String? = null, years: String? = null) {
        _uiState.value = _uiState.value.copy(
            initialOutcome = outcome ?: _uiState.value.initialOutcome,
            initialIRR = irr ?: _uiState.value.initialIRR,
            initialYears = years ?: _uiState.value.initialYears
        )
        updateInputTracking()
    }
    
    fun updateBlendedInputs(
        initial: String? = null, 
        outcome: String? = null, 
        years: String? = null,
        initialDate: LocalDate? = null
    ) {
        _uiState.value = _uiState.value.copy(
            blendedInitialInvestment = initial ?: _uiState.value.blendedInitialInvestment,
            blendedOutcome = outcome ?: _uiState.value.blendedOutcome,
            blendedYears = years ?: _uiState.value.blendedYears,
            blendedInitialDate = initialDate ?: _uiState.value.blendedInitialDate
        )
        updateInputTracking()
    }
    
    fun addFollowOnInvestment(investment: FollowOnInvestment) {
        _uiState.value = _uiState.value.copy(
            blendedFollowOnInvestments = _uiState.value.blendedFollowOnInvestments + investment
        )
    }
    
    fun removeFollowOnInvestment(id: String) {
        _uiState.value = _uiState.value.copy(
            blendedFollowOnInvestments = _uiState.value.blendedFollowOnInvestments.filter { it.id != id }
        )
    }
    
    fun updatePortfolioInputs(
        initialInvestment: String? = null,
        unitPrice: String? = null,
        numberOfUnits: String? = null,
        successRate: String? = null,
        timeInMonths: String? = null,
        outcomePerUnit: String? = null,
        topLineFees: String? = null,
        managementFees: String? = null,
        investorShare: String? = null,
        investmentType: String? = null,
        initialDate: LocalDate? = null
    ) {
        // Auto-calculate units when investment or price changes
        val currentState = _uiState.value
        var updatedNumberOfUnits = numberOfUnits ?: currentState.portfolioNumberOfUnits
        
        val newInitialInvestment = initialInvestment ?: currentState.portfolioInitialInvestment
        val newUnitPrice = unitPrice ?: currentState.portfolioUnitPrice
        
        // Auto-calculate units if investment or unit price changed
        if (initialInvestment != null || unitPrice != null) {
            val investment = newInitialInvestment.toDoubleOrNull() ?: 0.0
            val price = newUnitPrice.toDoubleOrNull() ?: 0.0
            if (investment > 0 && price > 0) {
                val calculatedUnits = investment / price
                updatedNumberOfUnits = String.format("%.2f", calculatedUnits)
            }
        }
        
        _uiState.value = currentState.copy(
            portfolioInitialInvestment = newInitialInvestment,
            portfolioUnitPrice = newUnitPrice,
            portfolioNumberOfUnits = updatedNumberOfUnits,
            portfolioSuccessRate = successRate ?: currentState.portfolioSuccessRate,
            portfolioTimeInMonths = timeInMonths ?: currentState.portfolioTimeInMonths,
            portfolioOutcomePerUnit = outcomePerUnit ?: currentState.portfolioOutcomePerUnit,
            portfolioTopLineFees = topLineFees ?: currentState.portfolioTopLineFees,
            portfolioManagementFees = managementFees ?: currentState.portfolioManagementFees,
            portfolioInvestorShare = investorShare ?: currentState.portfolioInvestorShare,
            portfolioInvestmentType = investmentType ?: currentState.portfolioInvestmentType,
            portfolioInitialDate = initialDate ?: currentState.portfolioInitialDate
        )
        updateInputTracking()
    }
    
    fun addPortfolioFollowOnInvestment(investment: FollowOnInvestment) {
        _uiState.value = _uiState.value.copy(
            portfolioFollowOnInvestments = _uiState.value.portfolioFollowOnInvestments + investment
        )
    }
    
    fun removePortfolioFollowOnInvestment(id: String) {
        _uiState.value = _uiState.value.copy(
            portfolioFollowOnInvestments = _uiState.value.portfolioFollowOnInvestments.filter { it.id != id }
        )
    }
    
    fun setShowingAddPortfolioInvestment(showing: Boolean) {
        _uiState.value = _uiState.value.copy(showingAddPortfolioInvestment = showing)
    }
    
    fun calculate() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isCalculating = true)
            
            // Simulate calculation delay like in Swift version
            delay(300)
            
            when (_uiState.value.calculationMode) {
                CalculationMode.CALCULATE_IRR -> calculateIRR()
                CalculationMode.CALCULATE_OUTCOME -> calculateOutcome()
                CalculationMode.CALCULATE_INITIAL -> calculateInitial()
                CalculationMode.CALCULATE_BLENDED -> calculateBlended()
                CalculationMode.PORTFOLIO_UNIT_INVESTMENT -> calculatePortfolioUnitInvestment()
            }
            
            _uiState.value = _uiState.value.copy(isCalculating = false)
        }
    }
    
    private fun calculateIRR() {
        val initial = _uiState.value.irrInitialInvestment.toDoubleOrNull() ?: return
        val outcome = _uiState.value.irrOutcome.toDoubleOrNull() ?: return
        val years = _uiState.value.irrYears.toDoubleOrNull() ?: return
        
        val irr = calculator.calculateIRRValue(initial, outcome, years)
        val points = calculator.growthPoints(initial, irr, years)
        
        _uiState.value = _uiState.value.copy(
            irrResult = irr,
            growthPoints = points
        )
        
        // Trigger auto-save
        val inputs = getInputsForMode()
        autoSaveManager.handleCalculationCompleted(
            calculationType = _uiState.value.calculationMode,
            inputs = inputs,
            result = irr,
            growthPoints = points
        )
    }
    
    private fun calculateOutcome() {
        val initial = _uiState.value.outcomeInitialInvestment.toDoubleOrNull() ?: return
        val irr = (_uiState.value.outcomeIRR.toDoubleOrNull() ?: return) / 100.0
        val years = _uiState.value.outcomeYears.toDoubleOrNull() ?: return
        
        val outcome = calculator.calculateOutcomeValue(initial, irr, years)
        val points = calculator.growthPoints(initial, irr, years)
        
        _uiState.value = _uiState.value.copy(
            outcomeResult = outcome,
            growthPoints = points
        )
        
        // Trigger auto-save
        val inputs = getInputsForMode()
        autoSaveManager.handleCalculationCompleted(
            calculationType = _uiState.value.calculationMode,
            inputs = inputs,
            result = outcome,
            growthPoints = points
        )
    }
    
    private fun calculateInitial() {
        val outcome = _uiState.value.initialOutcome.toDoubleOrNull() ?: return
        val irr = (_uiState.value.initialIRR.toDoubleOrNull() ?: return) / 100.0
        val years = _uiState.value.initialYears.toDoubleOrNull() ?: return
        
        val initial = calculator.calculateInitialValue(outcome, irr, years)
        val points = calculator.growthPoints(initial, irr, years)
        
        _uiState.value = _uiState.value.copy(
            initialResult = initial,
            growthPoints = points
        )
        
        // Trigger auto-save
        val inputs = getInputsForMode()
        autoSaveManager.handleCalculationCompleted(
            calculationType = _uiState.value.calculationMode,
            inputs = inputs,
            result = initial,
            growthPoints = points
        )
    }
    
    private fun calculateBlended() {
        val initial = _uiState.value.blendedInitialInvestment.toDoubleOrNull() ?: return
        val outcome = _uiState.value.blendedOutcome.toDoubleOrNull() ?: return
        val years = _uiState.value.blendedYears.toDoubleOrNull() ?: return
        
        val blendedIRR = calculator.calculateBlendedIRR(
            initial, outcome, years,
            _uiState.value.blendedFollowOnInvestments,
            _uiState.value.blendedInitialDate
        )
        
        val points = if (_uiState.value.blendedFollowOnInvestments.isEmpty()) {
            calculator.growthPoints(initial, blendedIRR, years)
        } else {
            calculator.growthPointsWithFollowOn(
                initial, blendedIRR, years,
                _uiState.value.blendedFollowOnInvestments,
                _uiState.value.blendedInitialDate
            )
        }
        
        _uiState.value = _uiState.value.copy(
            blendedResult = blendedIRR,
            growthPoints = points
        )
        
        // Trigger auto-save
        val inputs = getInputsForMode()
        autoSaveManager.handleCalculationCompleted(
            calculationType = _uiState.value.calculationMode,
            inputs = inputs,
            result = blendedIRR,
            growthPoints = points
        )
    }
    
    private fun calculatePortfolioUnitInvestment() {
        val initialInvestment = _uiState.value.portfolioInitialInvestment.toDoubleOrNull() ?: return
        val unitPrice = _uiState.value.portfolioUnitPrice.toDoubleOrNull() ?: return
        val outcomePerUnit = _uiState.value.portfolioOutcomePerUnit.toDoubleOrNull() ?: return
        val successRate = (_uiState.value.portfolioSuccessRate.toDoubleOrNull() ?: 100.0) / 100.0
        val topLineFees = (_uiState.value.portfolioTopLineFees.toDoubleOrNull() ?: 0.0) / 100.0
        val managementFees = (_uiState.value.portfolioManagementFees.toDoubleOrNull() ?: 40.0) / 100.0
        val investorShare = (_uiState.value.portfolioInvestorShare.toDoubleOrNull() ?: 42.5) / 100.0
        val timeInMonths = _uiState.value.portfolioTimeInMonths.toDoubleOrNull() ?: return
        
        // Auto-calculate number of units from investment amount and unit price
        val numberOfUnits = initialInvestment / unitPrice
        
        // Calculate successful units
        val successfulUnits = numberOfUnits * successRate
        
        // Calculate gross outcome
        val grossOutcome = successfulUnits * outcomePerUnit
        
        // Apply top-line fees (MDL committee fees, etc.)
        val afterTopLineFees = grossOutcome * (1 - topLineFees)
        
        // Apply management fees (plaintiff counsel share)
        val plaintiffCounselShare = afterTopLineFees * managementFees
        
        // Apply investor share
        val netInvestorOutcome = plaintiffCounselShare * investorShare
        
        val years = timeInMonths / 12.0
        
        // Calculate portfolio IRR with proper fee structure
        val portfolioIRR = calculator.calculateIRRValue(initialInvestment, netInvestorOutcome, years)
        
        // Generate growth points for portfolio
        val points = if (_uiState.value.portfolioFollowOnInvestments.isEmpty()) {
            calculator.growthPoints(initialInvestment, portfolioIRR, years)
        } else {
            calculator.growthPointsWithFollowOn(
                initialInvestment, portfolioIRR, years,
                _uiState.value.portfolioFollowOnInvestments,
                _uiState.value.portfolioInitialDate
            )
        }
        
        _uiState.value = _uiState.value.copy(
            portfolioResult = portfolioIRR,
            growthPoints = points
        )
        
        // Trigger auto-save
        val inputs = getInputsForMode()
        autoSaveManager.handleCalculationCompleted(
            calculationType = _uiState.value.calculationMode,
            inputs = inputs,
            result = portfolioIRR,
            growthPoints = points
        )
    }
    
    // MARK: - Auto-Save Methods
    
    private fun updateInputTracking() {
        val inputs = getInputsForMode()
        autoSaveManager.updateInputs(inputs)
    }
    
    private fun getInputsForMode(): Map<String, Any> {
        return when (_uiState.value.calculationMode) {
            CalculationMode.CALCULATE_IRR -> {
                val months = _uiState.value.irrYears.toDoubleOrNull()?.times(12) ?: 0.0
                mapOf(
                    "Initial Investment" to (_uiState.value.irrInitialInvestment.toDoubleOrNull() ?: 0.0),
                    "Outcome Amount" to (_uiState.value.irrOutcome.toDoubleOrNull() ?: 0.0),
                    "Time Period (Months)" to months,
                    "Time Period (Years)" to (_uiState.value.irrYears.toDoubleOrNull() ?: 0.0)
                )
            }
            CalculationMode.CALCULATE_OUTCOME -> {
                val months = _uiState.value.outcomeYears.toDoubleOrNull()?.times(12) ?: 0.0
                mapOf(
                    "Initial Investment" to (_uiState.value.outcomeInitialInvestment.toDoubleOrNull() ?: 0.0),
                    "IRR" to (_uiState.value.outcomeIRR.toDoubleOrNull() ?: 0.0),
                    "Time Period (Months)" to months,
                    "Time Period (Years)" to (_uiState.value.outcomeYears.toDoubleOrNull() ?: 0.0)
                )
            }
            CalculationMode.CALCULATE_INITIAL -> {
                val months = _uiState.value.initialYears.toDoubleOrNull()?.times(12) ?: 0.0
                mapOf(
                    "Outcome Amount" to (_uiState.value.initialOutcome.toDoubleOrNull() ?: 0.0),
                    "IRR" to (_uiState.value.initialIRR.toDoubleOrNull() ?: 0.0),
                    "Time Period (Months)" to months,
                    "Time Period (Years)" to (_uiState.value.initialYears.toDoubleOrNull() ?: 0.0)
                )
            }
            CalculationMode.CALCULATE_BLENDED -> {
                val months = _uiState.value.blendedYears.toDoubleOrNull()?.times(12) ?: 0.0
                mapOf(
                    "Initial Investment" to (_uiState.value.blendedInitialInvestment.toDoubleOrNull() ?: 0.0),
                    "Final Valuation" to (_uiState.value.blendedOutcome.toDoubleOrNull() ?: 0.0),
                    "Time Period (Months)" to months,
                    "Time Period (Years)" to (_uiState.value.blendedYears.toDoubleOrNull() ?: 0.0),
                    "Follow-on Investments" to _uiState.value.blendedFollowOnInvestments.size.toDouble()
                )
            }
            CalculationMode.PORTFOLIO_UNIT_INVESTMENT -> {
                val months = _uiState.value.portfolioTimeInMonths.toDoubleOrNull() ?: 0.0
                val units = _uiState.value.portfolioNumberOfUnits.toDoubleOrNull() ?: 0.0
                val successRate = _uiState.value.portfolioSuccessRate.toDoubleOrNull() ?: 100.0
                val successfulUnits = units * (successRate / 100.0)
                mapOf(
                    "Initial Investment" to (_uiState.value.portfolioInitialInvestment.toDoubleOrNull() ?: 0.0),
                    "Unit Price" to (_uiState.value.portfolioUnitPrice.toDoubleOrNull() ?: 0.0),
                    "Number of Units" to units,
                    "Success Rate (%)" to successRate,
                    "Expected Successful Units" to successfulUnits,
                    "Time Period (Months)" to months,
                    "Time Period (Years)" to (months / 12.0),
                    "Follow-on Batches" to _uiState.value.portfolioFollowOnInvestments.size.toDouble()
                )
            }
        }
    }
    
    // MARK: - Calculation Loading Methods
    
    fun loadCalculation(calculation: SavedCalculation) {
        // Clear current results
        clearResults()
        
        // Set the calculation mode
        setCalculationMode(calculation.calculationType)
        
        // Populate form fields based on calculation type
        when (calculation.calculationType) {
            CalculationMode.CALCULATE_IRR -> {
                updateIRRInputs(
                    initial = formatCurrency(calculation.initialInvestment),
                    outcome = formatCurrency(calculation.outcomeAmount),
                    years = formatNumber(calculation.timeInMonths?.div(12.0))
                )
                _uiState.value = _uiState.value.copy(
                    irrResult = calculation.calculatedResult,
                    growthPoints = calculation.getGrowthPoints()
                )
            }
            
            CalculationMode.CALCULATE_OUTCOME -> {
                updateOutcomeInputs(
                    initial = formatCurrency(calculation.initialInvestment),
                    irr = formatNumber(calculation.irr),
                    years = formatNumber(calculation.timeInMonths?.div(12.0))
                )
                _uiState.value = _uiState.value.copy(
                    outcomeResult = calculation.calculatedResult,
                    growthPoints = calculation.getGrowthPoints()
                )
            }
            
            CalculationMode.CALCULATE_INITIAL -> {
                updateInitialInputs(
                    outcome = formatCurrency(calculation.outcomeAmount),
                    irr = formatNumber(calculation.irr),
                    years = formatNumber(calculation.timeInMonths?.div(12.0))
                )
                _uiState.value = _uiState.value.copy(
                    initialResult = calculation.calculatedResult,
                    growthPoints = calculation.getGrowthPoints()
                )
            }
            
            CalculationMode.CALCULATE_BLENDED -> {
                updateBlendedInputs(
                    initial = formatCurrency(calculation.initialInvestment),
                    outcome = formatCurrency(calculation.outcomeAmount),
                    years = formatNumber(calculation.timeInMonths?.div(12.0))
                )
                _uiState.value = _uiState.value.copy(
                    blendedResult = calculation.calculatedResult,
                    growthPoints = calculation.getGrowthPoints()
                )
            }
            
            CalculationMode.PORTFOLIO_UNIT_INVESTMENT -> {
                updatePortfolioInputs(
                    initialInvestment = formatCurrency(calculation.initialInvestment),
                    unitPrice = formatCurrency(calculation.unitPrice),
                    numberOfUnits = formatNumber(calculation.outcomePerUnit), // Using outcomePerUnit as number of units
                    successRate = formatNumber(calculation.successRate) ?: "100",
                    timeInMonths = formatNumber(calculation.timeInMonths)
                )
                _uiState.value = _uiState.value.copy(
                    portfolioResult = calculation.calculatedResult,
                    growthPoints = calculation.getGrowthPoints()
                )
            }
        }
        
        // Clear unsaved changes since we just loaded a calculation
        autoSaveManager.clearUnsavedChanges()
    }
    
    private fun clearResults() {
        _uiState.value = _uiState.value.copy(
            irrResult = null,
            outcomeResult = null,
            initialResult = null,
            blendedResult = null,
            portfolioResult = null,
            growthPoints = emptyList()
        )
    }
    
    private fun formatCurrency(value: Double?): String {
        return value?.let { String.format("%.2f", it) } ?: ""
    }
    
    private fun formatNumber(value: Double?): String {
        return value?.let { String.format("%.0f", it) } ?: ""
    }
}