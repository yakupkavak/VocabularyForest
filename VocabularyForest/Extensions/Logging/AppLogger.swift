//
//  AppLogger.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.08.2026.
//

import Foundation
import os

enum LogCategory: String {
    case forest, sync, asset, auth, reward, ui, data, analytics
}

protocol AppLoggerProtocol: AnyObject {
    func debug(_ message: String, category: LogCategory)
    func error(_ message: String, category: LogCategory)
}

// MARK: - CONSTANTS

private extension AppLogger {
    enum Constants {
        static let fallbackSubsystem = "VocabularyForest"
    }
}

final class AppLogger {

    // MARK: - PROPERTIES

    static let shared = AppLogger()

    private let subsystem = Bundle.main.bundleIdentifier ?? Constants.fallbackSubsystem
    private var loggers: [LogCategory: Logger] = [:]
    private let lock = NSLock()
}

// MARK: - PROTOCOL CONFORMANCE

extension AppLogger: AppLoggerProtocol {

    func debug(_ message: String, category: LogCategory) {
        logger(for: category).debug("\(message, privacy: .public)")
    }

    func error(_ message: String, category: LogCategory) {
        logger(for: category).error("\(message, privacy: .public)")
    }
}

// MARK: - HELPERS

private extension AppLogger {

    func logger(for category: LogCategory) -> Logger {
        lock.lock()
        defer { lock.unlock() }
        if let existingLogger = loggers[category] { return existingLogger }
        let newLogger = Logger(subsystem: subsystem, category: category.rawValue)
        loggers[category] = newLogger
        return newLogger
    }
}
