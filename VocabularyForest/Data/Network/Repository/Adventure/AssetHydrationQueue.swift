//
//  AssetHydrationQueue.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.08.2026.
//

import Foundation

/// Serializes hydration passes and cancels every in-flight pass as one unit, so "cancel" always
/// stops the pass the user is actually watching, not just the most recently enqueued one.
protocol AssetHydrationQueueProtocol: AnyObject {
    /// A new pass waits for the previous one to finish; passes are idempotent so this is safe.
    func enqueue(_ pass: @escaping () async -> AssetHydrationSummary) async -> AssetHydrationSummary
    func cancelAll()
}

final class AssetHydrationQueue {

    // MARK: - PROPERTIES

    private let lock = NSLock()
    private var tasks: [(id: UUID, task: Task<AssetHydrationSummary, Never>)] = []
}

// MARK: - PROTOCOL CONFORMANCE

extension AssetHydrationQueue: AssetHydrationQueueProtocol {

    func enqueue(_ pass: @escaping () async -> AssetHydrationSummary) async -> AssetHydrationSummary {
        let (id, task) = makeTask(pass)
        let summary = await task.value
        removeTask(id: id)
        return summary
    }

    func cancelAll() {
        lock.lock()
        let activeTasks = tasks
        tasks.removeAll()
        lock.unlock()
        activeTasks.forEach { $0.task.cancel() }
    }
}

// MARK: - HELPERS

private extension AssetHydrationQueue {

    func makeTask(_ pass: @escaping () async -> AssetHydrationSummary) -> (id: UUID, task: Task<AssetHydrationSummary, Never>) {
        lock.lock()
        defer { lock.unlock() }
        let previousTask = tasks.last?.task
        let id = UUID()
        // Chaining on the previous task keeps passes serial; cancellation still reaches the new
        // task directly because cancelAll cancels every stored task, not just the head.
        let task = Task { () -> AssetHydrationSummary in
            _ = await previousTask?.value
            return await pass()
        }
        tasks.append((id: id, task: task))
        return (id: id, task: task)
    }

    func removeTask(id: UUID) {
        lock.lock()
        tasks.removeAll { $0.id == id }
        lock.unlock()
    }
}
