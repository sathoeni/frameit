//
//  ExecutionTimer.swift
//  frameit
//
//  Created by Sascha Thöni on 05.12.2024.
//


import Foundation

import Foundation

class ExecutionTimer {
    /// Measures the execution time of a synchronous throwing function with an optional label.
    /// - Parameters:
    ///   - label: An optional label to include in the output.
    ///   - block: The throwing function to measure.
    /// - Returns: A tuple containing the result of the function and the time interval in seconds.
    /// - Throws: Rethrows any error thrown by the block.
    @discardableResult
    static func measure<T>(
        label: String? = nil,
        _ block: () throws -> T
    ) rethrows -> (result: T, duration: TimeInterval) {
        let start = Date()
        let result = try block()
        let end = Date()
        let timeInterval = end.timeIntervalSince(start)
        if let label = label {
            print("\(label) - Execution time: \(timeInterval) seconds")
        } else {
            print("Execution time: \(timeInterval) seconds")
        }
        return (result, timeInterval)
    }

    /// Measures the execution time of an asynchronous throwing function with an optional label.
    /// - Parameters:
    ///   - label: An optional label to include in the output.
    ///   - block: The asynchronous throwing function to measure.
    /// - Returns: A tuple containing the result of the function and the time interval in seconds.
    /// - Throws: Rethrows any error thrown by the block.
    @discardableResult
    static func measureAsync<T>(
        label: String? = nil,
        _ block: @escaping () async throws -> T
    ) async rethrows -> (result: T, duration: TimeInterval) {
        let start = Date()
        let result = try await block()
        let end = Date()
        let timeInterval = end.timeIntervalSince(start)
        if let label = label {
            print("\(label) - Execution time: \(timeInterval) seconds")
        } else {
            print("Execution time: \(timeInterval) seconds")
        }
        return (result, timeInterval)
    }
}
