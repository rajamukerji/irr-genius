package com.irrgenius.android.data.models

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDateTime
import java.util.UUID

// Validation exception for Project
class ProjectValidationException(message: String) : Exception(message)

@Entity(tableName = "projects")
data class Project(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val description: String?,
    val createdDate: LocalDateTime,
    val modifiedDate: LocalDateTime,
    val color: String?
) {
    
    companion object {
        private const val MAX_NAME_LENGTH = 50
        private const val MAX_DESCRIPTION_LENGTH = 500
        
        /**
         * Validates project name
         */
        @Throws(ProjectValidationException::class)
        fun validateName(name: String) {
            if (name.trim().isEmpty()) {
                throw ProjectValidationException("Project name cannot be empty")
            }
            
            if (name.length > MAX_NAME_LENGTH) {
                throw ProjectValidationException("Name too long (max $MAX_NAME_LENGTH characters)")
            }
            
            // Check for invalid characters
            val invalidChars = listOf('<', '>', ':', '"', '/', '\\', '|', '?', '*')
            if (name.any { it in invalidChars }) {
                throw ProjectValidationException("Name contains invalid characters")
            }
        }
        
        /**
         * Validates project description
         */
        @Throws(ProjectValidationException::class)
        fun validateDescription(description: String) {
            if (description.length > MAX_DESCRIPTION_LENGTH) {
                throw ProjectValidationException("Description too long (max $MAX_DESCRIPTION_LENGTH characters)")
            }
        }
        
        /**
         * Validates project color (hex format)
         */
        @Throws(ProjectValidationException::class)
        fun validateColor(color: String) {
            val hexPattern = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$".toRegex()
            if (!hexPattern.matches(color)) {
                throw ProjectValidationException("Must be a valid hex color (e.g., #FF0000)")
            }
        }
        
        /**
         * Creates a validated Project instance
         */
        @Throws(ProjectValidationException::class)
        fun createValidated(
            id: String = UUID.randomUUID().toString(),
            name: String,
            description: String? = null,
            createdDate: LocalDateTime = LocalDateTime.now(),
            modifiedDate: LocalDateTime = LocalDateTime.now(),
            color: String? = null
        ): Project {
            validateName(name)
            description?.let { validateDescription(it) }
            color?.let { validateColor(it) }
            
            return Project(
                id = id,
                name = name,
                description = description,
                createdDate = createdDate,
                modifiedDate = modifiedDate,
                color = color
            )
        }
        
        /**
         * Default project colors for UI
         */
        val defaultColors = listOf(
            "#007AFF", // Blue
            "#34C759", // Green
            "#FF9500", // Orange
            "#FF3B30", // Red
            "#AF52DE", // Purple
            "#FF2D92", // Pink
            "#5AC8FA", // Light Blue
            "#FFCC00", // Yellow
            "#FF6B6B", // Light Red
            "#4ECDC4"  // Teal
        )
    }
    
    /**
     * Validates the entire project for data integrity
     */
    @Throws(ProjectValidationException::class)
    fun validate() {
        validateName(name)
        description?.let { validateDescription(it) }
        color?.let { validateColor(it) }
    }
    
    /**
     * Checks if project has valid data
     */
    val isValid: Boolean
        get() = try {
            validate()
            true
        } catch (e: ProjectValidationException) {
            false
        }
    
    /**
     * Creates a copy with updated modification date
     */
    fun withUpdatedModificationDate(): Project {
        return copy(modifiedDate = LocalDateTime.now())
    }
    
    /**
     * Calculates statistics for calculations associated with this project
     */
    fun calculateStatistics(calculations: List<SavedCalculation>): ProjectStatistics {
        val projectCalculations = calculations.filter { it.projectId == this.id }
        
        return ProjectStatistics(
            totalCalculations = projectCalculations.size,
            completedCalculations = projectCalculations.count { it.isComplete },
            lastModified = projectCalculations.maxByOrNull { it.modifiedDate }?.modifiedDate,
            calculationTypes = projectCalculations.groupBy { it.calculationType }
                .mapValues { it.value.size }
        )
    }
    
    // Convenience property for UI display - calculates calculation count from DataManager
    val calculationCount: Int
        get() = 0 // This will be calculated by the DataManager when needed
}

/**
 * Statistics for a project's calculations
 */
data class ProjectStatistics(
    val totalCalculations: Int,
    val completedCalculations: Int,
    val lastModified: LocalDateTime?,
    val calculationTypes: Map<CalculationMode, Int>
) {
    val completionRate: Double
        get() = if (totalCalculations > 0) {
            completedCalculations.toDouble() / totalCalculations.toDouble()
        } else {
            0.0
        }
}