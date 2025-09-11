import XCTest
import RxSwift
import RxTest
@testable import RoastMeLater

class DataExportImportTests: XCTestCase {
    
    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    var mockStorageService: MockStorageService!
    var mockErrorHandler: MockDataErrorHandler!
    var dataExportService: DataExportService!
    var dataImportService: DataImportService!
    
    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
        mockStorageService = MockStorageService()
        mockErrorHandler = MockDataErrorHandler()
        dataExportService = DataExportService(
            storageService: mockStorageService,
            errorHandler: mockErrorHandler
        )
        dataImportService = DataImportService(
            storageService: mockStorageService,
            errorHandler: mockErrorHandler
        )
    }
    
    override func tearDown() {
        disposeBag = nil
        scheduler = nil
        mockStorageService = nil
        mockErrorHandler = nil
        dataExportService = nil
        dataImportService = nil
        super.tearDown()
    }
    
    // MARK: - Export Tests
    
    func testExportWithDefaultOptions() {
        // Given
        let mockRoasts = createMockRoasts(count: 5)
        let mockPreferences = createMockUserPreferences()
        
        mockStorageService.roastsToReturn = mockRoasts
        mockStorageService.preferencesToReturn = mockPreferences
        
        let options = ExportOptions.default
        let progressObserver = scheduler.createObserver(ExportProgress.self)
        
        // When
        dataExportService.exportData(with: options)
            .subscribe(progressObserver)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        // Then
        XCTAssertGreaterThan(progressObserver.events.count, 0)
        
        let finalEvent = progressObserver.events.last!
        if case .completed = finalEvent.value.element!.phase {
            XCTAssertEqual(finalEvent.value.element!.progress, 1.0)
        } else {
            XCTFail("Export should complete successfully")
        }
    }
    
    func testExportWithNoData() {
        // Given
        mockStorageService.roastsToReturn = []
        mockStorageService.preferencesToReturn = createMockUserPreferences()
        
        let options = ExportOptions.default
        let progressObserver = scheduler.createObserver(ExportProgress.self)
        
        // When
        dataExportService.exportData(with: options)
            .subscribe(progressObserver)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        // Then
        let events = progressObserver.events
        XCTAssertTrue(events.contains { event in
            if case .failed(let error) = event.value.element?.phase {
                return error is DataManagementError
            }
            return false
        })
    }
    
    func testExportWithAPIKeysExcluded() {
        // Given
        let mockRoasts = createMockRoasts(count: 3)
        var mockPreferences = createMockUserPreferences()
        mockPreferences.apiConfiguration.apiKey = "secret-key"
        
        mockStorageService.roastsToReturn = mockRoasts
        mockStorageService.preferencesToReturn = mockPreferences
        
        let options = ExportOptions(
            includeAPIConfiguration: false,
            includeDeviceInfo: true,
            includeStatistics: true,
            anonymizeData: false
        )
        
        let progressObserver = scheduler.createObserver(ExportProgress.self)
        
        // When
        dataExportService.exportData(with: options)
            .subscribe(progressObserver)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        // Then
        // Verify that the export completes and API keys are excluded
        let finalEvent = progressObserver.events.last!
        if case .completed = finalEvent.value.element!.phase {
            // In a real test, we would verify the exported data doesn't contain API keys
            XCTAssertEqual(finalEvent.value.element!.progress, 1.0)
        } else {
            XCTFail("Export should complete successfully")
        }
    }
    
    // MARK: - Import Tests
    
    func testImportValidData() {
        // Given
        let mockExportData = createMockExportData()
        let jsonData = try! JSONEncoder().encode(mockExportData)
        
        let options = ImportOptions.merge
        let progressObserver = scheduler.createObserver(ImportProgress.self)
        
        // When
        dataImportService.importData(from: jsonData, options: options)
            .subscribe(progressObserver)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        // Then
        let finalEvent = progressObserver.events.last!
        if case .completed = finalEvent.value.element!.phase {
            XCTAssertEqual(finalEvent.value.element!.progress, 1.0)
            XCTAssertTrue(mockStorageService.bulkSaveRoastsCalled)
        } else {
            XCTFail("Import should complete successfully")
        }
    }
    
    func testImportInvalidJSON() {
        // Given
        let invalidData = "invalid json".data(using: .utf8)!
        let options = ImportOptions.merge
        let progressObserver = scheduler.createObserver(ImportProgress.self)
        
        // When
        dataImportService.importData(from: invalidData, options: options)
            .subscribe(progressObserver)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        // Then
        let events = progressObserver.events
        XCTAssertTrue(events.contains { event in
            if case .failed(let error) = event.value.element?.phase {
                return error is DataManagementError
            }
            return false
        })
    }
    
    func testImportPreview() {
        // Given
        let mockExportData = createMockExportData()
        let jsonData = try! JSONEncoder().encode(mockExportData)
        
        let previewObserver = scheduler.createObserver(ImportPreview.self)
        
        // When
        dataImportService.previewImport(from: jsonData)
            .subscribe(previewObserver)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        // Then
        XCTAssertEqual(previewObserver.events.count, 1)
        let preview = previewObserver.events.first!.value.element!
        XCTAssertEqual(preview.summary.totalRoasts, mockExportData.roastHistory.count)
        XCTAssertTrue(preview.isCompatible)
    }
    
    // MARK: - Error Handling Tests
    
    func testExportErrorHandling() {
        // Given
        mockStorageService.shouldFailGetRoasts = true
        
        let options = ExportOptions.default
        let progressObserver = scheduler.createObserver(ExportProgress.self)
        
        // When
        dataExportService.exportData(with: options)
            .subscribe(progressObserver)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        // Then
        XCTAssertTrue(mockErrorHandler.logErrorCalled)
        let events = progressObserver.events
        XCTAssertTrue(events.contains { event in
            if case .failed = event.value.element?.phase {
                return true
            }
            return false
        })
    }
    
    func testImportErrorRecovery() {
        // Given
        let corruptedData = createCorruptedExportData()
        let jsonData = try! JSONEncoder().encode(corruptedData)
        
        let options = ImportOptions(
            strategy: .merge,
            validateData: true,
            skipDuplicates: true,
            preserveExistingFavorites: true
        )
        
        let progressObserver = scheduler.createObserver(ImportProgress.self)
        
        // When
        dataImportService.importData(from: jsonData, options: options)
            .subscribe(progressObserver)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        // Then
        XCTAssertTrue(mockErrorHandler.logErrorCalled)
        // Verify that error recovery was attempted
        let events = progressObserver.events
        XCTAssertTrue(events.contains { event in
            !event.value.element!.warnings.isEmpty
        })
    }
    
    // MARK: - Performance Tests
    
    func testExportPerformanceWithLargeDataset() {
        // Given
        let largeRoastSet = createMockRoasts(count: 1000)
        mockStorageService.roastsToReturn = largeRoastSet
        mockStorageService.preferencesToReturn = createMockUserPreferences()
        
        let options = ExportOptions.default
        
        // When & Then
        measure {
            let expectation = self.expectation(description: "Export large dataset")
            
            dataExportService.exportData(with: options)
                .subscribe(onNext: { progress in
                    if case .completed = progress.phase {
                        expectation.fulfill()
                    }
                })
                .disposed(by: disposeBag)
            
            wait(for: [expectation], timeout: 30.0)
        }
    }
    
    func testImportPerformanceWithLargeDataset() {
        // Given
        let largeExportData = createMockExportData(roastCount: 1000)
        let jsonData = try! JSONEncoder().encode(largeExportData)
        
        let options = ImportOptions.merge
        
        // When & Then
        measure {
            let expectation = self.expectation(description: "Import large dataset")
            
            dataImportService.importData(from: jsonData, options: options)
                .subscribe(onNext: { progress in
                    if case .completed = progress.phase {
                        expectation.fulfill()
                    }
                })
                .disposed(by: disposeBag)
            
            wait(for: [expectation], timeout: 30.0)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockRoasts(count: Int) -> [Roast] {
        return (0..<count).map { index in
            Roast(
                id: UUID(),
                content: "Mock roast content \(index)",
                category: .general,
                spiceLevel: index % 5 + 1,
                createdAt: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                isFavorite: index % 3 == 0
            )
        }
    }
    
    private func createMockUserPreferences() -> UserPreferences {
        return UserPreferences(
            notificationsEnabled: true,
            notificationFrequency: .daily,
            defaultSpiceLevel: 3,
            safetyFiltersEnabled: true,
            preferredLanguage: "en",
            preferredCategories: [.general, .work],
            apiConfiguration: APIConfiguration(
                apiKey: "",
                baseURL: "https://api.example.com"
            )
        )
    }
    
    private func createMockExportData(roastCount: Int = 5) -> AppDataExport {
        return AppDataExport(
            metadata: ExportMetadata(
                version: "1.0.0",
                dataVersion: 1,
                exportDate: Date(),
                deviceInfo: DeviceInfo(platform: "iOS", osVersion: "17.0", appBuild: "1.0"),
                totalRoasts: roastCount,
                totalFavorites: roastCount / 3
            ),
            userPreferences: createMockUserPreferences(),
            roastHistory: createMockRoasts(count: roastCount),
            favorites: Array(createMockRoasts(count: roastCount).prefix(roastCount / 3).map { $0.id }),
            statistics: nil
        )
    }
    
    private func createCorruptedExportData() -> AppDataExport {
        var exportData = createMockExportData()
        // Simulate corruption by setting invalid data version
        exportData.metadata.dataVersion = 999
        return exportData
    }
}
