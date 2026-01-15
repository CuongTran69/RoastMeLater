import Foundation
import RxSwift
import RxCocoa
import CryptoKit

// MARK: - Import Options

struct ImportOptions {
    let strategy: ImportStrategy
    let validateData: Bool
    let skipDuplicates: Bool
    let preserveExistingFavorites: Bool
    let allowPartialImport: Bool
    let maxErrorsAllowed: Int

    static let merge = ImportOptions(
        strategy: .merge,
        validateData: true,
        skipDuplicates: true,
        preserveExistingFavorites: true,
        allowPartialImport: true,
        maxErrorsAllowed: 10
    )

    static let replace = ImportOptions(
        strategy: .replace,
        validateData: true,
        skipDuplicates: false,
        preserveExistingFavorites: false,
        allowPartialImport: true,
        maxErrorsAllowed: 10
    )
}

enum ImportStrategy {
    case merge      // Add new data to existing data
    case replace    // Replace all existing data
}

// MARK: - Import Progress

struct ImportProgress {
    let phase: ImportPhase
    let progress: Double // 0.0 to 1.0
    let message: String
    let itemsProcessed: Int
    let totalItems: Int
    let warnings: [ImportWarning]
    let errors: [ImportError]
    let successCount: Int
    let errorCount: Int
}

struct ImportError {
    let itemId: String
    let message: String
    let error: Error
}

enum ImportPhase {
    case validating
    case parsing
    case processingPreferences
    case processingRoasts
    case processingFavorites
    case saving
    case completed
    case failed(Error)
}

struct ImportWarning {
    let type: WarningType
    let message: String
    let itemId: String?
}

enum WarningType {
    case duplicateRoast
    case invalidSpiceLevel
    case futureDate
    case unsupportedCategory
    case dataVersionMismatch
    case missingField
}

// MARK: - Import Preview

struct ImportPreview {
    let metadata: ExportMetadata
    let summary: ImportSummary
    let warnings: [ImportWarning]
    let isCompatible: Bool
}

struct ImportSummary {
    let totalRoasts: Int
    let newRoasts: Int
    let duplicateRoasts: Int
    let totalFavorites: Int
    let newFavorites: Int
    let preferencesChanges: [String]
    let categoryBreakdown: [RoastCategory: Int]
}

// MARK: - Import Errors

enum DataImportError: Error, LocalizedError {
    case invalidFileFormat
    case unsupportedDataVersion(Int)
    case corruptedData(String)
    case validationFailed([ValidationError])
    case importCancelled
    case storageError(Error)
    case incompatibleData
    case tooManyErrors(Int, [ImportError])

    var errorDescription: String? {
        switch self {
        case .invalidFileFormat:
            return "Định dạng file không hợp lệ"
        case .unsupportedDataVersion(let version):
            return "Phiên bản dữ liệu không được hỗ trợ: \(version)"
        case .corruptedData(let details):
            return "Dữ liệu bị hỏng: \(details)"
        case .validationFailed(let errors):
            return "Lỗi xác thực dữ liệu: \(errors.count) lỗi"
        case .importCancelled:
            return "Đã hủy nhập dữ liệu"
        case .storageError(let error):
            return "Lỗi lưu trữ: \(error.localizedDescription)"
        case .incompatibleData:
            return "Dữ liệu không tương thích với phiên bản hiện tại"
        case .tooManyErrors(let count, _):
            return "Quá nhiều lỗi khi import (\(count) lỗi). Đã dừng quá trình import."
        }
    }
}

struct ValidationError: Equatable {
    let field: String
    let value: Any?
    let reason: String

    static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
        return lhs.field == rhs.field && lhs.reason == rhs.reason
    }
}

// MARK: - Data Import Service

protocol DataImportServiceProtocol {
    func previewImport(from data: Data) -> Observable<ImportPreview>
    func importData(from data: Data, options: ImportOptions) -> Observable<ImportProgress>
    func validateImportData(_ data: Data) -> Observable<[ValidationError]>
}

class DataImportService: DataImportServiceProtocol {
    private let storageService: StorageServiceProtocol
    private let errorHandler: DataErrorHandlerProtocol
    private let migrationService: DataMigrationServiceProtocol
    private let disposeBag = DisposeBag()

    // Supported data versions
    private let supportedDataVersions = [1, 2, 3, 4]
    private let currentDataVersion = 1

    init(storageService: StorageServiceProtocol = StorageService.shared,
         errorHandler: DataErrorHandlerProtocol = DataErrorHandler(),
         migrationService: DataMigrationServiceProtocol = DataMigrationService()) {
        self.storageService = storageService
        self.errorHandler = errorHandler
        self.migrationService = migrationService
    }
    
    func previewImport(from data: Data) -> Observable<ImportPreview> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(DataImportError.importCancelled)
                return Disposables.create()
            }
            
            do {
                let importData = try self.parseImportData(data)
                let existingRoasts = self.storageService.getRoastHistory()
                let existingFavorites = existingRoasts.filter { $0.isFavorite }
                
                let preview = self.createImportPreview(
                    importData: importData,
                    existingRoasts: existingRoasts,
                    existingFavorites: existingFavorites
                )
                
                observer.onNext(preview)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    func importData(from data: Data, options: ImportOptions = .merge) -> Observable<ImportProgress> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(DataImportError.importCancelled)
                return Disposables.create()
            }
            
            self.performImport(data: data, options: options, observer: observer)
            
            return Disposables.create()
        }
        .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func validateImportData(_ data: Data) -> Observable<[ValidationError]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext([])
                observer.onCompleted()
                return Disposables.create()
            }
            
            do {
                let importData = try self.parseImportData(data)
                let errors = self.validateAppDataExport(importData)
                observer.onNext(errors)
                observer.onCompleted()
            } catch {
                observer.onNext([ValidationError(field: "file", value: nil, reason: error.localizedDescription)])
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - Private Methods
    
    private func parseImportData(_ data: Data) throws -> AppDataExport {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            var importData = try decoder.decode(AppDataExport.self, from: data)

            // Verify checksum if present
            if let checksum = importData.checksum {
                try verifyChecksum(data: data, expectedChecksum: checksum, importData: importData)
            }

            // Auto-migrate if needed
            if importData.metadata.dataVersion < currentDataVersion {
                importData = try migrationService.migrateData(
                    from: importData.metadata.dataVersion,
                    to: currentDataVersion,
                    data: importData
                )
            }

            return importData
        } catch {
            if error is DecodingError {
                throw DataManagementError.importInvalidFileFormat(details: error.localizedDescription)
            }
            throw DataManagementError.importCorruptedData(field: "unknown", reason: error.localizedDescription)
        }
    }

    private func verifyChecksum(data: Data, expectedChecksum: String, importData: AppDataExport) throws {
        // Re-encode the data without checksum to verify
        var dataWithoutChecksum = importData
        let mirror = Mirror(reflecting: dataWithoutChecksum)

        // Create a copy without checksum by re-encoding with nil checksum
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let exportDataWithoutChecksum = AppDataExport(
            metadata: importData.metadata,
            userPreferences: importData.userPreferences,
            roastHistory: importData.roastHistory,
            favorites: importData.favorites,
            statistics: importData.statistics,
            checksum: nil
        )

        guard let reEncodedData = try? encoder.encode(exportDataWithoutChecksum) else {
            throw DataImportError.corruptedData("Không thể xác minh checksum")
        }

        let calculatedChecksum = calculateChecksum(data: reEncodedData)

        if calculatedChecksum != expectedChecksum {
            throw DataImportError.corruptedData("Checksum không khớp. Dữ liệu có thể đã bị thay đổi.")
        }
    }

    private func calculateChecksum(data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func createImportPreview(
        importData: AppDataExport,
        existingRoasts: [Roast],
        existingFavorites: [Roast]
    ) -> ImportPreview {
        let existingRoastIds = Set(existingRoasts.map { $0.id })
        let newRoasts = importData.roastHistory.filter { !existingRoastIds.contains($0.id) }
        let duplicateRoasts = importData.roastHistory.filter { existingRoastIds.contains($0.id) }
        
        let existingFavoriteIds = Set(existingFavorites.map { $0.id })
        let newFavorites = importData.favorites.filter { !existingFavoriteIds.contains($0) }
        
        let categoryBreakdown = Dictionary(grouping: newRoasts, by: { $0.category })
            .mapValues { $0.count }
        
        let preferencesChanges = comparePreferences(
            current: storageService.getUserPreferences(),
            imported: importData.userPreferences
        )
        
        let warnings = generateImportWarnings(importData: importData, duplicateRoasts: duplicateRoasts)
        
        let summary = ImportSummary(
            totalRoasts: importData.roastHistory.count,
            newRoasts: newRoasts.count,
            duplicateRoasts: duplicateRoasts.count,
            totalFavorites: importData.favorites.count,
            newFavorites: newFavorites.count,
            preferencesChanges: preferencesChanges,
            categoryBreakdown: categoryBreakdown
        )
        
        let isCompatible = supportedDataVersions.contains(importData.metadata.dataVersion)
        
        return ImportPreview(
            metadata: importData.metadata,
            summary: summary,
            warnings: warnings,
            isCompatible: isCompatible
        )
    }
    
    private func comparePreferences(current: UserPreferences, imported: UserPreferences) -> [String] {
        var changes: [String] = []
        
        if current.preferredLanguage != imported.preferredLanguage {
            changes.append("Ngôn ngữ: \(current.preferredLanguage) → \(imported.preferredLanguage)")
        }
        
        if current.defaultSpiceLevel != imported.defaultSpiceLevel {
            changes.append("Mức độ cay mặc định: \(current.defaultSpiceLevel) → \(imported.defaultSpiceLevel)")
        }
        
        if current.notificationsEnabled != imported.notificationsEnabled {
            changes.append("Thông báo: \(current.notificationsEnabled ? "Bật" : "Tắt") → \(imported.notificationsEnabled ? "Bật" : "Tắt")")
        }
        
        if current.safetyFiltersEnabled != imported.safetyFiltersEnabled {
            changes.append("Bộ lọc an toàn: \(current.safetyFiltersEnabled ? "Bật" : "Tắt") → \(imported.safetyFiltersEnabled ? "Bật" : "Tắt")")
        }
        
        return changes
    }
    
    private func generateImportWarnings(importData: AppDataExport, duplicateRoasts: [Roast]) -> [ImportWarning] {
        var warnings: [ImportWarning] = []
        
        // Data version warning
        if importData.metadata.dataVersion != currentDataVersion {
            warnings.append(ImportWarning(
                type: .dataVersionMismatch,
                message: "Phiên bản dữ liệu khác biệt (hiện tại: \(currentDataVersion), import: \(importData.metadata.dataVersion))",
                itemId: nil
            ))
        }
        
        // Duplicate roasts warning
        if !duplicateRoasts.isEmpty {
            warnings.append(ImportWarning(
                type: .duplicateRoast,
                message: "Tìm thấy \(duplicateRoasts.count) roast trùng lặp",
                itemId: nil
            ))
        }
        
        // Future dates warning
        let futureRoasts = importData.roastHistory.filter { $0.createdAt > Date() }
        if !futureRoasts.isEmpty {
            warnings.append(ImportWarning(
                type: .futureDate,
                message: "Tìm thấy \(futureRoasts.count) roast có ngày tạo trong tương lai",
                itemId: nil
            ))
        }
        
        return warnings
    }

    private func performImport(data: Data, options: ImportOptions, observer: AnyObserver<ImportProgress>) {
        do {
            // Phase 1: Validating
            observer.onNext(ImportProgress(
                phase: .validating,
                progress: 0.0,
                message: "Xác thực dữ liệu...",
                itemsProcessed: 0,
                totalItems: 0,
                warnings: [],
                errors: [],
                successCount: 0,
                errorCount: 0
            ))

            let importData = try parseImportData(data)

            // Check data version compatibility
            if !supportedDataVersions.contains(importData.metadata.dataVersion) {
                throw DataImportError.unsupportedDataVersion(importData.metadata.dataVersion)
            }

            // Validate data if requested
            if options.validateData {
                let validationErrors = validateAppDataExport(importData)
                if !validationErrors.isEmpty {
                    throw DataImportError.validationFailed(validationErrors)
                }
            }

            let totalItems = importData.roastHistory.count + importData.favorites.count + 1 // +1 for preferences

            // Phase 2: Parsing
            observer.onNext(ImportProgress(
                phase: .parsing,
                progress: 0.1,
                message: "Phân tích dữ liệu...",
                itemsProcessed: 0,
                totalItems: totalItems,
                warnings: [],
                errors: [],
                successCount: 0,
                errorCount: 0
            ))

            let existingRoasts = storageService.getRoastHistory()
            let existingRoastIds = Set(existingRoasts.map { $0.id })

            // Determine which roasts to import based on strategy and options
            let roastsToImport: [Roast]
            if options.strategy == .replace {
                roastsToImport = importData.roastHistory
            } else {
                roastsToImport = options.skipDuplicates
                    ? importData.roastHistory.filter { !existingRoastIds.contains($0.id) }
                    : importData.roastHistory
            }

            // Phase 3: Processing Preferences
            observer.onNext(ImportProgress(
                phase: .processingPreferences,
                progress: 0.2,
                message: "Xử lý cài đặt...",
                itemsProcessed: 0,
                totalItems: totalItems,
                warnings: [],
                errors: [],
                successCount: 0,
                errorCount: 0
            ))

            // Import preferences
            storageService.saveUserPreferences(importData.userPreferences)

            // Phase 4: Processing Roasts
            observer.onNext(ImportProgress(
                phase: .processingRoasts,
                progress: 0.3,
                message: "Xử lý lịch sử roast...",
                itemsProcessed: 1,
                totalItems: totalItems,
                warnings: [],
                errors: [],
                successCount: 0,
                errorCount: 0
            ))

            // Clear existing data if replace strategy
            if options.strategy == .replace {
                storageService.clearAllData()
                storageService.saveUserPreferences(importData.userPreferences)
            }

            // Import roasts with partial import support
            var processedRoasts = 0
            var successCount = 0
            var errorCount = 0
            var errors: [ImportError] = []
            var warnings: [ImportWarning] = []

            for roast in roastsToImport {
                do {
                    // Validate individual roast if needed
                    if options.validateData {
                        try validateRoast(roast)
                    }

                    storageService.saveRoast(roast)
                    successCount += 1
                } catch {
                    errorCount += 1
                    let importError = ImportError(
                        itemId: roast.id.uuidString,
                        message: "Lỗi khi import roast: \(error.localizedDescription)",
                        error: error
                    )
                    errors.append(importError)

                    // Check if we should continue or abort
                    if !options.allowPartialImport || errorCount > options.maxErrorsAllowed {
                        throw DataImportError.tooManyErrors(errorCount, errors)
                    }

                    // Add warning for this failed item
                    warnings.append(ImportWarning(
                        type: .missingField,
                        message: "Bỏ qua roast do lỗi: \(error.localizedDescription)",
                        itemId: roast.id.uuidString
                    ))
                }

                processedRoasts += 1

                // Update progress periodically
                if processedRoasts % 10 == 0 {
                    observer.onNext(ImportProgress(
                        phase: .processingRoasts,
                        progress: 0.3 + (Double(processedRoasts) / Double(roastsToImport.count)) * 0.4,
                        message: "Đã xử lý \(processedRoasts)/\(roastsToImport.count) roast (\(successCount) thành công, \(errorCount) lỗi)...",
                        itemsProcessed: processedRoasts + 1,
                        totalItems: totalItems,
                        warnings: warnings,
                        errors: errors,
                        successCount: successCount,
                        errorCount: errorCount
                    ))
                }
            }

            // Phase 5: Processing Favorites
            observer.onNext(ImportProgress(
                phase: .processingFavorites,
                progress: 0.7,
                message: "Xử lý danh sách yêu thích...",
                itemsProcessed: processedRoasts + 1,
                totalItems: totalItems,
                warnings: warnings,
                errors: errors,
                successCount: successCount,
                errorCount: errorCount
            ))

            // Update favorite status for imported roasts
            let importedRoastIds = Set(roastsToImport.map { $0.id })
            for favoriteId in importData.favorites {
                if importedRoastIds.contains(favoriteId) {
                    // The roast was imported and should be marked as favorite
                    // This is handled by the roast's isFavorite property during import
                    continue
                }

                // If preserving existing favorites and this favorite exists, keep it
                if options.preserveExistingFavorites && existingRoastIds.contains(favoriteId) {
                    storageService.toggleFavorite(roastId: favoriteId)
                }
            }

            // Phase 6: Saving
            observer.onNext(ImportProgress(
                phase: .saving,
                progress: 0.9,
                message: "Lưu dữ liệu...",
                itemsProcessed: totalItems,
                totalItems: totalItems,
                warnings: warnings,
                errors: errors,
                successCount: successCount,
                errorCount: errorCount
            ))

            // Force save and refresh
            // The individual saves above should have already persisted the data

            // Phase 7: Completed
            let finalMessage = errorCount > 0
                ? "Nhập dữ liệu hoàn tất: \(successCount) thành công, \(errorCount) lỗi"
                : "Nhập dữ liệu thành công!"

            observer.onNext(ImportProgress(
                phase: .completed,
                progress: 1.0,
                message: finalMessage,
                itemsProcessed: totalItems,
                totalItems: totalItems,
                warnings: warnings,
                errors: errors,
                successCount: successCount,
                errorCount: errorCount
            ))

            observer.onCompleted()

        } catch {
            let errorList: [ImportError]
            if case .tooManyErrors(_, let errors) = error as? DataImportError {
                errorList = errors
            } else {
                errorList = []
            }

            observer.onNext(ImportProgress(
                phase: .failed(error),
                progress: 0.0,
                message: error.localizedDescription,
                itemsProcessed: 0,
                totalItems: 0,
                warnings: [],
                errors: errorList,
                successCount: 0,
                errorCount: errorList.count
            ))
            observer.onError(error)
        }
    }

    private func validateAppDataExport(_ importData: AppDataExport) -> [ValidationError] {
        var errors: [ValidationError] = []

        // Validate metadata
        if importData.metadata.version.isEmpty {
            errors.append(ValidationError(field: "metadata.version", value: importData.metadata.version, reason: "Phiên bản app không được để trống"))
        }

        if importData.metadata.totalRoasts != importData.roastHistory.count {
            errors.append(ValidationError(field: "metadata.totalRoasts", value: importData.metadata.totalRoasts, reason: "Số lượng roast không khớp với dữ liệu thực tế"))
        }

        if importData.metadata.totalFavorites != importData.favorites.count {
            errors.append(ValidationError(field: "metadata.totalFavorites", value: importData.metadata.totalFavorites, reason: "Số lượng yêu thích không khớp với dữ liệu thực tế"))
        }

        // Validate roasts
        for (index, roast) in importData.roastHistory.enumerated() {
            if roast.content.isEmpty {
                errors.append(ValidationError(field: "roastHistory[\(index)].content", value: roast.content, reason: "Nội dung roast không được để trống"))
            }

            if roast.spiceLevel < 1 || roast.spiceLevel > 5 {
                errors.append(ValidationError(field: "roastHistory[\(index)].spiceLevel", value: roast.spiceLevel, reason: "Mức độ cay phải từ 1 đến 5"))
            }

            if roast.createdAt > Date().addingTimeInterval(86400) { // Allow 1 day future for timezone differences
                errors.append(ValidationError(field: "roastHistory[\(index)].createdAt", value: roast.createdAt, reason: "Ngày tạo không được ở tương lai"))
            }
        }

        // Validate preferences
        let validLanguages = ["vi", "en"]
        if !validLanguages.contains(importData.userPreferences.preferredLanguage) {
            errors.append(ValidationError(field: "userPreferences.preferredLanguage", value: importData.userPreferences.preferredLanguage, reason: "Ngôn ngữ không được hỗ trợ"))
        }

        if importData.userPreferences.defaultSpiceLevel < 1 || importData.userPreferences.defaultSpiceLevel > 5 {
            errors.append(ValidationError(field: "userPreferences.defaultSpiceLevel", value: importData.userPreferences.defaultSpiceLevel, reason: "Mức độ cay mặc định phải từ 1 đến 5"))
        }

        // Validate favorites reference existing roasts
        let roastIds = Set(importData.roastHistory.map { $0.id })
        for favoriteId in importData.favorites {
            if !roastIds.contains(favoriteId) {
                errors.append(ValidationError(field: "favorites", value: favoriteId, reason: "Roast yêu thích không tồn tại trong lịch sử"))
            }
        }

        return errors
    }

    private func validateRoast(_ roast: Roast) throws {
        if roast.content.isEmpty {
            throw DataImportError.validationFailed([
                ValidationError(field: "content", value: roast.content, reason: "Nội dung roast không được để trống")
            ])
        }

        if roast.spiceLevel < 1 || roast.spiceLevel > 5 {
            throw DataImportError.validationFailed([
                ValidationError(field: "spiceLevel", value: roast.spiceLevel, reason: "Mức độ cay phải từ 1 đến 5")
            ])
        }

        if roast.createdAt > Date().addingTimeInterval(86400) {
            throw DataImportError.validationFailed([
                ValidationError(field: "createdAt", value: roast.createdAt, reason: "Ngày tạo không được ở tương lai")
            ])
        }
    }
}
