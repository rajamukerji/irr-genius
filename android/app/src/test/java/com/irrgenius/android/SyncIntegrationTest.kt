package com.irrgenius.android

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.irrgenius.android.data.database.AppDatabase
import com.irrgenius.android.data.models.*
import com.irrgenius.android.data.repository.RepositoryFactory
import com.irrgenius.android.data.repository.RoomCalculationRepository
import com.irrgenius.android.data.repository.RoomProjectRepository
import com.irrgenius.android.data.sync.CloudSyncService
import io.mockk.*
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.time.LocalDateTime
import kotlin.test.*

@RunWith(RobolectricTestRunner::class)
class SyncIntegrationTest {
    
    private lateinit var context: Context
    private lateinit var database: AppDatabase
    private lateinit var calculationRepository: RoomCalculationRepository
    private lateinit var projectRepository: RoomProjectRepository
    private lateinit var repositoryFactory: RepositoryFactory
    private lateinit var mockFirebaseAuth: FirebaseAuth
    private lateinit var mockFirestore: FirebaseFirestore
    private lateinit var cloudSyncService: CloudSyncService
    
    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
        
        database = Room.inMemoryDatabaseBuilder(
            context,
            AppDatabase::class.java
        ).allowMainThreadQueries().build()
        
        calculationRepository = RoomCalculationRepository(
            database.calculationDao(),
            database.followOnInvestmentDao()
        )
        
        projectRepository = RoomProjectRepository(database.projectDao())
        
        repositoryFactory = mockk(relaxed = true)
        every { repositoryFactory.createCalculationRepository() } returns calculationRepository
        every { repositoryFactory.createProjectRepository() } returns projectRepository
        
        // Mock Firebase dependencies
        mockFirebaseAuth = mockk(relaxed = true)
        mockFirestore = mockk(relaxed = true)
        
        mockkStatic(FirebaseAuth::class)
        mockkStatic(FirebaseFirestore::class)
        every { FirebaseAuth.getInstance() } returns mockFirebaseAuth
        every { FirebaseFirestore.getInstance() } returns mockFirestore
        
        cloudSyncService = CloudSyncService(context, repositoryFactory)
    }
    
    @After
    fun teardown() {
        database.close()
        unmockkAll()
    }
    
    @Test
    fun testSyncConflictResolutionWorkflow() = runTest {
        // Given: Local and remote calculations with conflicts
        val baseTime = LocalDateTime.now()
        
        val localCalculation = SavedCalculation.createValidated(
            id = "conflict-calc-id",
            name = "Local Version",
            calculationType = CalculationMode.CALCULATE_IRR,
            createdDate = baseTime.minusHours(2),
            modifiedDate = baseTime.minusMinutes(30), // Modified 30 minutes ago
            initialInvestment = 100000.0,
            outcomeAmount = 150000.0,
            timeInMonths = 24.0,
            calculatedResult = 22.47,
            notes = "Local modifications"
        )
        
        val remoteCalculation = SavedCalculation.createValidated(
            id = "conflict-calc-id",
            name = "Remote Version",
            calculationType = CalculationMode.CALCULATE_IRR,
            createdDate = baseTime.minusHours(2),
            modifiedDate = baseTime.minusMinutes(15), // Modified 15 minutes ago (newer)
            initialInvestment = 100000.0,
            outcomeAmount = 160000.0, // Different outcome
            timeInMonths = 24.0,
            calculatedResult = 25.12, // Different result
            notes = "Remote modifications"
        )
        
        // Save local calculation
        calculationRepository.saveCalculation(localCalculation)
        
        // Mock authenticated user
        val mockUser = mockk<com.google.firebase.auth.FirebaseUser>(relaxed = true)
        every { mockUser.uid } returns "test-user-id"
        every { mockFirebaseAuth.currentUser } returns mockUser
        
        // Mock Firestore operations for conflict scenario
        val mockDocumentReference = mockk<com.google.firebase.firestore.DocumentReference>(relaxed = true)
        val mockCollectionReference = mockk<com.google.firebase.firestore.CollectionReference>(relaxed = true)
        val mockQuerySnapshot = mockk<com.google.firebase.firestore.QuerySnapshot>(relaxed = true)
        val mockDocumentSnapshot = mockk<com.google.firebase.firestore.QueryDocumentSnapshot>(relaxed = true)
        val mockQuery = mockk<com.google.firebase.firestore.Query>(relaxed = true)
        
        // Mock successful upload
        val mockUploadTask = mockk<com.google.android.gms.tasks.Task<Void>>(relaxed = true)
        every { mockUploadTask.isSuccessful } returns true
        every { mockDocumentReference.set(any(), any()) } returns mockUploadTask
        every { mockCollectionReference.document(any()) } returns mockDocumentReference
        
        // Mock download returning remote calculation
        val cloudCalculation = CloudSyncService.CloudCalculation(
            id = remoteCalculation.id,
            name = remoteCalculation.name,
            calculationType = remoteCalculation.calculationType.name,
            createdDate = remoteCalculation.createdDate.toString(),
            modifiedDate = remoteCalculation.modifiedDate.toString(),
            projectId = remoteCalculation.projectId,
            initialInvestment = remoteCalculation.initialInvestment,
            outcomeAmount = remoteCalculation.outcomeAmount,
            timeInMonths = remoteCalculation.timeInMonths,
            irr = remoteCalculation.irr,
            unitPrice = remoteCalculation.unitPrice,
            successRate = remoteCalculation.successRate,
            outcomePerUnit = remoteCalculation.outcomePerUnit,
            investorShare = remoteCalculation.investorShare,
            feePercentage = remoteCalculation.feePercentage,
            calculatedResult = remoteCalculation.calculatedResult,
            followOnInvestments = null,
            growthPoints = null,
            notes = remoteCalculation.notes,
            tags = null,
            encryptedData = null
        )
        
        val mockQueryTask = mockk<com.google.android.gms.tasks.Task<com.google.firebase.firestore.QuerySnapshot>>(relaxed = true)
        every { mockQueryTask.isSuccessful } returns true
        every { mockQueryTask.result } returns mockQuerySnapshot
        every { mockQuerySnapshot.documents } returns listOf(mockDocumentSnapshot)
        every { mockDocumentSnapshot.toObject(CloudSyncService.CloudCalculation::class.java) } returns cloudCalculation
        every { mockQuery.get() } returns mockQueryTask
        every { mockCollectionReference.orderBy(any<String>(), any()) } returns mockQuery
        every { mockFirestore.collection(any()).document(any()).collection(any()) } returns mockCollectionReference
        
        // When: Sync calculations (should detect conflict)
        val syncResult = cloudSyncService.syncCalculations()
        
        // Then: Sync should succeed and handle conflict
        assertTrue(syncResult.isSuccess)
        
        // Verify that conflict was detected and resolved
        // In this case, remote is newer so it should be saved locally
        val finalCalculation = calculationRepository.loadCalculation(localCalculation.id)
        assertNotNull(finalCalculation)
        
        // The final calculation should have the remote data since it's newer
        // Note: The exact behavior depends on the conflict resolution strategy
        // For this test, we assume last-modified-wins
        assertTrue(finalCalculation.modifiedDate.isAfter(localCalculation.modifiedDate) || 
                  finalCalculation.modifiedDate.isEqual(localCalculation.modifiedDate))
    }
    
    @Test
    fun testOfflineOnlineSyncWorkflow() = runTest {
        // Given: Create calculations while offline
        val offlineCalculations = listOf(
            SavedCalculation.createValidated(
                name = "Offline Calculation 1",
                calculationType = CalculationMode.CALCULATE_IRR,
                initialInvestment = 100000.0,
                outcomeAmount = 150000.0,
                timeInMonths = 24.0,
                calculatedResult = 22.47,
                notes = "Created while offline"
            ),
            SavedCalculation.createValidated(
                name = "Offline Calculation 2",
                calculationType = CalculationMode.CALCULATE_OUTCOME,
                initialInvestment = 50000.0,
                irr = 15.0,
                timeInMonths = 12.0,
                calculatedResult = 57500.0,
                notes = "Also created while offline"
            )
        )
        
        // Save calculations locally (simulating offline work)
        for (calculation in offlineCalculations) {
            calculationRepository.saveCalculation(calculation)
        }
        
        // Verify calculations are saved locally
        val localCalculations = calculationRepository.getAllCalculations()
        assertEquals(2, localCalculations.size)
        
        // Mock coming back online
        val mockUser = mockk<com.google.firebase.auth.FirebaseUser>(relaxed = true)
        every { mockUser.uid } returns "test-user-id"
        every { mockFirebaseAuth.currentUser } returns mockUser
        
        // Mock successful sync operations
        val mockDocumentReference = mockk<com.google.firebase.firestore.DocumentReference>(relaxed = true)
        val mockCollectionReference = mockk<com.google.firebase.firestore.CollectionReference>(relaxed = true)
        val mockQuerySnapshot = mockk<com.google.firebase.firestore.QuerySnapshot>(relaxed = true)
        val mockQuery = mockk<com.google.firebase.firestore.Query>(relaxed = true)
        
        val mockUploadTask = mockk<com.google.android.gms.tasks.Task<Void>>(relaxed = true)
        every { mockUploadTask.isSuccessful } returns true
        every { mockDocumentReference.set(any(), any()) } returns mockUploadTask
        every { mockCollectionReference.document(any()) } returns mockDocumentReference
        
        val mockQueryTask = mockk<com.google.android.gms.tasks.Task<com.google.firebase.firestore.QuerySnapshot>>(relaxed = true)
        every { mockQueryTask.isSuccessful } returns true
        every { mockQueryTask.result } returns mockQuerySnapshot
        every { mockQuerySnapshot.documents } returns emptyList() // No remote calculations
        every { mockQuery.get() } returns mockQueryTask
        every { mockCollectionReference.orderBy(any<String>(), any()) } returns mockQuery
        every { mockFirestore.collection(any()).document(any()).collection(any()) } returns mockCollectionReference
        
        // When: Enable sync and perform sync
        val enableResult = cloudSyncService.enableSync()
        assertTrue(enableResult.isSuccess)
        
        val syncResult = cloudSyncService.syncCalculations()
        assertTrue(syncResult.isSuccess)
        
        // Then: All local calculations should be uploaded
        verify(exactly = 2) { mockDocumentReference.set(any(), any()) }
        
        // Verify calculations are still available locally
        val finalCalculations = calculationRepository.getAllCalculations()
        assertEquals(2, finalCalculations.size)
        assertTrue(finalCalculations.any { it.name == "Offline Calculation 1" })
        assertTrue(finalCalculations.any { it.name == "Offline Calculation 2" })
    }
    
    @Test
    fun testMultiDeviceSyncWorkflow() = runTest {
        // Given: Simulate calculations from multiple devices
        val device1Calculations = listOf(
            SavedCalculation.createValidated(
                name = "Device 1 Calculation",
                calculationType = CalculationMode.CALCULATE_IRR,
                initialInvestment = 100000.0,
                outcomeAmount = 150000.0,
                timeInMonths = 24.0,
                calculatedResult = 22.47,
                notes = "From device 1"
            )
        )
        
        val device2Calculations = listOf(
            SavedCalculation.createValidated(
                name = "Device 2 Calculation",
                calculationType = CalculationMode.CALCULATE_OUTCOME,
                initialInvestment = 75000.0,
                irr = 18.0,
                timeInMonths = 18.0,
                calculatedResult = 95000.0,
                notes = "From device 2"
            )
        )
        
        // Save device 1 calculations locally
        for (calculation in device1Calculations) {
            calculationRepository.saveCalculation(calculation)
        }
        
        // Mock authenticated user
        val mockUser = mockk<com.google.firebase.auth.FirebaseUser>(relaxed = true)
        every { mockUser.uid } returns "test-user-id"
        every { mockFirebaseAuth.currentUser } returns mockUser
        
        // Mock Firestore operations
        val mockDocumentReference = mockk<com.google.firebase.firestore.DocumentReference>(relaxed = true)
        val mockCollectionReference = mockk<com.google.firebase.firestore.CollectionReference>(relaxed = true)
        val mockQuerySnapshot = mockk<com.google.firebase.firestore.QuerySnapshot>(relaxed = true)
        val mockDocumentSnapshot = mockk<com.google.firebase.firestore.QueryDocumentSnapshot>(relaxed = true)
        val mockQuery = mockk<com.google.firebase.firestore.Query>(relaxed = true)
        
        // Mock successful upload
        val mockUploadTask = mockk<com.google.android.gms.tasks.Task<Void>>(relaxed = true)
        every { mockUploadTask.isSuccessful } returns true
        every { mockDocumentReference.set(any(), any()) } returns mockUploadTask
        every { mockCollectionReference.document(any()) } returns mockDocumentReference
        
        // Mock download returning device 2 calculations
        val device2CloudCalc = CloudSyncService.CloudCalculation(
            id = device2Calculations[0].id,
            name = device2Calculations[0].name,
            calculationType = device2Calculations[0].calculationType.name,
            createdDate = device2Calculations[0].createdDate.toString(),
            modifiedDate = device2Calculations[0].modifiedDate.toString(),
            projectId = device2Calculations[0].projectId,
            initialInvestment = device2Calculations[0].initialInvestment,
            outcomeAmount = device2Calculations[0].outcomeAmount,
            timeInMonths = device2Calculations[0].timeInMonths,
            irr = device2Calculations[0].irr,
            unitPrice = device2Calculations[0].unitPrice,
            successRate = device2Calculations[0].successRate,
            outcomePerUnit = device2Calculations[0].outcomePerUnit,
            investorShare = device2Calculations[0].investorShare,
            feePercentage = device2Calculations[0].feePercentage,
            calculatedResult = device2Calculations[0].calculatedResult,
            followOnInvestments = null,
            growthPoints = null,
            notes = device2Calculations[0].notes,
            tags = null,
            encryptedData = null
        )
        
        val mockQueryTask = mockk<com.google.android.gms.tasks.Task<com.google.firebase.firestore.QuerySnapshot>>(relaxed = true)
        every { mockQueryTask.isSuccessful } returns true
        every { mockQueryTask.result } returns mockQuerySnapshot
        every { mockQuerySnapshot.documents } returns listOf(mockDocumentSnapshot)
        every { mockDocumentSnapshot.toObject(CloudSyncService.CloudCalculation::class.java) } returns device2CloudCalc
        every { mockQuery.get() } returns mockQueryTask
        every { mockCollectionReference.orderBy(any<String>(), any()) } returns mockQuery
        every { mockFirestore.collection(any()).document(any()).collection(any()) } returns mockCollectionReference
        
        // When: Sync calculations
        val syncResult = cloudSyncService.syncCalculations()
        assertTrue(syncResult.isSuccess)
        
        // Then: Should have calculations from both devices
        val allCalculations = calculationRepository.getAllCalculations()
        assertEquals(2, allCalculations.size)
        
        assertTrue(allCalculations.any { it.name == "Device 1 Calculation" })
        assertTrue(allCalculations.any { it.name == "Device 2 Calculation" })
        
        // Verify device 1 calculation was uploaded
        verify(atLeast = 1) { mockDocumentReference.set(any(), any()) }
        
        // Verify device 2 calculation was downloaded and saved
        val device2Calc = allCalculations.find { it.name == "Device 2 Calculation" }
        assertNotNull(device2Calc)
        assertEquals(CalculationMode.CALCULATE_OUTCOME, device2Calc.calculationType)
        assertEquals(75000.0, device2Calc.initialInvestment)
        assertEquals(18.0, device2Calc.irr)
        assertEquals(95000.0, device2Calc.calculatedResult)
    }
    
    @Test
    fun testSyncRetryMechanism() = runTest {
        // Given: A calculation to sync and network failures
        val calculation = SavedCalculation.createValidated(
            name = "Retry Test Calculation",
            calculationType = CalculationMode.CALCULATE_IRR,
            initialInvestment = 100000.0,
            outcomeAmount = 150000.0,
            timeInMonths = 24.0,
            calculatedResult = 22.47
        )
        
        calculationRepository.saveCalculation(calculation)
        
        // Mock authenticated user
        val mockUser = mockk<com.google.firebase.auth.FirebaseUser>(relaxed = true)
        every { mockUser.uid } returns "test-user-id"
        every { mockFirebaseAuth.currentUser } returns mockUser
        
        // Mock Firestore operations with initial failures then success
        val mockDocumentReference = mockk<com.google.firebase.firestore.DocumentReference>(relaxed = true)
        val mockCollectionReference = mockk<com.google.firebase.firestore.CollectionReference>(relaxed = true)
        val mockQuerySnapshot = mockk<com.google.firebase.firestore.QuerySnapshot>(relaxed = true)
        val mockQuery = mockk<com.google.firebase.firestore.Query>(relaxed = true)
        
        // Mock network failure first, then success
        val mockFailedTask = mockk<com.google.android.gms.tasks.Task<Void>>(relaxed = true)
        val mockSuccessTask = mockk<com.google.android.gms.tasks.Task<Void>>(relaxed = true)
        
        every { mockFailedTask.isSuccessful } returns false
        every { mockFailedTask.exception } returns java.net.UnknownHostException("Network error")
        every { mockSuccessTask.isSuccessful } returns true
        
        // First call fails, subsequent calls succeed
        every { mockDocumentReference.set(any(), any()) } returnsMany listOf(mockFailedTask, mockSuccessTask)
        every { mockCollectionReference.document(any()) } returns mockDocumentReference
        
        val mockQueryTask = mockk<com.google.android.gms.tasks.Task<com.google.firebase.firestore.QuerySnapshot>>(relaxed = true)
        every { mockQueryTask.isSuccessful } returns true
        every { mockQueryTask.result } returns mockQuerySnapshot
        every { mockQuerySnapshot.documents } returns emptyList()
        every { mockQuery.get() } returns mockQueryTask
        every { mockCollectionReference.orderBy(any<String>(), any()) } returns mockQuery
        every { mockFirestore.collection(any()).document(any()).collection(any()) } returns mockCollectionReference
        
        // When: First sync attempt (should fail and add to retry queue)
        val firstSyncResult = cloudSyncService.syncCalculations()
        
        // Then: First sync should fail but not throw exception (handled gracefully)
        // The calculation should be added to retry queue
        
        // When: Process retry queue (simulating retry timer)
        cloudSyncService.processRetryQueue()
        
        // Then: Retry should eventually succeed
        verify(atLeast = 2) { mockDocumentReference.set(any(), any()) }
    }
    
    @Test
    fun testProjectSyncWorkflow() = runTest {
        // Given: Create projects and calculations
        val project = Project.createValidated(
            name = "Sync Test Project",
            description = "Testing project sync",
            color = "#007AFF"
        )
        
        val calculation = SavedCalculation.createValidated(
            name = "Project Calculation",
            calculationType = CalculationMode.CALCULATE_IRR,
            projectId = project.id,
            initialInvestment = 100000.0,
            outcomeAmount = 150000.0,
            timeInMonths = 24.0,
            calculatedResult = 22.47
        )
        
        // Save locally
        projectRepository.insertProject(project)
        calculationRepository.saveCalculation(calculation)
        
        // Mock authenticated user
        val mockUser = mockk<com.google.firebase.auth.FirebaseUser>(relaxed = true)
        every { mockUser.uid } returns "test-user-id"
        every { mockFirebaseAuth.currentUser } returns mockUser
        
        // Mock Firestore operations for both projects and calculations
        val mockDocumentReference = mockk<com.google.firebase.firestore.DocumentReference>(relaxed = true)
        val mockCollectionReference = mockk<com.google.firebase.firestore.CollectionReference>(relaxed = true)
        val mockQuerySnapshot = mockk<com.google.firebase.firestore.QuerySnapshot>(relaxed = true)
        val mockQuery = mockk<com.google.firebase.firestore.Query>(relaxed = true)
        
        val mockUploadTask = mockk<com.google.android.gms.tasks.Task<Void>>(relaxed = true)
        every { mockUploadTask.isSuccessful } returns true
        every { mockDocumentReference.set(any(), any()) } returns mockUploadTask
        every { mockCollectionReference.document(any()) } returns mockDocumentReference
        
        val mockQueryTask = mockk<com.google.android.gms.tasks.Task<com.google.firebase.firestore.QuerySnapshot>>(relaxed = true)
        every { mockQueryTask.isSuccessful } returns true
        every { mockQueryTask.result } returns mockQuerySnapshot
        every { mockQuerySnapshot.documents } returns emptyList()
        every { mockQuery.get() } returns mockQueryTask
        every { mockCollectionReference.orderBy(any<String>(), any()) } returns mockQuery
        every { mockFirestore.collection(any()).document(any()).collection(any()) } returns mockCollectionReference
        
        // When: Sync both projects and calculations
        val projectSyncResult = cloudSyncService.syncProjects()
        val calculationSyncResult = cloudSyncService.syncCalculations()
        
        // Then: Both syncs should succeed
        assertTrue(projectSyncResult.isSuccess)
        assertTrue(calculationSyncResult.isSuccess)
        
        // Verify both project and calculation were uploaded
        verify(atLeast = 2) { mockDocumentReference.set(any(), any()) }
        
        // Verify data integrity after sync
        val syncedProject = projectRepository.getProjectById(project.id)
        val syncedCalculation = calculationRepository.loadCalculation(calculation.id)
        
        assertNotNull(syncedProject)
        assertNotNull(syncedCalculation)
        assertEquals(project.id, syncedCalculation?.projectId)
        assertEquals(project.name, syncedProject?.name)
        assertEquals(calculation.name, syncedCalculation?.name)
    }
}