package com.irrgenius.android

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.irrgenius.android.data.models.*
import com.irrgenius.android.data.repository.RepositoryFactory
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
class CloudSyncServiceTest {
    
    private lateinit var context: Context
    private lateinit var mockRepositoryFactory: RepositoryFactory
    private lateinit var mockFirebaseAuth: FirebaseAuth
    private lateinit var mockFirestore: FirebaseFirestore
    private lateinit var cloudSyncService: CloudSyncService
    
    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
        
        // Mock Firebase dependencies
        mockFirebaseAuth = mockk(relaxed = true)
        mockFirestore = mockk(relaxed = true)
        mockRepositoryFactory = mockk(relaxed = true)
        
        // Mock static Firebase instances
        mockkStatic(FirebaseAuth::class)
        mockkStatic(FirebaseFirestore::class)
        every { FirebaseAuth.getInstance() } returns mockFirebaseAuth
        every { FirebaseFirestore.getInstance() } returns mockFirestore
        
        cloudSyncService = CloudSyncService(context, mockRepositoryFactory)
    }
    
    @After
    fun tearDown() {
        unmockkAll()
    }
    
    @Test
    fun testSyncStatusInitialization() {
        // When service is created
        // Then initial status should be idle
        assertEquals(CloudSyncService.SyncStatus.Idle, cloudSyncService.syncStatus.value)
        assertEquals(0.0, cloudSyncService.syncProgress.value)
        assertTrue(cloudSyncService.pendingConflicts.value.isEmpty())
    }
    
    @Test
    fun testEnableSyncSuccess() = runTest {
        // Given authenticated user
        val mockUser = mockk<com.google.firebase.auth.FirebaseUser>(relaxed = true)
        every { mockUser.uid } returns "test-user-id"
        every { mockFirebaseAuth.currentUser } returns mockUser
        
        // Mock successful authentication
        val mockAuthResult = mockk<com.google.firebase.auth.AuthResult>(relaxed = true)
        every { mockAuthResult.user } returns mockUser
        
        val mockTask = mockk<com.google.android.gms.tasks.Task<com.google.firebase.auth.AuthResult>>(relaxed = true)
        every { mockTask.isSuccessful } returns true
        every { mockTask.result } returns mockAuthResult
        every { mockFirebaseAuth.signInAnonymously() } returns mockTask
        
        // When enabling sync
        val result = cloudSyncService.enableSync()
        
        // Then should succeed
        assertTrue(result.isSuccess)
        verify { mockFirebaseAuth.signInAnonymously() }
    }
    
    @Test
    fun testEnableSyncFailure() = runTest {
        // Given authentication failure
        every { mockFirebaseAuth.currentUser } returns null
        
        val mockTask = mockk<com.google.android.gms.tasks.Task<com.google.firebase.auth.AuthResult>>(relaxed = true)
        every { mockTask.isSuccessful } returns false
        every { mockTask.exception } returns Exception("Auth failed")
        every { mockFirebaseAuth.signInAnonymously() } returns mockTask
        
        // When enabling sync
        val result = cloudSyncService.enableSync()
        
        // Then should fail
        assertTrue(result.isFailure)
        assertNotNull(result.exceptionOrNull())
    }
    
    @Test
    fun testDisableSync() = runTest {
        // When disabling sync
        val result = cloudSyncService.disableSync()
        
        // Then should succeed and update status
        assertTrue(result.isSuccess)
        assertEquals(CloudSyncService.SyncStatus.Idle, cloudSyncService.syncStatus.value)
    }
    
    @Test
    fun testUploadCalculationSuccess() = runTest {
        // Given authenticated user and calculation
        val mockUser = mockk<com.google.firebase.auth.FirebaseUser>(relaxed = true)
        every { mockUser.uid } returns "test-user-id"
        every { mockFirebaseAuth.currentUser } returns mockUser
        
        val calculation = createTestCalculation()
        
        // Mock successful Firestore operation
        val mockDocumentReference = mockk<com.google.firebase.firestore.DocumentReference>(relaxed = true)
        val mockCollectionReference = mockk<com.google.firebase.firestore.CollectionReference>(relaxed = true)
        val mockTask = mockk<com.google.android.gms.tasks.Task<Void>>(relaxed = true)
        
        every { mockTask.isSuccessful } returns true
        every { mockDocumentReference.set(any(), any()) } returns mockTask
        every { mockCollectionReference.document(any()) } returns mockDocumentReference
        every { mockFirestore.collection(any()).document(any()).collection(any()) } returns mockCollectionReference
        
        // When uploading calculation
        val result = cloudSyncService.uploadCalculation(calculation)
        
        // Then should succeed
        assertTrue(result.isSuccess)
        verify { mockDocumentReference.set(any(), any()) }
    }
    
    @Test
    fun testUploadCalculationFailure() = runTest {
        // Given authenticated user but Firestore failure
        val mockUser = mockk<com.google.firebase.auth.FirebaseUser>(relaxed = true)
        every { mockUser.uid } returns "test-user-id"
        every { mockFirebaseAuth.currentUser } returns mockUser
        
        val calculation = createTestCalculation()
        
        // Mock failed Firestore operation
        val mockDocumentReference = mockk<com.google.firebase.firestore.DocumentReference>(relaxed = true)
        val mockCollectionReference = mockk<com.google.firebase.firestore.CollectionReference>(relaxed = true)
        val mockTask = mockk<com.google.android.gms.tasks.Task<Void>>(relaxed = true)
        
        every { mockTask.isSuccessful } returns false
        every { mockTask.exception } returns Exception("Firestore error")
        every { mockDocumentReference.set(any(), any()) } returns mockTask
        every { mockCollectionReference.document(any()) } returns mockDocumentReference
        every { mockFirestore.collection(any()).document(any()).collection(any()) } returns mockCollectionReference
        
        // When uploading calculation
        val result = cloudSyncService.uploadCalculation(calculation)
        
        // Then should fail
        assertTrue(result.isFailure)
        assertNotNull(result.exceptionOrNull())
    }
    
    @Test
    fun testUploadCalculationUnauthenticated() = runTest {
        // Given unauthenticated user
        every { mockFirebaseAuth.currentUser } returns null
        
        val calculation = createTestCalculation()
        
        // When uploading calculation
        val result = cloudSyncService.uploadCalculation(calculation)
        
        // Then should fail with authentication error
        assertTrue(result.isFailure)
        val exception = result.exceptionOrNull()
        assertNotNull(exception)
        assertTrue(exception.message!!.contains("not authenticated"))
    }
    
    @Test
    fun testDownloadCalculationsSuccess() = runTest {
        // Given authenticated user
        val mockUser = mockk<com.google.firebase.auth.FirebaseUser>(relaxed = true)
        every { mockUser.uid } returns "test-user-id"
        every { mockFirebaseAuth.currentUser } returns mockUser
        
        // Mock successful Firestore query
        val mockQuerySnapshot = mockk<com.google.firebase.firestore.QuerySnapshot>(relaxed = true)
        val mockDocumentSnapshot = mockk<com.google.firebase.firestore.QueryDocumentSnapshot>(relaxed = true)
        val mockTask = mockk<com.google.android.gms.tasks.Task<com.google.firebase.firestore.QuerySnapshot>>(relaxed = true)
        val mockQuery = mockk<com.google.firebase.firestore.Query>(relaxed = true)
        val mockCollectionReference = mockk<com.google.firebase.firestore.CollectionReference>(relaxed = true)
        
        // Mock cloud calculation data
        val cloudCalculation = CloudSyncService.CloudCalculation(
            id = "test-id",
            name = "Test Calculation",
            calculationType = "CALCULATE_IRR",
            createdDate = LocalDateTime.now().toString(),
            modifiedDate = LocalDateTime.now().toString(),
            projectId = null,
            initialInvestment = 100000.0,
            outcomeAmount = 150000.0,
            timeInMonths = 24.0,
            irr = null,
            unitPrice = null,
            successRate = null,
            outcomePerUnit = null,
            investorShare = null,
            feePercentage = null,
            calculatedResult = 22.47,
            followOnInvestments = null,
            growthPoints = null,
            notes = "Test calculation",
            tags = null,
            encryptedData = null
        )
        
        every { mockTask.isSuccessful } returns true
        every { mockTask.result } returns mockQuerySnapshot
        every { mockQuerySnapshot.documents } returns listOf(mockDocumentSnapshot)
        every { mockDocumentSnapshot.toObject(CloudSyncService.CloudCalculation::class.java) } returns cloudCalculation
        every { mockQuery.get() } returns mockTask
        every { mockCollectionReference.orderBy(any<String>(), any()) } returns mockQuery
        every { mockFirestore.collection(any()).document(any()).collection(any()) } returns mockCollectionReference
        
        // When downloading calculations
        val calculations = cloudSyncService.downloadCalculations()
        
        // Then should return calculations
        assertEquals(1, calculations.size)
        assertEquals("Test Calculation", calculations[0].name)
        assertEquals(CalculationMode.CALCULATE_IRR, calculations[0].calculationType)
    }
    
    @Test
    fun testConflictResolutionUseLocal() = runTest {
        // Given a sync conflict
        val localCalc = createTestCalculation(name = "Local Version")
        val remoteCalc = createTestCalculation(name = "Remote Version")
        val conflict = CloudSyncService.SyncConflict(
            localRecord = localCalc,
            remoteRecord = remoteCalc,
            conflictType = CloudSyncService.SyncConflict.ConflictType.MODIFICATION_DATE
        )
        
        // Mock successful upload
        val mockUser = mockk<com.google.firebase.auth.FirebaseUser>(relaxed = true)
        every { mockUser.uid } returns "test-user-id"
        every { mockFirebaseAuth.currentUser } returns mockUser
        
        val mockDocumentReference = mockk<com.google.firebase.firestore.DocumentReference>(relaxed = true)
        val mockCollectionReference = mockk<com.google.firebase.firestore.CollectionReference>(relaxed = true)
        val mockTask = mockk<com.google.android.gms.tasks.Task<Void>>(relaxed = true)
        
        every { mockTask.isSuccessful } returns true
        every { mockDocumentReference.set(any(), any()) } returns mockTask
        every { mockCollectionReference.document(any()) } returns mockDocumentReference
        every { mockFirestore.collection(any()).document(any()).collection(any()) } returns mockCollectionReference
        
        // When resolving conflict with USE_LOCAL
        val result = cloudSyncService.resolveConflict(conflict, CloudSyncService.ConflictResolution.USE_LOCAL)
        
        // Then should upload local version
        assertTrue(result.isSuccess)
        verify { mockDocumentReference.set(any(), any()) }
    }
    
    @Test
    fun testConflictResolutionUseRemote() = runTest {
        // Given a sync conflict
        val localCalc = createTestCalculation(name = "Local Version")
        val remoteCalc = createTestCalculation(name = "Remote Version")
        val conflict = CloudSyncService.SyncConflict(
            localRecord = localCalc,
            remoteRecord = remoteCalc,
            conflictType = CloudSyncService.SyncConflict.ConflictType.MODIFICATION_DATE
        )
        
        // Mock successful local save
        val mockCalculationRepository = mockk<com.irrgenius.android.data.repository.CalculationRepository>(relaxed = true)
        every { mockRepositoryFactory.createCalculationRepository() } returns mockCalculationRepository
        coEvery { mockCalculationRepository.insertCalculation(any()) } returns Unit
        
        // When resolving conflict with USE_REMOTE
        val result = cloudSyncService.resolveConflict(conflict, CloudSyncService.ConflictResolution.USE_REMOTE)
        
        // Then should save remote version locally
        assertTrue(result.isSuccess)
        coVerify { mockCalculationRepository.insertCalculation(remoteCalc) }
    }
    
    @Test
    fun testDataEncryption() {
        // Given a calculation with sensitive data
        val calculation = createTestCalculation()
        
        // When converting to cloud format (which includes encryption)
        val cloudCalculation = cloudSyncService.convertToCloudFormat(calculation)
        
        // Then should have encrypted data
        assertNotNull(cloudCalculation.encryptedData)
        assertTrue(cloudCalculation.encryptedData!!.isNotEmpty())
        
        // And sensitive fields should still be present for compatibility
        assertEquals(calculation.initialInvestment, cloudCalculation.initialInvestment)
        assertEquals(calculation.outcomeAmount, cloudCalculation.outcomeAmount)
        assertEquals(calculation.calculatedResult, cloudCalculation.calculatedResult)
    }
    
    @Test
    fun testRetryMechanism() = runTest {
        // Given a retryable operation
        var attemptCount = 0
        val operation: suspend () -> Result<Unit> = {
            attemptCount++
            if (attemptCount < 3) {
                Result.failure(java.net.UnknownHostException("Network error"))
            } else {
                Result.success(Unit)
            }
        }
        
        // When adding to retry queue and processing
        cloudSyncService.addToRetryQueue(operation, "Test operation")
        
        // Process retry queue multiple times to simulate timer
        repeat(3) {
            cloudSyncService.processRetryQueue()
            kotlinx.coroutines.delay(100) // Small delay between attempts
        }
        
        // Then operation should eventually succeed
        assertEquals(3, attemptCount)
    }
    
    @Test
    fun testSyncProgressTracking() = runTest {
        // Given sync service with mocked dependencies
        val mockCalculationRepository = mockk<com.irrgenius.android.data.repository.CalculationRepository>(relaxed = true)
        every { mockRepositoryFactory.createCalculationRepository() } returns mockCalculationRepository
        coEvery { mockCalculationRepository.getAllCalculations() } returns emptyList()
        
        val mockUser = mockk<com.google.firebase.auth.FirebaseUser>(relaxed = true)
        every { mockUser.uid } returns "test-user-id"
        every { mockFirebaseAuth.currentUser } returns mockUser
        
        // Mock empty remote calculations
        val mockQuerySnapshot = mockk<com.google.firebase.firestore.QuerySnapshot>(relaxed = true)
        val mockTask = mockk<com.google.android.gms.tasks.Task<com.google.firebase.firestore.QuerySnapshot>>(relaxed = true)
        val mockQuery = mockk<com.google.firebase.firestore.Query>(relaxed = true)
        val mockCollectionReference = mockk<com.google.firebase.firestore.CollectionReference>(relaxed = true)
        
        every { mockTask.isSuccessful } returns true
        every { mockTask.result } returns mockQuerySnapshot
        every { mockQuerySnapshot.documents } returns emptyList()
        every { mockQuery.get() } returns mockTask
        every { mockCollectionReference.orderBy(any<String>(), any()) } returns mockQuery
        every { mockFirestore.collection(any()).document(any()).collection(any()) } returns mockCollectionReference
        
        // When syncing calculations
        val result = cloudSyncService.syncCalculations()
        
        // Then progress should be tracked
        assertTrue(result.isSuccess)
        assertEquals(1.0, cloudSyncService.syncProgress.value)
        assertTrue(cloudSyncService.syncStatus.value is CloudSyncService.SyncStatus.Success)
    }
    
    private fun createTestCalculation(
        name: String = "Test Calculation",
        projectId: String? = null
    ): SavedCalculation {
        return SavedCalculation.createValidated(
            name = name,
            calculationType = CalculationMode.CALCULATE_IRR,
            projectId = projectId,
            initialInvestment = 100000.0,
            outcomeAmount = 150000.0,
            timeInMonths = 24.0,
            calculatedResult = 22.47,
            notes = "Test calculation"
        )
    }
}