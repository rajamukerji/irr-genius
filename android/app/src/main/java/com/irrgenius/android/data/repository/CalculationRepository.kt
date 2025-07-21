package com.irrgenius.android.data.repository

import com.irrgenius.android.data.models.SavedCalculation
import com.irrgenius.android.data.models.Project
import kotlinx.coroutines.flow.Flow

interface CalculationRepository {
    suspend fun saveCalculation(calculation: SavedCalculation)
    suspend fun loadCalculations(): List<SavedCalculation>
    fun loadCalculationsFlow(): Flow<List<SavedCalculation>>
    suspend fun loadCalculation(id: String): SavedCalculation?
    suspend fun deleteCalculation(id: String)
    suspend fun searchCalculations(query: String): List<SavedCalculation>
    suspend fun loadCalculationsByProject(projectId: String): List<SavedCalculation>
}

interface ProjectRepository {
    suspend fun saveProject(project: Project)
    suspend fun loadProjects(): List<Project>
    fun loadProjectsFlow(): Flow<List<Project>>
    suspend fun loadProject(id: String): Project?
    suspend fun deleteProject(id: String)
    suspend fun searchProjects(query: String): List<Project>
}

sealed class RepositoryError : Exception() {
    data class PersistenceError(override val cause: Throwable) : RepositoryError()
    object NotFound : RepositoryError()
    object InvalidData : RepositoryError()
    object DuplicateEntry : RepositoryError()
    
    override val message: String
        get() = when (this) {
            is PersistenceError -> "Failed to save data: ${cause.message}"
            is NotFound -> "Item not found"
            is InvalidData -> "Invalid data provided"
            is DuplicateEntry -> "Item already exists"
        }
}