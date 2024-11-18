//
//  Logger.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 1/9/24.
//

import Foundation

@MainActor
@Observable
class Logger: ErrorHandler {
    var messages = [String]()
    var errorLevel = ErrorLevel.NO_ERROR
    private var galleriesProgress = [String: (ttl: Int, complete: Int)]()
    private(set) var completionStatus = GenerationCompletionStatus.started
    private(set) var overallPercentComplete = Double(0.0)

    enum ErrorLevel {
        case NO_ERROR, WARN, ERROR
    }

    enum GenerationCompletionStatus {
        case inactive, started, completedSuccessfully, completedWithError
    }

    func reset() {
        messages.removeAll()
        errorLevel = .NO_ERROR
        galleriesProgress.removeAll()
        completionStatus = .inactive
    }

    func handleError(_ context: String, _ error: Error) {
        errorLevel = .ERROR
        messages.append("\(context) \(String(describing: error))")

        debugPrint(context)
        debugPrint(error)
    }

    func logMessage(_ message: String) {
        messages.append(message)
    }

    func markComplete() {
        if errorLevel == .NO_ERROR {
            completionStatus = .completedSuccessfully
        } else {
            completionStatus = .completedWithError
        }
    }

    func updateGalleryProgress(galleryName: String, itemCount: Int, completionCount: Int) async {
        galleriesProgress[galleryName] = (ttl: itemCount, complete: completionCount)
        let allGalleries = galleriesProgress.values.reduce((ttl: 0, complete: 0))
            { (ttl: $0.ttl + $1.ttl, complete: $0.complete + $1.complete) }
        overallPercentComplete = Double(allGalleries.complete) / Double(allGalleries.ttl)
    }

    func progressFor(gallery galleryName: String) -> Double {
        guard let status = galleriesProgress[galleryName] else { return 0.0 }
        return Double(status.complete / status.ttl)
    }

    func start() {
        completionStatus = .started
    }
}

protocol ErrorHandler: Sendable {
    func handleError(_ context: String, _ error: Error) async -> Void
    func markComplete() async -> Void
    func updateGalleryProgress(galleryName: String, itemCount: Int, completionCount: Int) async -> Void
}
