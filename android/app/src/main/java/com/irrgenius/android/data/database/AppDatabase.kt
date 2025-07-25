package com.irrgenius.android.data.database

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import android.content.Context
import com.irrgenius.android.data.dao.CalculationDao
import com.irrgenius.android.data.dao.FollowOnInvestmentDao
import com.irrgenius.android.data.dao.ProjectDao
import com.irrgenius.android.data.models.FollowOnInvestmentEntity
import com.irrgenius.android.data.models.Project
import com.irrgenius.android.data.models.SavedCalculation

@Database(
    entities = [SavedCalculation::class, Project::class, FollowOnInvestmentEntity::class],
    version = 2,
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun calculationDao(): CalculationDao
    abstract fun projectDao(): ProjectDao
    abstract fun followOnInvestmentDao(): FollowOnInvestmentDao
    
    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null
        
        // Migration from version 1 to 2 - adds Portfolio Unit Investment fields
        val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(database: SupportSQLiteDatabase) {
                // Add new columns for Portfolio Unit Investment
                database.execSQL("ALTER TABLE saved_calculations ADD COLUMN unitPrice REAL")
                database.execSQL("ALTER TABLE saved_calculations ADD COLUMN successRate REAL")
                database.execSQL("ALTER TABLE saved_calculations ADD COLUMN outcomePerUnit REAL")
                database.execSQL("ALTER TABLE saved_calculations ADD COLUMN investorShare REAL")
                database.execSQL("ALTER TABLE saved_calculations ADD COLUMN feePercentage REAL")
                
                // Add indexes for better query performance
                database.execSQL("CREATE INDEX IF NOT EXISTS index_saved_calculations_projectId ON saved_calculations(projectId)")
                database.execSQL("CREATE INDEX IF NOT EXISTS index_saved_calculations_calculationType ON saved_calculations(calculationType)")
                database.execSQL("CREATE INDEX IF NOT EXISTS index_saved_calculations_modifiedDate ON saved_calculations(modifiedDate)")
                database.execSQL("CREATE INDEX IF NOT EXISTS index_projects_modifiedDate ON projects(modifiedDate)")
                database.execSQL("CREATE INDEX IF NOT EXISTS index_follow_on_investments_calculationId ON follow_on_investments(calculationId)")
            }
        }
        
        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "irr_genius_database"
                )
                .addMigrations(MIGRATION_1_2)
                .fallbackToDestructiveMigration() // Only for development - remove in production
                .build()
                INSTANCE = instance
                instance
            }
        }
        
        // For testing purposes
        fun getInMemoryDatabase(context: Context): AppDatabase {
            return Room.inMemoryDatabaseBuilder(
                context.applicationContext,
                AppDatabase::class.java
            )
            .allowMainThreadQueries() // Only for testing
            .build()
        }
        
        // Clear instance for testing
        fun clearInstance() {
            INSTANCE = null
        }
    }
}