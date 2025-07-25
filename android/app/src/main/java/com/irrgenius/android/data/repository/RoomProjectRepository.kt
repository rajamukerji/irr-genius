package com.irrgenius.android.data.repository

import com.irrgenius.android.data.dao.ProjectDao
import com.irrgenius.android.data.dao.CalculationDao
import com.irrgenius.android.data.models.Project
import com.irrgenius.android.data.models.ProjectValidationException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import android.database.sqlite.SQLiteConstraintException
import android.database.sqlite.SQLiteException

class RoomProjectRepository(
    private val projectDao: ProjectDao,
    private val calculationDao: CalculationDao
) : ProjectRepository {
    
    override suspend fun saveProject(project: Project) {
        try {
            // Validate project before saving
            project.validate()
            
            // Check if project already exists
            val existingProject = projectDao.getProjectById(project.id)
            if (existingProject != null) {
                // Update existing project
                projectDao.updateProject(project.withUpdatedModificationDate())
            } else {
                // Insert new project
                projectDao.insertProject(project)
            }
            
        } catch (e: ProjectValidationException) {
            throw RepositoryError.InvalidData
        } catch (e: SQLiteConstraintException) {
            throw RepositoryError.DuplicateEntry
        } catch (e: SQLiteException) {
            throw RepositoryError.PersistenceError(e)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override suspend fun loadProjects(): List<Project> {
        return try {
            projectDao.getAllProjects()
        } catch (e: SQLiteException) {
            throw RepositoryError.PersistenceError(e)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override fun loadProjectsFlow(): Flow<List<Project>> {
        return projectDao.getAllProjectsFlow()
            .catch { e ->
                when (e) {
                    is SQLiteException -> throw RepositoryError.PersistenceError(e)
                    else -> throw RepositoryError.PersistenceError(e)
                }
            }
    }
    
    override suspend fun loadProject(id: String): Project? {
        return try {
            if (id.isBlank()) {
                throw RepositoryError.InvalidData
            }
            projectDao.getProjectById(id)
        } catch (e: SQLiteException) {
            throw RepositoryError.PersistenceError(e)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override suspend fun deleteProject(id: String) {
        try {
            if (id.isBlank()) {
                throw RepositoryError.InvalidData
            }
            
            // Check if project exists
            val project = projectDao.getProjectById(id)
                ?: throw RepositoryError.NotFound
            
            // Check if project has associated calculations
            val calculations = calculationDao.getCalculationsByProject(id)
            if (calculations.isNotEmpty()) {
                // For now, we'll prevent deletion of projects with calculations
                // In a real app, you might want to ask the user what to do
                throw RepositoryError.PersistenceError(
                    IllegalStateException("Cannot delete project with associated calculations")
                )
            }
            
            // Delete the project
            projectDao.deleteProjectById(id)
            
        } catch (e: RepositoryError) {
            throw e
        } catch (e: SQLiteException) {
            throw RepositoryError.PersistenceError(e)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override suspend fun searchProjects(query: String): List<Project> {
        return try {
            if (query.isBlank()) {
                return emptyList()
            }
            projectDao.searchProjects(query.trim())
        } catch (e: SQLiteException) {
            throw RepositoryError.PersistenceError(e)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    /**
     * Additional method to get project with calculation statistics
     */
    suspend fun getProjectWithStatistics(id: String): Pair<Project, Int>? {
        return try {
            val project = projectDao.getProjectById(id) ?: return null
            val calculationCount = calculationDao.getCalculationsByProject(id).size
            Pair(project, calculationCount)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    /**
     * Additional method to delete project and optionally move calculations to another project
     */
    suspend fun deleteProjectWithCalculationHandling(
        projectId: String, 
        moveCalculationsToProjectId: String? = null
    ) {
        try {
            if (projectId.isBlank()) {
                throw RepositoryError.InvalidData
            }
            
            // Check if project exists
            val project = projectDao.getProjectById(projectId)
                ?: throw RepositoryError.NotFound
            
            // Get associated calculations
            val calculations = calculationDao.getCalculationsByProject(projectId)
            
            if (calculations.isNotEmpty()) {
                if (moveCalculationsToProjectId != null) {
                    // Move calculations to another project
                    calculations.forEach { calculation ->
                        calculationDao.updateCalculation(
                            calculation.copy(projectId = moveCalculationsToProjectId)
                        )
                    }
                } else {
                    // Set calculations to have no project (null projectId)
                    calculations.forEach { calculation ->
                        calculationDao.updateCalculation(
                            calculation.copy(projectId = null)
                        )
                    }
                }
            }
            
            // Delete the project
            projectDao.deleteProjectById(projectId)
            
        } catch (e: RepositoryError) {
            throw e
        } catch (e: SQLiteException) {
            throw RepositoryError.PersistenceError(e)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
}