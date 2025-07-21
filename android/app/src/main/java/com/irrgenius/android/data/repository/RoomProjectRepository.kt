package com.irrgenius.android.data.repository

import com.irrgenius.android.data.dao.ProjectDao
import com.irrgenius.android.data.models.Project
import kotlinx.coroutines.flow.Flow
class RoomProjectRepository(
    private val projectDao: ProjectDao
) : ProjectRepository {
    
    override suspend fun saveProject(project: Project) {
        try {
            projectDao.insertProject(project)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override suspend fun loadProjects(): List<Project> {
        return try {
            projectDao.getAllProjects()
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override fun loadProjectsFlow(): Flow<List<Project>> {
        return projectDao.getAllProjectsFlow()
    }
    
    override suspend fun loadProject(id: String): Project? {
        return try {
            projectDao.getProjectById(id)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override suspend fun deleteProject(id: String) {
        try {
            projectDao.deleteProjectById(id)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
    
    override suspend fun searchProjects(query: String): List<Project> {
        return try {
            projectDao.searchProjects(query)
        } catch (e: Exception) {
            throw RepositoryError.PersistenceError(e)
        }
    }
}