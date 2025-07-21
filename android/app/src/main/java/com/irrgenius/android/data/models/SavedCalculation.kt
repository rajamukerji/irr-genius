package com.irrgenius.android.data.models

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDateTime
import java.util.UUID

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
    
    // Results
    val calculatedResult: Double?,
    val growthPointsJson: String?, // JSON serialized GrowthPoint array
    
    // Metadata
    val notes: String?,
    val tags: String? // JSON array as string
)

@Entity(tableName = "projects")
data class Project(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val description: String?,
    val createdDate: LocalDateTime,
    val modifiedDate: LocalDateTime,
    val color: String?
)

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
    val customValuation: Double?
)