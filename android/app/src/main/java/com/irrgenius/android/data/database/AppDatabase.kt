package com.irrgenius.android.data.database

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import android.content.Context
import com.irrgenius.android.data.dao.CalculationDao
import com.irrgenius.android.data.dao.FollowOnInvestmentDao
import com.irrgenius.android.data.dao.ProjectDao
import com.irrgenius.android.data.models.FollowOnInvestmentEntity
import com.irrgenius.android.data.models.Project
import com.irrgenius.android.data.models.SavedCalculation

@Database(
    entities = [SavedCalculation::class, Project::class, FollowOnInvestmentEntity::class],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun calculationDao(): CalculationDao
    abstract fun projectDao(): ProjectDao
    abstract fun followOnInvestmentDao(): FollowOnInvestmentDao
    
    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null
        
        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "irr_genius_database"
                ).build()
                INSTANCE = instance
                instance
            }
        }
        
        // For testing purposes
        fun getInMemoryDatabase(context: Context): AppDatabase {
            return Room.inMemoryDatabaseBuilder(
                context.applicationContext,
                AppDatabase::class.java
            ).build()
        }
    }
}