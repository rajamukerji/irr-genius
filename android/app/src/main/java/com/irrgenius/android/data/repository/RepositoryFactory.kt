package com.irrgenius.android.data.repository

import android.content.Context
import com.irrgenius.android.data.database.AppDatabase
import com.irrgenius.android.data.models.SavedCalculation
import com.irrgenius.android.data.models.Project
import kotlinx.coroutines.flow.Flow

// MARK: - Repository Factory Interface

interface RepositoryFactory {
    fun createCalculationRepository(): CalculationRepository
    fun createProjectRepository(): ProjectRepository
}

// MARK: - Production Repository Factory

class ProductionRepositoryFactory(private val context: Context) : RepositoryFactory {
    private val database: AppDatabase by lazy {
        AppDatabase.getDatabase(context)
    }
    
    override fun createCalculationRepository(): CalculationRepository {
        return RoomCalculationRepository(
            calculationDao = database.calculationDao(),
            followOnInvestmentDao = database.followOnInvestmentDao()
        )
    }
    
    override fun createProjectRepository(): ProjectRepository {
        return RoomProjectRepository(
            projectDao = database.projectDao(),
            calculationDao = database.calculationDao()
        )
    }
}

// MARK: - Test Repository Factory

class TestRepositoryFactory(private val context: Context) : RepositoryFactory {
    private val database: AppDatabase by lazy {
        AppDatabase.getInMemoryDatabase(context)
    }
    
    override fun createCalculationRepository(): CalculationRepository {
        return RoomCalculationRepository(
            calculationDao = database.calculationDao(),
            followOnInvestmentDao = database.followOnInvestmentDao()
        )
    }
    
    override fun createProjectRepository(): ProjectRepository {
        return RoomProjectRepository(
            projectDao = database.projectDao(),
            calculationDao = database.calculationDao()
        )
    }
}

// MARK: - Repository Manager (Dependency Injection Container)

class RepositoryManager private constructor(
    private val factory: RepositoryFactory
) {
    
    val calculationRepository: CalculationRepository by lazy {
        factory.createCalculationRepository()
    }
    
    val projectRepository: ProjectRepository by lazy {
        factory.createProjectRepository()
    }
    
    companion object {
        @Volatile
        private var INSTANCE: RepositoryManager? = null
        
        fun getInstance(context: Context): RepositoryManager {
            return INSTANCE ?: synchronized(this) {
                val instance = RepositoryManager(ProductionRepositoryFactory(context))
                INSTANCE = instance
                instance
            }
        }
        
        // For testing purposes
        fun createTestInstance(context: Context): RepositoryManager {
            return RepositoryManager(TestRepositoryFactory(context))
        }
        
        // Clear instance for testing
        fun clearInstance() {
            INSTANCE = null
        }
    }
}

// MARK: - Repository Extensions for Convenience

/**
 * Extension functions to provide safe repository operations with Result types
 */

suspend fun CalculationRepository.saveCalculationSafely(calculation: SavedCalculation): Result<Unit> {
    return try {
        saveCalculation(calculation)
        Result.success(Unit)
    } catch (e: RepositoryError) {
        Result.failure(e)
    } catch (e: Exception) {
        Result.failure(RepositoryError.PersistenceError(e))
    }
}

suspend fun CalculationRepository.loadCalculationsSafely(): Result<List<SavedCalculation>> {
    return try {
        val calculations = loadCalculations()
        Result.success(calculations)
    } catch (e: RepositoryError) {
        Result.failure(e)
    } catch (e: Exception) {
        Result.failure(RepositoryError.PersistenceError(e))
    }
}

suspend fun CalculationRepository.loadCalculationSafely(id: String): Result<SavedCalculation?> {
    return try {
        val calculation = loadCalculation(id)
        Result.success(calculation)
    } catch (e: RepositoryError) {
        Result.failure(e)
    } catch (e: Exception) {
        Result.failure(RepositoryError.PersistenceError(e))
    }
}

suspend fun CalculationRepository.deleteCalculationSafely(id: String): Result<Unit> {
    return try {
        deleteCalculation(id)
        Result.success(Unit)
    } catch (e: RepositoryError) {
        Result.failure(e)
    } catch (e: Exception) {
        Result.failure(RepositoryError.PersistenceError(e))
    }
}

suspend fun CalculationRepository.searchCalculationsSafely(query: String): Result<List<SavedCalculation>> {
    return try {
        val calculations = searchCalculations(query)
        Result.success(calculations)
    } catch (e: RepositoryError) {
        Result.failure(e)
    } catch (e: Exception) {
        Result.failure(RepositoryError.PersistenceError(e))
    }
}

suspend fun ProjectRepository.saveProjectSafely(project: Project): Result<Unit> {
    return try {
        saveProject(project)
        Result.success(Unit)
    } catch (e: RepositoryError) {
        Result.failure(e)
    } catch (e: Exception) {
        Result.failure(RepositoryError.PersistenceError(e))
    }
}

suspend fun ProjectRepository.loadProjectsSafely(): Result<List<Project>> {
    return try {
        val projects = loadProjects()
        Result.success(projects)
    } catch (e: RepositoryError) {
        Result.failure(e)
    } catch (e: Exception) {
        Result.failure(RepositoryError.PersistenceError(e))
    }
}

suspend fun ProjectRepository.loadProjectSafely(id: String): Result<Project?> {
    return try {
        val project = loadProject(id)
        Result.success(project)
    } catch (e: RepositoryError) {
        Result.failure(e)
    } catch (e: Exception) {
        Result.failure(RepositoryError.PersistenceError(e))
    }
}

suspend fun ProjectRepository.deleteProjectSafely(id: String): Result<Unit> {
    return try {
        deleteProject(id)
        Result.success(Unit)
    } catch (e: RepositoryError) {
        Result.failure(e)
    } catch (e: Exception) {
        Result.failure(RepositoryError.PersistenceError(e))
    }
}

suspend fun ProjectRepository.searchProjectsSafely(query: String): Result<List<Project>> {
    return try {
        val projects = searchProjects(query)
        Result.success(projects)
    } catch (e: RepositoryError) {
        Result.failure(e)
    } catch (e: Exception) {
        Result.failure(RepositoryError.PersistenceError(e))
    }
}