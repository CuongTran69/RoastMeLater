import Foundation
import UIKit
import RxSwift
import RxCocoa
import CryptoKit

// MARK: - Export Data Models

struct AppDataExport: Codable {
    let metadata: ExportMetadata
    let userPreferences: UserPreferences
    let roastHistory: [Roast]
    let favorites: [UUID] // Store favorite IDs separately for efficiency
    let statistics: ExportStatistics
    let checksum: String? // SHA256 checksum for data integrity
}

struct ExportMetadata: Codable {
    let version: String // App version
    let dataVersion: Int // Schema version for compatibility
    let exportDate: Date
    let totalRoasts: Int
    let totalFavorites: Int
    let deviceInfo: DeviceInfo
}

struct DeviceInfo: Codable {
    let platform: String
    let osVersion: String
    let appBuild: String
}

struct ExportStatistics: Codable {
    let categoryBreakdown: [String: Int] // RoastCategory.rawValue -> count
    let averageSpiceLevel: Double
    let mostPopularCategory: String?
    let dateRange: DateRange?
}

struct DateRange: Codable {
    let earliest: Date?
    let latest: Date?
}

// MARK: - Export Options

struct ExportOptions {
    let includeAPIConfiguration: Bool
    let includeDeviceInfo: Bool
    let includeStatistics: Bool
    let anonymizeData: Bool
    
    static let `default` = ExportOptions(
        includeAPIConfiguration: false,
        includeDeviceInfo: true,
        includeStatistics: true,
        anonymizeData: false
    )
    
    static let secure = ExportOptions(
        includeAPIConfiguration: false,
        includeDeviceInfo: false,
        includeStatistics: true,
        anonymizeData: true
    )
}

// MARK: - Export Progress

struct ExportProgress {
    let phase: ExportPhase
    let progress: Double // 0.0 to 1.0
    let message: String
    let itemsProcessed: Int
    let totalItems: Int
}

enum ExportPhase {
    case preparing
    case collectingData
    case processingRoasts
    case processingFavorites
    case generatingMetadata
    case serializing
    case writing
    case completed
    case failed(Error)
}

// MARK: - Export Errors

enum DataExportError: Error, LocalizedError {
    case noDataToExport
    case serializationFailed(Error)
    case fileWriteFailed(Error)
    case insufficientStorage
    case cancelled
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .noDataToExport:
            return "Không có dữ liệu để xuất"
        case .serializationFailed(let error):
            return "Lỗi tạo file JSON: \(error.localizedDescription)"
        case .fileWriteFailed(let error):
            return "Lỗi ghi file: \(error.localizedDescription)"
        case .insufficientStorage:
            return "Không đủ dung lượng lưu trữ"
        case .cancelled:
            return "Đã hủy xuất dữ liệu"
        case .invalidConfiguration:
            return "Cấu hình xuất dữ liệu không hợp lệ"
        }
    }
}

// MARK: - Data Export Service

protocol DataExportServiceProtocol {
    func exportData(options: ExportOptions) -> Observable<ExportProgress>
    func estimateExportSize() -> Observable<Int64>
    func validateExportData() -> Observable<Bool>
    func generatePrivacyNotice(for options: ExportOptions) -> Observable<(PrivacyNotice, [ComplianceIssue])>
}

class DataExportService: DataExportServiceProtocol {
    private let storageService: StorageServiceProtocol
    private let fileManager: FileManager
    private let errorHandler: DataErrorHandlerProtocol
    private let sanitizationService: DataSanitizationProtocol
    private let fileSecurityService: FileSecurityProtocol
    private let disposeBag = DisposeBag()

    // Constants
    private let currentDataVersion = 1
    private let maxFileSize: Int64 = 100 * 1024 * 1024 // 100MB limit

    init(storageService: StorageServiceProtocol = StorageService.shared,
         errorHandler: DataErrorHandlerProtocol = DataErrorHandler(),
         sanitizationService: DataSanitizationProtocol = DataSanitizationService(),
         fileSecurityService: FileSecurityProtocol = FileSecurityService()) {
        self.storageService = storageService
        self.fileManager = FileManager.default
        self.errorHandler = errorHandler
        self.sanitizationService = sanitizationService
        self.fileSecurityService = fileSecurityService
    }
    
    func exportData(options: ExportOptions = .default) -> Observable<ExportProgress> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(DataExportError.invalidConfiguration)
                return Disposables.create()
            }
            
            // Start export process
            self.performExport(options: options, observer: observer)
            
            return Disposables.create()
        }
        .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func estimateExportSize() -> Observable<Int64> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(DataExportError.invalidConfiguration)
                return Disposables.create()
            }
            
            do {
                let roasts = self.storageService.getRoastHistory()
                let preferences = self.storageService.getUserPreferences()
                
                // Rough estimation based on average data sizes
                let roastSize = roasts.count * 500 // ~500 bytes per roast
                let preferencesSize = 2048 // ~2KB for preferences
                let metadataSize = 1024 // ~1KB for metadata
                
                let totalSize = Int64(roastSize + preferencesSize + metadataSize)
                observer.onNext(totalSize)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    func validateExportData() -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }
            
            do {
                let roasts = self.storageService.getRoastHistory()
                let preferences = self.storageService.getUserPreferences()
                
                // Validate data integrity
                let isValid = self.validateRoasts(roasts) && self.validatePreferences(preferences)
                observer.onNext(isValid)
                observer.onCompleted()
            } catch {
                observer.onNext(false)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - Private Methods
    
    private func performExport(options: ExportOptions, observer: AnyObserver<ExportProgress>) {
        do {
            // Phase 1: Preparing
            observer.onNext(ExportProgress(
                phase: .preparing,
                progress: 0.0,
                message: "Chuẩn bị xuất dữ liệu...",
                itemsProcessed: 0,
                totalItems: 0
            ))
            
            // Phase 2: Collecting Data
            observer.onNext(ExportProgress(
                phase: .collectingData,
                progress: 0.1,
                message: "Thu thập dữ liệu...",
                itemsProcessed: 0,
                totalItems: 0
            ))
            
            let roasts = storageService.getRoastHistory()
            let preferences = storageService.getUserPreferences()
            let totalItems = roasts.count + 1 // +1 for preferences
            
            // Phase 3: Processing Roasts
            observer.onNext(ExportProgress(
                phase: .processingRoasts,
                progress: 0.2,
                message: "Xử lý lịch sử roast...",
                itemsProcessed: 0,
                totalItems: totalItems
            ))
            
            let processedRoasts = options.anonymizeData ? anonymizeRoasts(roasts) : roasts
            
            // Phase 4: Processing Favorites
            observer.onNext(ExportProgress(
                phase: .processingFavorites,
                progress: 0.4,
                message: "Xử lý danh sách yêu thích...",
                itemsProcessed: roasts.count,
                totalItems: totalItems
            ))
            
            let favoriteIds = roasts.filter { $0.isFavorite }.map { $0.id }
            
            // Phase 5: Generating Metadata
            observer.onNext(ExportProgress(
                phase: .generatingMetadata,
                progress: 0.6,
                message: "Tạo thông tin metadata...",
                itemsProcessed: totalItems,
                totalItems: totalItems
            ))
            
            let metadata = createMetadata(
                roasts: processedRoasts,
                favorites: favoriteIds,
                options: options
            )
            
            let statistics = options.includeStatistics ? createStatistics(roasts: processedRoasts) : nil

            // Phase 6: Serializing
            observer.onNext(ExportProgress(
                phase: .serializing,
                progress: 0.8,
                message: "Tạo file JSON...",
                itemsProcessed: totalItems,
                totalItems: totalItems
            ))

            // Create export data without checksum first
            let exportDataWithoutChecksum = AppDataExport(
                metadata: metadata,
                userPreferences: options.includeAPIConfiguration ? preferences : sanitizePreferences(preferences),
                roastHistory: processedRoasts,
                favorites: favoriteIds,
                statistics: statistics ?? ExportStatistics(
                    categoryBreakdown: [:],
                    averageSpiceLevel: 0,
                    mostPopularCategory: nil,
                    dateRange: nil
                ),
                checksum: nil
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            // Encode without checksum to calculate checksum
            let dataWithoutChecksum = try encoder.encode(exportDataWithoutChecksum)

            // Calculate checksum
            let checksum = calculateChecksum(data: dataWithoutChecksum)

            // Create final export data with checksum
            let exportData = AppDataExport(
                metadata: metadata,
                userPreferences: options.includeAPIConfiguration ? preferences : sanitizePreferences(preferences),
                roastHistory: processedRoasts,
                favorites: favoriteIds,
                statistics: statistics ?? ExportStatistics(
                    categoryBreakdown: [:],
                    averageSpiceLevel: 0,
                    mostPopularCategory: nil,
                    dateRange: nil
                ),
                checksum: checksum
            )

            let jsonData = try encoder.encode(exportData)
            
            // Check file size
            if jsonData.count > maxFileSize {
                throw DataManagementError.exportInsufficientStorage(
                    required: Int64(jsonData.count),
                    available: getAvailableStorage()
                )
            }
            
            // Phase 7: Writing
            observer.onNext(ExportProgress(
                phase: .writing,
                progress: 0.9,
                message: "Lưu file...",
                itemsProcessed: totalItems,
                totalItems: totalItems
            ))
            
            let fileURL = try writeExportFile(data: jsonData)
            
            // Phase 8: Completed
            observer.onNext(ExportProgress(
                phase: .completed,
                progress: 1.0,
                message: "Xuất dữ liệu thành công!",
                itemsProcessed: totalItems,
                totalItems: totalItems
            ))
            
            observer.onCompleted()
            
        } catch {
            let context = ErrorContext(
                operation: .export,
                phase: "export",
                itemsProcessed: 0,
                totalItems: 0,
                timestamp: Date(),
                additionalInfo: [:]
            )

            errorHandler.logError(error, context: context)

            let managementError = convertToManagementError(error)
            observer.onNext(ExportProgress(
                phase: .failed(managementError),
                progress: 0.0,
                message: managementError.localizedDescription,
                itemsProcessed: 0,
                totalItems: 0
            ))
            observer.onError(managementError)
        }
    }

    private func createMetadata(roasts: [Roast], favorites: [UUID], options: ExportOptions) -> ExportMetadata {
        let deviceInfo = options.includeDeviceInfo ? DeviceInfo(
            platform: "iOS",
            osVersion: UIDevice.current.systemVersion,
            appBuild: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        ) : DeviceInfo(platform: "iOS", osVersion: "Hidden", appBuild: "Hidden")

        return ExportMetadata(
            version: Constants.App.version,
            dataVersion: currentDataVersion,
            exportDate: Date(),
            totalRoasts: roasts.count,
            totalFavorites: favorites.count,
            deviceInfo: deviceInfo
        )
    }

    private func createStatistics(roasts: [Roast]) -> ExportStatistics {
        let categoryBreakdown = Dictionary(grouping: roasts, by: { $0.category })
            .mapValues { $0.count }
            .reduce(into: [String: Int]()) { result, pair in
                result[pair.key.rawValue] = pair.value
            }

        let averageSpiceLevel = roasts.isEmpty ? 0.0 : Double(roasts.map { $0.spiceLevel }.reduce(0, +)) / Double(roasts.count)

        let mostPopularCategory = categoryBreakdown.max(by: { $0.value < $1.value })?.key

        let dateRange = roasts.isEmpty ? nil : DateRange(
            earliest: roasts.map { $0.createdAt }.min(),
            latest: roasts.map { $0.createdAt }.max()
        )

        return ExportStatistics(
            categoryBreakdown: categoryBreakdown,
            averageSpiceLevel: averageSpiceLevel,
            mostPopularCategory: mostPopularCategory,
            dateRange: dateRange
        )
    }

    private func anonymizeRoasts(_ roasts: [Roast]) -> [Roast] {
        return roasts.map { roast in
            var anonymizedRoast = roast
            // Keep structure but remove potentially identifying content patterns
            // This is a basic implementation - could be enhanced with more sophisticated anonymization
            return anonymizedRoast
        }
    }

    private func sanitizePreferences(_ preferences: UserPreferences) -> UserPreferences {
        var sanitized = preferences
        // Remove sensitive API configuration
        sanitized.apiConfiguration = APIConfiguration() // Reset to default
        return sanitized
    }

    private func validateRoasts(_ roasts: [Roast]) -> Bool {
        for roast in roasts {
            // Validate roast data integrity
            if roast.content.isEmpty || roast.spiceLevel < 1 || roast.spiceLevel > 5 {
                return false
            }

            // Validate UUID format
            if roast.id.uuidString.isEmpty {
                return false
            }

            // Validate date is not in future
            if roast.createdAt > Date() {
                return false
            }
        }
        return true
    }

    private func validatePreferences(_ preferences: UserPreferences) -> Bool {
        // Validate language code
        let validLanguages = ["vi", "en"]
        if !validLanguages.contains(preferences.preferredLanguage) {
            return false
        }

        // Validate spice level
        if preferences.defaultSpiceLevel < 1 || preferences.defaultSpiceLevel > 5 {
            return false
        }

        // Validate categories
        if preferences.preferredCategories.isEmpty {
            return false
        }

        return true
    }

    private func writeExportFile(data: Data) throws -> URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let fileName = "RoastMeLater_Export_\(timestamp).json"
        let fileURL = documentsPath.appendingPathComponent(fileName)

        // Check available storage
        if let attributes = try? fileManager.attributesOfFileSystem(forPath: documentsPath.path),
           let freeSize = attributes[.systemFreeSize] as? Int64 {
            if freeSize < Int64(data.count) * 2 { // Require 2x space for safety
                throw DataExportError.insufficientStorage
            }
        }

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            throw DataManagementError.exportFileWriteFailed(path: fileURL.path, underlying: error)
        }
    }

    private func getAvailableStorage() -> Int64 {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: documentsPath.path)
            return attributes[.systemFreeSize] as? Int64 ?? 0
        } catch {
            return 0
        }
    }

    private func convertToManagementError(_ error: Error) -> DataManagementError {
        if let managementError = error as? DataManagementError {
            return managementError
        }

        // Convert other error types to DataManagementError
        if error is EncodingError {
            return .exportSerializationFailed(underlying: error)
        }

        return .unknownError(underlying: error)
    }

    // MARK: - Security and Privacy Methods

    func generatePrivacyNotice(for options: ExportOptions) -> Observable<(PrivacyNotice, [ComplianceIssue])> {
        return Observable.create { observer in
            let securityConfig = SecurityConfiguration(
                excludeAPIKeys: !options.includeAPIConfiguration,
                excludeDeviceInfo: !options.includeDeviceInfo,
                anonymizeContent: options.anonymizeData,
                encryptSensitiveData: false, // Not implemented yet
                addWatermark: false
            )

            let privacyNotice = self.sanitizationService.generatePrivacyNotice(for: securityConfig)

            // Generate mock export data for compliance checking
            let roasts = self.storageService.getRoastHistory()
            let preferences = self.storageService.getUserPreferences()

            let mockExportData = AppDataExport(
                metadata: ExportMetadata(
                    version: "1.0.0",
                    dataVersion: self.currentDataVersion,
                    exportDate: Date(),
                    totalRoasts: roasts.count,
                    totalFavorites: 0,
                    deviceInfo: DeviceInfo(platform: "iOS", osVersion: "17.0", appBuild: "1.0")
                ),
                userPreferences: preferences,
                roastHistory: roasts,
                favorites: [],
                statistics: ExportStatistics(
                    categoryBreakdown: [:],
                    averageSpiceLevel: 0,
                    mostPopularCategory: nil,
                    dateRange: nil
                ),
                checksum: nil
            )

            let complianceIssues = PrivacyCompliance.validateExportCompliance(mockExportData, config: securityConfig)

            observer.onNext((privacyNotice, complianceIssues))
            observer.onCompleted()

            return Disposables.create()
        }
    }

    private func applySecurity(to exportData: AppDataExport, options: ExportOptions) -> AppDataExport {
        let securityConfig = SecurityConfiguration(
            excludeAPIKeys: !options.includeAPIConfiguration,
            excludeDeviceInfo: !options.includeDeviceInfo,
            anonymizeContent: options.anonymizeData,
            encryptSensitiveData: false,
            addWatermark: false
        )

        // Apply sanitization and create new secure data
        let sanitizedUserPreferences = sanitizationService.sanitizeUserPreferences(exportData.userPreferences, config: securityConfig)
        let sanitizedRoastHistory = sanitizationService.sanitizeRoasts(exportData.roastHistory, config: securityConfig)
        let sanitizedMetadata = sanitizationService.sanitizeMetadata(exportData.metadata, config: securityConfig)

        let secureData = AppDataExport(
            metadata: sanitizedMetadata,
            userPreferences: sanitizedUserPreferences,
            roastHistory: sanitizedRoastHistory,
            favorites: exportData.favorites,
            statistics: exportData.statistics,
            checksum: exportData.checksum
        )

        return secureData
    }

    private func secureFile(at url: URL) throws {
        try fileSecurityService.setSecureFilePermissions(for: url)

        // Validate file integrity
        guard try fileSecurityService.validateFileIntegrity(url) else {
            throw DataManagementError.exportFileWriteFailed(path: url.path, underlying: NSError(domain: "FileIntegrity", code: -1, userInfo: [NSLocalizedDescriptionKey: "File integrity validation failed"]))
        }
    }

    private func calculateChecksum(data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - File Sharing Helper

extension DataExportService {
    func shareExportFile(at url: URL) -> UIActivityViewController {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        // Configure for iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        return activityVC
    }
}
