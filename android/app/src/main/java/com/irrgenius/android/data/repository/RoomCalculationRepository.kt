package com.irrgenius.android.data.repository

import com.irrgenius.android.data.dao.CalculationDao
import com.irrgenius.android.data.dao.FollowOnInvestmentDao
import com.irrgenius.android.data.models.SavedCalculation
import com.irrgenius.android.data.models.SavedCalculationValidationException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import android.database.sqlite.SQLiteConstraintException
import android.database.sqlite.SQLiteException

class RoomCalculationRepository(
    private val calculationDao: CalculationDao,
    private val followOnInvestmentDao: FollowOnInvestmentDao
) : CalculationRepository {
    
    override suspend fun saveCalculation(calculation: SavedCalculation) {
        try {
            // Validate calculation before saving
            calculation.validate()
            
            // Check if calculation already exists
            val existingCalculation = calculationDao.getCalculationById(calculation.id)
            if (existingCalculation != null) {
                // Update existing calculation
                calculationDao.updateCalculation(calculation.withUpdatedModificationDate())
            } else {
                // Insert new calculation
                calculationDao.insertCalculation(calculation)
            }
            
        } catch (e: SavedCalculationValidationException) {
            throw RepositoryError.InvalidData
        } catch (e: SQLiteConstraintException) {
            throw RepositoryError.DuplicateEntry
        } catch (e: SQLiteException) {
            throw RepositoryError.PersistenceError(e)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override suspend fun loadCalculations(): List<SavedCalculation> {
        return try {
            calculationDao.getAllCalculations()
        } catch (e: SQLiteException) {
            throw RepositoryError.PersistenceError(e)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override fun loadCalculationsFlow(): Flow<List<SavedCalculation>> {
        return calculationDao.getAllCalculationsFlow()
            .catch { e ->
                when (e) {
                    is SQLiteException -> throw RepositoryError.PersistenceError(e)
                    else -> throw RepositoryError.PersistenceError(e)
                }
            }
    }
    
    override suspend fun loadCalculation(id: String): SavedCalculation? {
        return try {
            if (id.isBlank()) {
                throw RepositoryError.InvalidData
            }
            calculationDao.getCalculationById(id)
        } catch (e: SQLiteException) {
            throw RepositoryError.PersistenceError(e)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override suspend fun deleteCalculation(id: String) {
        try {
            if (id.isBlank()) {
                throw RepositoryError.InvalidData
            }
            
            // Check if calculation exists
            val calculation = calculationDao.getCalculationById(id)
                ?: throw RepositoryError.NotFound
            
            // Delete associated follow-on investments first (cascade should handle this, but being explicit)
            followOnInvestmentDao.deleteByCalculationId(id)
            
            // Delete the calculation
            calculationDao.deleteCalculationById(id)
            
        } catch (e: RepositoryError) {
            throw e
        } catch (e: SQLiteException) {
            throw RepositoryError.PersistenceError(e)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override suspend fun searchCalculations(query: String): List<SavedCalculation> {
        return try {
            if (query.isBlank()) {
                return emptyList()
            }
            calculationDao.searchCalculations(query.trim())
        } catch (e: SQLiteException) {
            throw RepositoryError.PersistenceError(e)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override suspend fun loadCalculationsByProject(projectId: String): List<SavedCalculation> {
        return try {
            if (projectId.isBlank()) {
                throw RepositoryError.InvalidData
            }
            calculationDao.getCalculationsByProject(projectId)
        } catch (e: SQLiteException) {
            throw RepositoryError.PersistenceError(e)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    /**
     * Additional method to get calculation count for a project
     */
    suspend fun getCalculationCountByProject(projectId: String): Int {
        return try {
            calculationDao.getCalculationsByProject(projectId).size
        } catch (e: Exception) {
            0
        }
    }
    
    /**
     * Additional method to get calculations by type
     */
    suspend fun getCalculationsByType(calculationType: String): List<SavedCalculation> {
        return try {
            calculationDao.getAllCalculations().filter { 
                it.calculationType.name == calculationType 
            }
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
}