import Foundation

/// Performance monitoring utility for tracking operation durations
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var measurements: [String: [TimeInterval]] = [:]
    private let queue = DispatchQueue(label: "com.roastmelater.performance", attributes: .concurrent)
    
    private init() {}
    
    /// Start measuring an operation
    /// - Parameter operation: Name of the operation to measure
    /// - Returns: Start time to pass to endMeasurement
    func startMeasurement(for operation: String) -> Date {
        return Date()
    }
    
    /// End measurement and log the duration
    /// - Parameters:
    ///   - operation: Name of the operation
    ///   - startTime: Start time from startMeasurement
    func endMeasurement(for operation: String, startTime: Date) {
        let duration = Date().timeIntervalSince(startTime)
        
        queue.async(flags: .barrier) { [weak self] in
            if self?.measurements[operation] == nil {
                self?.measurements[operation] = []
            }
            self?.measurements[operation]?.append(duration)
        }
        
        #if DEBUG
        print("⏱️ [\(operation)] Duration: \(String(format: "%.2f", duration * 1000))ms")
        #endif
    }
    
    /// Measure a synchronous operation
    /// - Parameters:
    ///   - operation: Name of the operation
    ///   - block: Code block to measure
    /// - Returns: Result of the block
    func measure<T>(operation: String, block: () -> T) -> T {
        let start = startMeasurement(for: operation)
        let result = block()
        endMeasurement(for: operation, startTime: start)
        return result
    }
    
    /// Get statistics for an operation
    /// - Parameter operation: Name of the operation
    /// - Returns: Statistics (average, min, max, count)
    func getStatistics(for operation: String) -> (average: TimeInterval, min: TimeInterval, max: TimeInterval, count: Int)? {
        return queue.sync {
            guard let durations = measurements[operation], !durations.isEmpty else {
                return nil
            }
            
            let sum = durations.reduce(0, +)
            let average = sum / Double(durations.count)
            let min = durations.min() ?? 0
            let max = durations.max() ?? 0
            
            return (average, min, max, durations.count)
        }
    }
    
    /// Print all statistics
    func printAllStatistics() {
        queue.sync {
            print("\n📊 Performance Statistics:")
            print("=" * 60)
            
            for (operation, durations) in measurements.sorted(by: { $0.key < $1.key }) {
                guard !durations.isEmpty else { continue }
                
                let sum = durations.reduce(0, +)
                let average = sum / Double(durations.count)
                let min = durations.min() ?? 0
                let max = durations.max() ?? 0
                
                print("\n\(operation):")
                print("  Count: \(durations.count)")
                print("  Average: \(String(format: "%.2f", average * 1000))ms")
                print("  Min: \(String(format: "%.2f", min * 1000))ms")
                print("  Max: \(String(format: "%.2f", max * 1000))ms")
            }
            
            print("\n" + "=" * 60)
        }
    }
    
    /// Clear all measurements
    func clearMeasurements() {
        queue.async(flags: .barrier) { [weak self] in
            self?.measurements.removeAll()
        }
    }
    
    /// Clear measurements for a specific operation
    /// - Parameter operation: Name of the operation
    func clearMeasurements(for operation: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.measurements.removeValue(forKey: operation)
        }
    }
}

// MARK: - String Extension for Repeat
private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

