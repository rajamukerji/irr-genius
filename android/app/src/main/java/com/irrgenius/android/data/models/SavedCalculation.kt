package com.irrgenius.android.data.models

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDateTime
import java.util.UUID

// Import the FollowOnInvestmentValidationException from FollowOnInvestment.kt
// This will be available once both files are in the same package

// Validation exception for SavedCalculation
class SavedCalculationValidationException(message: String) : Exception(message)

@Entity(tableName = "saved_calculations")
data class SavedCalculation(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val calculationType: CalculationMode,
    val createdDate: LocalDateTime,
    val modifiedDate: LocalDateTime,
    val projectId: String?,
    
    // Calculation inputs
    val initialInvestment: Double?,
    val outcomeAmount: Double?,
    val timeInMonths: Double?,
    val irr: Double?,
    
    // Portfolio Unit Investment specific parameters
    val unitPrice: Double?,
    val successRate: Double?, // Percentage (0-100)
    val outcomePerUnit: Double?,
    val investorShare: Double?, // Percentage (0-100)
    val feePercentage: Double?, // Management/legal/servicing fees percentage (0-100)
    
    // Results
    val calculatedResult: Double?,
    val growthPointsJson: String?, // JSON serialized GrowthPoint array
    
    // Metadata
    val notes: String?,
    val tags: String? // JSON array as string
) {
    
    companion object {
        private const val MAX_NAME_LENGTH = 100
        private const val MIN_IRR = -100.0
        private const val MAX_IRR = 1000.0
        
        /**
         * Validates calculation name
         */
        @Throws(SavedCalculationValidationException::class)
        fun validateName(name: String) {
            if (name.trim().isEmpty()) {
                throw SavedCalculationValidationException("Calculation name cannot be empty")
            }
            
            if (name.length > MAX_NAME_LENGTH) {
                throw SavedCalculationValidationException("Name too long (max $MAX_NAME_LENGTH characters)")
            }
            
            // Check for invalid characters
            val invalidChars = listOf('<', '>', ':', '"', '/', '\\', '|', '?', '*')
            if (name.any { it in invalidChars }) {
                throw SavedCalculationValidationException("Name contains invalid characters")
            }
        }
        
        /**
         * Validates calculation inputs based on calculation type
         */
        @Throws(SavedCalculationValidationException::class)
        fun validateCalculationInputs(
            calculationType: CalculationMode,
            initialInvestment: Double?,
            outcomeAmount: Double?,
            timeInMonths: Double?,
            irr: Double?,
            unitPrice: Double? = null,
            successRate: Double? = null,
            outcomePerUnit: Double? = null,
            investorShare: Double? = null
        ) {
            val missingFields = mutableListOf<String>()
            
            when (calculationType) {
                CalculationMode.CALCULATE_IRR -> {
                    initialInvestment?.let { investment ->
                        if (investment <= 0) throw SavedCalculationValidationException("Initial investment must be positive")
                    } ?: missingFields.add("Initial Investment")
                    
                    outcomeAmount?.let { outcome ->
                        if (outcome <= 0) throw SavedCalculationValidationException("Outcome amount must be positive")
                    } ?: missingFields.add("Outcome Amount")
                    
                    timeInMonths?.let { time ->
                        if (time <= 0) throw SavedCalculationValidationException("Time in months must be positive")
                    } ?: missingFields.add("Time in Months")
                }
                
                CalculationMode.CALCULATE_OUTCOME -> {
                    initialInvestment?.let { investment ->
                        if (investment <= 0) throw SavedCalculationValidationException("Initial investment must be positive")
                    } ?: missingFields.add("Initial Investment")
                    
                    irr?.let { irrValue ->
                        if (irrValue <= MIN_IRR || irrValue >= MAX_IRR) {
                            throw SavedCalculationValidationException("IRR must be between $MIN_IRR and $MAX_IRR")
                        }
                    } ?: missingFields.add("IRR")
                    
                    timeInMonths?.let { time ->
                        if (time <= 0) throw SavedCalculationValidationException("Time in months must be positive")
                    } ?: missingFields.add("Time in Months")
                }
                
                CalculationMode.CALCULATE_INITIAL -> {
                    outcomeAmount?.let { outcome ->
                        if (outcome <= 0) throw SavedCalculationValidationException("Outcome amount must be positive")
                    } ?: missingFields.add("Outcome Amount")
                    
                    irr?.let { irrValue ->
                        if (irrValue <= MIN_IRR || irrValue >= MAX_IRR) {
                            throw SavedCalculationValidationException("IRR must be between $MIN_IRR and $MAX_IRR")
                        }
                    } ?: missingFields.add("IRR")
                    
                    timeInMonths?.let { time ->
                        if (time <= 0) throw SavedCalculationValidationException("Time in months must be positive")
                    } ?: missingFields.add("Time in Months")
                }
                
                CalculationMode.CALCULATE_BLENDED -> {
                    initialInvestment?.let { investment ->
                        if (investment <= 0) throw SavedCalculationValidationException("Initial investment must be positive")
                    } ?: missingFields.add("Initial Investment")
                    
                    outcomeAmount?.let { outcome ->
                        if (outcome <= 0) throw SavedCalculationValidationException("Outcome amount must be positive")
                    } ?: missingFields.add("Outcome Amount")
                    
                    timeInMonths?.let { time ->
                        if (time <= 0) throw SavedCalculationValidationException("Time in months must be positive")
                    } ?: missingFields.add("Time in Months")
                }
                
                CalculationMode.PORTFOLIO_UNIT_INVESTMENT -> {
                    initialInvestment?.let { investment ->
                        if (investment <= 0) throw SavedCalculationValidationException("Initial investment must be positive")
                    } ?: missingFields.add("Investment Amount")
                    
                    unitPrice?.let { price ->
                        if (price <= 0) throw SavedCalculationValidationException("Unit price must be positive")
                    } ?: missingFields.add("Unit Price")
                    
                    successRate?.let { rate ->
                        if (rate < 0 || rate > 100) throw SavedCalculationValidationException("Success rate must be between 0 and 100")
                    } ?: missingFields.add("Success Rate")
                    
                    outcomePerUnit?.let { outcome ->
                        if (outcome <= 0) throw SavedCalculationValidationException("Outcome per unit must be positive")
                    } ?: missingFields.add("Outcome Per Unit")
                    
                    investorShare?.let { share ->
                        if (share < 0 || share > 100) throw SavedCalculationValidationException("Investor share must be between 0 and 100")
                    } ?: missingFields.add("Investor Share")
                    
                    timeInMonths?.let { time ->
                        if (time <= 0) throw SavedCalculationValidationException("Time in months must be positive")
                    } ?: missingFields.add("Time in Months")
                }
            }
            
            if (missingFields.isNotEmpty()) {
                throw SavedCalculationValidationException("Missing required fields: ${missingFields.joinToString(", ")}")
            }
        }
        
        /**
         * Creates a validated SavedCalculation instance
         */
        @Throws(SavedCalculationValidationException::class)
        fun createValidated(
            id: String = UUID.randomUUID().toString(),
            name: String,
            calculationType: CalculationMode,
            createdDate: LocalDateTime = LocalDateTime.now(),
            modifiedDate: LocalDateTime = LocalDateTime.now(),
            projectId: String? = null,
            initialInvestment: Double? = null,
            outcomeAmount: Double? = null,
            timeInMonths: Double? = null,
            irr: Double? = null,
            unitPrice: Double? = null,
            successRate: Double? = null,
            outcomePerUnit: Double? = null,
            investorShare: Double? = null,
            feePercentage: Double? = null,
            calculatedResult: Double? = null,
            growthPointsJson: String? = null,
            notes: String? = null,
            tags: String? = null
        ): SavedCalculation {
            validateName(name)
            validateCalculationInputs(calculationType, initialInvestment, outcomeAmount, timeInMonths, irr, unitPrice, successRate, outcomePerUnit, investorShare)
            
            return SavedCalculation(
                id = id,
                name = name,
                calculationType = calculationType,
                createdDate = createdDate,
                modifiedDate = modifiedDate,
                projectId = projectId,
                initialInvestment = initialInvestment,
                outcomeAmount = outcomeAmount,
                timeInMonths = timeInMonths,
                irr = irr,
                unitPrice = unitPrice,
                successRate = successRate,
                outcomePerUnit = outcomePerUnit,
                investorShare = investorShare,
                feePercentage = feePercentage,
                calculatedResult = calculatedResult,
                growthPointsJson = growthPointsJson,
                notes = notes,
                tags = tags
            )
        }
    }
    
    /**
     * Validates the entire calculation for data integrity
     */
    @Throws(SavedCalculationValidationException::class)
    fun validate() {
        validateName(name)
        validateCalculationInputs(calculationType, initialInvestment, outcomeAmount, timeInMonths, irr, unitPrice, successRate, outcomePerUnit, investorShare)
    }
    
    /**
     * Checks if calculation has all required data for its type
     */
    val isComplete: Boolean
        get() = try {
            validate()
            true
        } catch (e: SavedCalculationValidationException) {
            false
        }
    
    /**
     * Returns a summary of the calculation for display purposes
     */
    val summary: String
        get() = when (calculationType) {
            CalculationMode.CALCULATE_IRR -> {
                calculatedResult?.let { result ->
                    "IRR: ${String.format("%.2f", result)}%"
                } ?: "IRR calculation"
            }
            CalculationMode.CALCULATE_OUTCOME -> {
                calculatedResult?.let { result ->
                    "Outcome: $${String.format("%.2f", result)}"
                } ?: "Outcome calculation"
            }
            CalculationMode.CALCULATE_INITIAL -> {
                calculatedResult?.let { result ->
                    "Initial: $${String.format("%.2f", result)}"
                } ?: "Initial investment calculation"
            }
            CalculationMode.CALCULATE_BLENDED -> {
                calculatedResult?.let { result ->
                    "Blended IRR: ${String.format("%.2f", result)}%"
                } ?: "Blended IRR calculation"
            }
            CalculationMode.PORTFOLIO_UNIT_INVESTMENT -> {
                calculatedResult?.let { result ->
                    "Portfolio IRR: ${String.format("%.2f", result)}%"
                } ?: "Portfolio unit investment"
            }
        }
    
    /**
     * Creates a copy with updated modification date
     */
    fun withUpdatedModificationDate(): SavedCalculation {
        return copy(modifiedDate = LocalDateTime.now())
    }
    
    /**
     * Serializes tags array to JSON string
     */
    fun getTagsAsJson(): String {
        return tags ?: "[]"
    }
    
    /**
     * Deserializes tags from JSON string
     */
    fun getTagsFromJson(): List<String> {
        return try {
            if (tags.isNullOrEmpty()) return emptyList()
            // Simple JSON parsing for string arrays
            val cleanJson = tags.trim()
            if (cleanJson.startsWith("[") && cleanJson.endsWith("]")) {
                val content = cleanJson.substring(1, cleanJson.length - 1)
                if (content.isBlank()) return emptyList()
                return content.split(",").map { it.trim().removeSurrounding("\"") }
            }
            emptyList()
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    /**
     * Gets growth points from JSON string
     */
    fun getGrowthPoints(): List<GrowthPoint> {
        return GrowthPoint.fromJsonString(growthPointsJson)
    }
    
    /**
     * Sets growth points as JSON string
     */
    fun withGrowthPoints(growthPoints: List<GrowthPoint>): SavedCalculation {
        return copy(growthPointsJson = GrowthPoint.toJsonString(growthPoints))
    }
    
    /**
     * Sets tags as JSON string
     */
    fun withTags(tagsList: List<String>): SavedCalculation {
        val tagsJson = if (tagsList.isEmpty()) {
            "[]"
        } else {
            "[" + tagsList.joinToString(",") { "\"$it\"" } + "]"
        }
        return copy(tags = tagsJson)
    }
}


@Entity(
    tableName = "follow_on_investments",
    foreignKeys = [androidx.room.ForeignKey(
        entity = SavedCalculation::class,
        parentColumns = ["id"],
        childColumns = ["calculationId"],
        onDelete = androidx.room.ForeignKey.CASCADE
    )]
)
data class FollowOnInvestmentEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val calculationId: String,
    val amount: Double,
    val investmentType: InvestmentType,
    val timingType: TimingType,
    val absoluteDate: String?, // ISO date string
    val relativeTime: Double?,
    val relativeTimeUnit: TimeUnit?,
    val valuationMode: ValuationMode,
    val valuationType: ValuationType,
    val customValuation: Double?,
    val irr: Double? // Used for computed valuation
) {
    
    /**
     * Converts this FollowOnInvestmentEntity to a FollowOnInvestment domain model
     */
    fun toDomainModel(): FollowOnInvestment {
        return FollowOnInvestment(
            id = id,
            amount = amount,
            investmentType = investmentType,
            timingType = timingType,
            absoluteDate = absoluteDate?.let { java.time.LocalDate.parse(it) } ?: java.time.LocalDate.now(),
            relativeTime = relativeTime ?: 1.0,
            relativeTimeUnit = relativeTimeUnit ?: TimeUnit.YEARS,
            valuationMode = valuationMode,
            valuationType = valuationType,
            customValuation = customValuation ?: 0.0,
            irr = irr ?: 0.0
        )
    }
    
    /**
     * Validates the entity data
     */
    @Throws(FollowOnInvestmentValidationException::class)
    fun validate() {
        if (amount <= 0) {
            throw FollowOnInvestmentValidationException("Investment amount must be positive")
        }
        
        when (timingType) {
            TimingType.ABSOLUTE -> {
                if (absoluteDate == null) {
                    throw FollowOnInvestmentValidationException("Absolute date is required for absolute timing")
                }
                try {
                    java.time.LocalDate.parse(absoluteDate)
                } catch (e: Exception) {
                    throw FollowOnInvestmentValidationException("Invalid date format")
                }
            }
            TimingType.RELATIVE -> {
                if (relativeTime == null || relativeTime <= 0) {
                    throw FollowOnInvestmentValidationException("Relative time must be positive")
                }
                if (relativeTimeUnit == null) {
                    throw FollowOnInvestmentValidationException("Relative time unit is required")
                }
            }
        }
        
        when (valuationMode) {
            ValuationMode.CUSTOM -> {
                if (valuationType == ValuationType.SPECIFIED) {
                    if (customValuation == null || customValuation <= 0) {
                        throw FollowOnInvestmentValidationException("Custom valuation must be positive")
                    }
                } else {
                    if (irr == null || irr <= -100.0 || irr >= 1000.0) {
                        throw FollowOnInvestmentValidationException("IRR must be between -100 and 1000")
                    }
                }
            }
            ValuationMode.TAG_ALONG -> {
                // Tag-along mode doesn't require additional validation
            }
        }
    }
    
    /**
     * Checks if the entity has valid data
     */
    val isValid: Boolean
        get() = try {
            validate()
            true
        } catch (e: FollowOnInvestmentValidationException) {
            false
        }
}