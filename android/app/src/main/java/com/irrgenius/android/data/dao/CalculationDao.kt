package com.irrgenius.android.data.dao

import androidx.room.*
import com.irrgenius.android.data.models.SavedCalculation
import kotlinx.coroutines.flow.Flow

@Dao
interface CalculationDao {
    @Query("SELECT * FROM saved_calculations ORDER BY modifiedDate DESC")
    suspend fun getAllCalculations(): List<SavedCalculation>
    
    @Query("SELECT * FROM saved_calculations ORDER BY modifiedDate DESC")
    fun getAllCalculationsFlow(): Flow<List<SavedCalculation>>
    
    @Query("SELECT * FROM saved_calculations WHERE id = :id")
    suspend fun getCalculationById(id: String): SavedCalculation?
    
    @Query("SELECT * FROM saved_calculations WHERE projectId = :projectId ORDER BY modifiedDate DESC")
    suspend fun getCalculationsByProject(projectId: String): List<SavedCalculation>
    
    @Query("SELECT * FROM saved_calculations WHERE name LIKE '%' || :query || '%' OR notes LIKE '%' || :query || '%' ORDER BY modifiedDate DESC")
    suspend fun searchCalculations(query: String): List<SavedCalculation>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCalculation(calculation: SavedCalculation)
    
    @Update
    suspend fun updateCalculation(calculation: SavedCalculation)
    
    @Delete
    suspend fun deleteCalculation(calculation: SavedCalculation)
    
    @Query("DELETE FROM saved_calculations WHERE id = :id")
    suspend fun deleteCalculationById(id: String)
}