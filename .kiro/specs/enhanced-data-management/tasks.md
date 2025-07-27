# Implementation Plan

- [x] 1. Set up data persistence foundation
  - Create Core Data model and Room database schemas for saved calculations and projects
  - Implement repository pattern interfaces for data access abstraction
  - Write unit tests for basic CRUD operations on calculations and projects
  - _Requirements: 1.1, 1.2, 6.1, 6.2_

- [x] 2. Implement core data models and validation
  - [x] 2.1 Create enhanced SavedCalculation data model
    - Write SavedCalculation struct/class with all calculation types support
    - Implement Codable/Serializable protocols for data persistence
    - Add validation methods for calculation data integrity
    - _Requirements: 1.1, 1.4_

  - [x] 2.2 Create Project data model and relationships
    - Write Project model with calculation relationships
    - Implement project-calculation association logic
    - Add project validation and naming constraints
    - _Requirements: 6.1, 6.2, 6.4_

  - [x] 2.3 Implement FollowOnInvestment persistence model
    - Extend existing FollowOnInvestment for database storage
    - Create relationship mapping between calculations and follow-on investments
    - Write serialization logic for complex investment data
    - _Requirements: 1.1, 1.2_

- [x] 3. Build data repository layer
  - [x] 3.1 Implement iOS Core Data repository
    - Create CoreDataCalculationRepository with async/await methods
    - Implement saveCalculation, loadCalculations, deleteCalculation methods
    - Add search functionality with NSPredicate queries
    - Write error handling for Core Data operations
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

  - [x] 3.2 Implement Android Room repository
    - Create CalculationDao with suspend functions for database operations
    - Implement ProjectDao for project management operations
    - Add database migration strategies for schema updates
    - Write repository implementation with proper error handling
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

  - [x] 3.3 Create repository abstraction layer
    - Define protocol/interface for cross-platform repository consistency
    - Implement dependency injection for repository instances
    - Add repository factory pattern for testing and production environments
    - _Requirements: 1.1, 1.2_

- [x] 4. Implement file import functionality
  - [x] 4.1 Create CSV import service
    - Write CSV parser with configurable delimiters and headers
    - Implement data validation and type conversion for financial data
    - Add column mapping interface for user-defined field assignments
    - Create preview functionality before final import
    - _Requirements: 3.1, 3.2, 3.4, 3.5_

  - [x] 4.2 Create Excel import service
    - Implement Excel file reader supporting .xlsx and .xls formats
    - Add sheet selection and range specification capabilities
    - Write data extraction logic with proper error handling
    - Implement same validation and mapping as CSV import
    - _Requirements: 3.1, 3.2, 3.4, 3.5_

  - [x] 4.3 Build import validation and mapping UI
    - Create file picker interface for import file selection
    - Implement data preview table with column mapping controls
    - Add validation error display with specific row/column feedback
    - Write import confirmation dialog with data summary
    - _Requirements: 3.2, 3.4, 3.5, 3.6_

- [x] 5. Implement file export functionality
  - [x] 5.1 Create PDF export service
    - Write PDF generation logic with calculation details and charts
    - Implement professional formatting with company branding options
    - Add chart rendering to PDF with proper scaling
    - Create batch export functionality for multiple calculations
    - _Requirements: 4.1, 4.2, 4.4_

  - [x] 5.2 Create CSV/Excel export service
    - Implement structured data export with all calculation parameters
    - Write export format that can be re-imported into the app
    - Add custom field selection for export customization
    - Create export templates for different use cases
    - _Requirements: 4.1, 4.3, 4.4_

  - [x] 5.3 Integrate native sharing capabilities
    - Implement iOS share sheet integration for export files
    - Add Android sharing intent for file distribution
    - Write temporary file management for export operations
    - Add export progress indicators for large datasets
    - _Requirements: 4.4, 4.5_

- [x] 6. Build enhanced UI navigation structure
  - [x] 6.1 Create tabbed navigation system
    - Implement TabView (iOS) and BottomNavigationView (Android) with four main tabs
    - Add tab icons and labels for Calculator, Saved, Projects, Settings
    - Write navigation state management to preserve user context
    - Implement deep linking support for direct navigation to saved calculations
    - _Requirements: 2.1, 2.2_

  - [x] 6.2 Implement saved calculations list view
    - Create list interface displaying saved calculations with key metrics
    - Add search functionality with real-time filtering
    - Implement swipe actions for delete and export operations
    - Write pull-to-refresh functionality for data synchronization
    - _Requirements: 1.2, 2.3, 6.3_

  - [x] 6.3 Build project management interface
    - Create project creation and editing forms
    - Implement project list view with calculation counts
    - Add project filtering and organization capabilities
    - Write project deletion with calculation handling options
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 7. Implement Portfolio Unit Investment calculation mode
  - [x] 7.1 Add Portfolio Unit Investment enum and data model
    - Add new CalculationMode.portfolioUnitInvestment enum case
    - Extend SavedCalculation model to support portfolio unit investment parameters
    - Add validation for portfolio unit investment specific constraints
    - _Requirements: 1.1, 1.4_

  - [x] 7.2 Implement portfolio unit investment calculation logic
    - Create calculation methods for unit-based investments with success rates
    - Implement follow-on batch support with different unit prices and timing
    - Add blended IRR calculation for multiple investment batches
    - Write growth point generation for portfolio unit investments
    - _Requirements: 1.1, 1.2_

  - [x] 7.3 Build portfolio unit investment UI components
    - Create input form for portfolio unit investment parameters
    - Add batch management interface for follow-on investments
    - Implement results display with unit-based metrics
    - Write validation and error handling for portfolio unit inputs
    - _Requirements: 2.1, 2.2_

- [x] 8. Enhance calculation workflow with persistence
  - [x] 8.1 Add auto-save functionality to calculations
    - Implement automatic saving after successful calculations
    - Add save dialog with naming and project assignment options
    - Write unsaved changes detection and warning system
    - Create draft saving for incomplete calculations
    - _Requirements: 1.1, 2.2_

  - [x] 8.2 Implement calculation loading and editing
    - Add "Load Calculation" functionality to populate form fields
    - Write calculation duplication feature for scenario analysis
    - Implement calculation history tracking with version management
    - Create calculation comparison interface for side-by-side analysis
    - _Requirements: 1.3, 2.2_

  - [x] 8.3 Add progress indicators and loading states
    - Implement loading spinners for calculation operations
    - Add progress bars for file import/export operations
    - Write timeout handling for long-running operations
    - Create user feedback for background sync operations
    - _Requirements: 2.4, 2.5_

- [x] 9. Implement cloud synchronization
  - [x] 9.1 Create iOS CloudKit integration
    - Set up CloudKit container and record types for calculations and projects
    - Implement upload/download logic with conflict resolution
    - Add sync status indicators and manual sync triggers
    - Write offline-first sync with automatic retry mechanisms
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

  - [x] 9.2 Create Android cloud sync service
    - Implement Google Drive or Firebase integration for data backup
    - Write cross-platform data format for iOS/Android compatibility
    - Add encryption for sensitive financial data in cloud storage
    - Create sync conflict resolution with user choice options
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

  - [x] 9.3 Build sync settings and management UI
    - Create sync enable/disable toggle in settings
    - Implement sync status display with last sync timestamp
    - Add manual sync trigger button with progress feedback
    - Write sync conflict resolution interface for user decisions
    - _Requirements: 5.1, 5.5_

- [x] 10. Add comprehensive error handling and validation
  - [x] 10.1 Implement data validation framework
    - Write validation rules for all calculation input fields
    - Add real-time validation feedback in form interfaces
    - Implement server-side validation for imported data
    - Create validation error aggregation and display system
    - _Requirements: 1.5, 3.5, 4.5_

  - [x] 10.2 Create error recovery and retry mechanisms
    - Implement automatic retry logic for network operations
    - Add manual retry buttons for failed operations
    - Write error logging and crash reporting integration
    - Create graceful degradation for offline scenarios
    - _Requirements: 4.5, 5.4_

  - [x] 10.3 Build user-friendly error messaging
    - Create contextual error messages with actionable suggestions
    - Implement error categorization with appropriate icons and colors
    - Add help links and documentation references in error dialogs
    - Write error reporting functionality for user feedback
    - _Requirements: 2.4, 3.5, 4.5_

- [x] 11. Write comprehensive test suite
  - [x] 11.1 Create unit tests for data layer
    - Write tests for repository implementations with mock databases
    - Add tests for data model validation and serialization
    - Implement tests for import/export service logic
    - Create tests for sync service with mocked cloud providers
    - _Requirements: 1.1, 1.2, 3.1, 5.1_

  - [x] 11.2 Write integration tests for workflows
    - Create end-to-end tests for save/load/export cycles
    - Add tests for file import with various formats and edge cases
    - Implement tests for sync scenarios including conflicts
    - Write tests for error handling and recovery scenarios
    - _Requirements: 1.1, 3.1, 4.1, 5.1_

  - [x] 11.3 Add UI automation tests
    - Create tests for navigation flows between tabs and screens
    - Add tests for form validation and user input scenarios
    - Implement tests for import/export user workflows
    - Write tests for error state handling in UI components
    - _Requirements: 2.1, 2.2, 3.2, 4.2_

- [x] 12. Implement settings and preferences
  - [x] 12.1 Create app settings infrastructure
    - Implement settings storage using UserDefaults (iOS) and SharedPreferences (Android)
    - Add settings categories for data, sync, import/export, and display preferences
    - Write settings validation and migration logic for app updates
    - Create settings backup and restore functionality
    - _Requirements: 5.1, 5.5_

  - [x] 12.2 Build settings UI interface
    - Create settings screen with organized sections and clear labels
    - Add toggle switches, selection lists, and input fields for preferences
    - Implement settings search functionality for large preference lists
    - Write settings help and documentation integration
    - _Requirements: 5.1, 5.5_

- [x] 13. Finalize and integrate all components
  - [x] 13.1 Integration testing and bug fixes
    - Test all features together in complete app workflows
    - Fix integration issues between data persistence and UI components
    - Resolve performance issues with large datasets and file operations
    - Optimize memory usage and battery consumption for mobile devices
    - _Requirements: All requirements_

  - [x] 13.2 Polish UI and user experience
    - Implement consistent styling and theming across all new screens
    - Add animations and transitions for smooth user interactions
    - Write accessibility support for screen readers and assistive technologies
    - Create onboarding flow for new features and import capabilities
    - _Requirements: 2.1, 2.2, 2.3_

  - [x] 13.3 Performance optimization and final testing
    - Optimize database queries and indexing for fast search and filtering
    - Implement lazy loading and pagination for large calculation lists
    - Add performance monitoring and crash reporting integration
    - Conduct final testing on various devices and OS versions
    - _Requirements: All requirements_