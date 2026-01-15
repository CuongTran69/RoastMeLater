import Foundation

// MARK: - Data Migration Service

protocol DataMigrationServiceProtocol {
    func migrateData(from oldVersion: Int, to newVersion: Int, data: AppDataExport) throws -> AppDataExport
    func canMigrate(from oldVersion: Int, to newVersion: Int) -> Bool
}

class DataMigrationService: DataMigrationServiceProtocol {
    
    // MARK: - Migration Path
    
    func canMigrate(from oldVersion: Int, to newVersion: Int) -> Bool {
        // Check if migration path exists
        guard oldVersion < newVersion else { return false }
        
        // Currently support migration from version 1 to any future version
        return oldVersion >= 1 && newVersion <= 10 // Support up to version 10
    }
    
    func migrateData(from oldVersion: Int, to newVersion: Int, data: AppDataExport) throws -> AppDataExport {
        guard canMigrate(from: oldVersion, to: newVersion) else {
            throw DataMigrationError.unsupportedMigrationPath(from: oldVersion, to: newVersion)
        }
        
        var migratedData = data
        
        // Apply migrations sequentially
        for version in (oldVersion + 1)...newVersion {
            migratedData = try performMigration(to: version, data: migratedData)
        }
        
        return migratedData
    }
    
    // MARK: - Version-Specific Migrations
    
    private func performMigration(to version: Int, data: AppDataExport) throws -> AppDataExport {
        switch version {
        case 2:
            return try migrateToV2(data)
        case 3:
            return try migrateToV3(data)
        case 4:
            return try migrateToV4(data)
        default:
            // No migration needed for this version
            return data
        }
    }
    
    // MARK: - Migration to Version 2
    // Example: Add new field with default value
    
    private func migrateToV2(_ data: AppDataExport) throws -> AppDataExport {
        // Example migration: Add tags field to roasts (if we add this feature in v2)
        // For now, just update metadata version
        
        var newMetadata = data.metadata
        // Update to reflect new version
        let mirror = Mirror(reflecting: newMetadata)
        
        // Create new metadata with updated version
        let updatedMetadata = ExportMetadata(
            version: data.metadata.version,
            dataVersion: 2,
            exportDate: data.metadata.exportDate,
            totalRoasts: data.metadata.totalRoasts,
            totalFavorites: data.metadata.totalFavorites,
            deviceInfo: data.metadata.deviceInfo
        )
        
        return AppDataExport(
            metadata: updatedMetadata,
            userPreferences: data.userPreferences,
            roastHistory: data.roastHistory,
            favorites: data.favorites,
            statistics: data.statistics,
            checksum: nil // Checksum will be recalculated on export
        )
    }
    
    // MARK: - Migration to Version 3
    // Example: Add new category or modify existing data structure
    
    private func migrateToV3(_ data: AppDataExport) throws -> AppDataExport {
        // Example: If we add a new category in v3, existing roasts remain unchanged
        // Just update version number
        
        let updatedMetadata = ExportMetadata(
            version: data.metadata.version,
            dataVersion: 3,
            exportDate: data.metadata.exportDate,
            totalRoasts: data.metadata.totalRoasts,
            totalFavorites: data.metadata.totalFavorites,
            deviceInfo: data.metadata.deviceInfo
        )
        
        return AppDataExport(
            metadata: updatedMetadata,
            userPreferences: data.userPreferences,
            roastHistory: data.roastHistory,
            favorites: data.favorites,
            statistics: data.statistics,
            checksum: nil
        )
    }
    
    // MARK: - Migration to Version 4
    // Example: Add new preferences or modify roast structure
    
    private func migrateToV4(_ data: AppDataExport) throws -> AppDataExport {
        // Example: If we add new preferences in v4, set default values
        
        let updatedMetadata = ExportMetadata(
            version: data.metadata.version,
            dataVersion: 4,
            exportDate: data.metadata.exportDate,
            totalRoasts: data.metadata.totalRoasts,
            totalFavorites: data.metadata.totalFavorites,
            deviceInfo: data.metadata.deviceInfo
        )
        
        return AppDataExport(
            metadata: updatedMetadata,
            userPreferences: data.userPreferences,
            roastHistory: data.roastHistory,
            favorites: data.favorites,
            statistics: data.statistics,
            checksum: nil
        )
    }
}

// MARK: - Migration Errors

enum DataMigrationError: Error, LocalizedError {
    case unsupportedMigrationPath(from: Int, to: Int)
    case migrationFailed(version: Int, reason: String)
    case corruptedDataDuringMigration(version: Int)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedMigrationPath(let from, let to):
            return "Không hỗ trợ migration từ phiên bản \(from) đến \(to)"
        case .migrationFailed(let version, let reason):
            return "Migration đến phiên bản \(version) thất bại: \(reason)"
        case .corruptedDataDuringMigration(let version):
            return "Dữ liệu bị hỏng trong quá trình migration đến phiên bản \(version)"
        }
    }
}

// MARK: - Migration Strategy

enum MigrationStrategy {
    case automatic      // Automatically migrate to latest version
    case manual         // Ask user before migrating
    case skipIfNeeded   // Skip migration if data is compatible
}

// MARK: - Migration Result

struct MigrationResult {
    let success: Bool
    let fromVersion: Int
    let toVersion: Int
    let warnings: [String]
    let errors: [Error]
}

