package com.irrgenius.android.data.dao

import androidx.room.*
import com.irrgenius.android.data.models.Project
import kotlinx.coroutines.flow.Flow

@Dao
interface ProjectDao {
    @Query("SELECT * FROM projects ORDER BY modifiedDate DESC")
    suspend fun getAllProjects(): List<Project>
    
    @Query("SELECT * FROM projects ORDER BY modifiedDate DESC")
    fun getAllProjectsFlow(): Flow<List<Project>>
    
    @Query("SELECT * FROM projects WHERE id = :id")
    suspend fun getProjectById(id: String): Project?
    
    @Query("SELECT * FROM projects WHERE name LIKE '%' || :query || '%' OR description LIKE '%' || :query || '%' ORDER BY modifiedDate DESC")
    suspend fun searchProjects(query: String): List<Project>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProject(project: Project)
    
    @Update
    suspend fun updateProject(project: Project)
    
    @Delete
    suspend fun deleteProject(project: Project)
    
    @Query("DELETE FROM projects WHERE id = :id")
    suspend fun deleteProjectById(id: String)
}