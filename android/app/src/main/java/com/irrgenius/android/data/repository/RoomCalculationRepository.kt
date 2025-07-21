package com.irrgenius.android.data.repository

import com.irrgenius.android.data.dao.CalculationDao
import com.irrgenius.android.data.dao.FollowOnInvestmentDao
import com.irrgenius.android.data.models.SavedCalculation
import kotlinx.coroutines.flow.Flow
class RoomCalculationRepository(
    private val calculationDao: CalculationDao,
    private val followOnInvestmentDao: FollowOnInvestmentDao
) : CalculationRepository {
    
    override suspend fun saveCalculation(calculation: SavedCalculation) {
        try {
            calculationDao.insertCalculation(calculation)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override suspend fun loadCalculations(): List<SavedCalculation> {
        return try {
            calculationDao.getAllCalculations()
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override fun loadCalculationsFlow(): Flow<List<SavedCalculation>> {
        return calculationDao.getAllCalculationsFlow()
    }
    
    override suspend fun loadCalculation(id: String): SavedCalculation? {
        return try {
            calculationDao.getCalculationById(id)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override suspend fun deleteCalculation(id: String) {
        try {
            calculationDao.deleteCalculationById(id)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override suspend fun searchCalculations(query: String): List<SavedCalculation> {
        return try {
            calculationDao.searchCalculations(query)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override suspend fun loadCalculationsByProject(projectId: String): List<SavedCalculation> {
        return try {
            calculationDao.getCalculationsByProject(projectId)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
}