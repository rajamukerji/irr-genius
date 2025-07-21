package com.irrgenius.android.data.dao

import androidx.room.*
import com.irrgenius.android.data.models.FollowOnInvestmentEntity

@Dao
interface FollowOnInvestmentDao {
    @Query("SELECT * FROM follow_on_investments WHERE calculationId = :calculationId")
    suspend fun getFollowOnInvestmentsByCalculation(calculationId: String): List<FollowOnInvestmentEntity>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertFollowOnInvestment(investment: FollowOnInvestmentEntity)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertFollowOnInvestments(investments: List<FollowOnInvestmentEntity>)
    
    @Delete
    suspend fun deleteFollowOnInvestment(investment: FollowOnInvestmentEntity)
    
    @Query("DELETE FROM follow_on_investments WHERE calculationId = :calculationId")
    suspend fun deleteFollowOnInvestmentsByCalculation(calculationId: String)
}