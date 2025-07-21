package com.irrgenius.android

import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.irrgenius.android.data.database.AppDatabase
import com.irrgenius.android.data.models.Project
import com.irrgenius.android.data.repository.RoomProjectRepository
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.time.LocalDateTime
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

@RunWith(RobolectricTestRunner::class)
class RoomProjectRepositoryTest {
    
    private lateinit var database: AppDatabase
    private lateinit var repository: RoomProjectRepository
    
    @Before
    fun setup() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            AppDatabase::class.java
        ).allowMainThreadQueries().build()
        
        repository = RoomProjectRepository(database.projectDao())
    }
    
    @After
    fun teardown() {
        database.close()
    }
    
    @Test
    fun saveAndLoadProject() = runTest {
        // Given
        val project = createTestProject()
        
        // When
        repository.saveProject(project)
        val loaded = repository.loadProject(project.id)
        
        // Then
        assertNotNull(loaded)
        assertEquals(project.id, loaded.id)
        assertEquals(project.name, loaded.name)
        assertEquals(project.description, loaded.description)
        assertEquals(project.color, loaded.color)
    }
    
    @Test
    fun loadAllProjects() = runTest {
        // Given
        val project1 = createTestProject(name = "Project 1")
        val project2 = createTestProject(name = "Project 2")
        
        // When
        repository.saveProject(project1)
        repository.saveProject(project2)
        val projects = repository.loadProjects()
        
        // Then
        assertEquals(2, projects.size)
        assertTrue(projects.any { it.name == "Project 1" })
        assertTrue(projects.any { it.name == "Project 2" })
    }
    
    @Test
    fun deleteProject() = runTest {
        // Given
        val project = createTestProject()
        repository.saveProject(project)
        
        // When
        repository.deleteProject(project.id)
        val loaded = repository.loadProject(project.id)
        
        // Then
        assertNull(loaded)
    }
    
    @Test
    fun searchProjects() = runTest {
        // Given
        val project1 = createTestProject(name = "Real Estate Analysis")
        val project2 = createTestProject(name = "Stock Investment")
        val project3 = createTestProject(name = "Bond Study", description = "Real estate bonds")
        
        repository.saveProject(project1)
        repository.saveProject(project2)
        repository.saveProject(project3)
        
        // When
        val results = repository.searchProjects("Real")
        
        // Then
        assertEquals(2, results.size)
        assertTrue(results.any { it.name == "Real Estate Analysis" })
        assertTrue(results.any { it.name == "Bond Study" })
    }
    
    private fun createTestProject(
        name: String = "Test Project",
        description: String? = "Test project description"
    ): Project {
        return Project(
            name = name,
            description = description,
            createdDate = LocalDateTime.now(),
            modifiedDate = LocalDateTime.now(),
            color = "#FF5733"
        )
    }
}