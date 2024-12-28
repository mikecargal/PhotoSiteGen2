//
//  WebsiteGenerationStatus.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/25/24.
//
import SwiftUI

@MainActor
enum GenerationStatus: Int {
    case generatingWithErrors
    case generatingNoErrors
    case pending
    case completeWithErrors
    case completeNoErrors
    case cancelled

    var description: String {
        switch self {
        case .pending: "Pending"
        case .generatingNoErrors: "Generating"
        case .generatingWithErrors: "Generating with errors"
        case .completeNoErrors: "Complete"
        case .completeWithErrors: "Complete with errors"
        case .cancelled: "Cancelled"
        }
    }
}

@Observable @MainActor
class WebsiteGenerationStatus: ErrorHandler,
    Identifiable
{

    let id = UUID()

    var status: GenerationStatus = .pending
    var errors = [String]()
    var galleryStatuses: [GalleryGenerationStatus] = []

    var percentComplete: Double {
        let progressCounter = galleryStatuses.reduce(0) {
            $0 + $1.progressCounter
        }
        let ticksToComplete = galleryStatuses.reduce(0) {
            $0 + $1.progressTarget
        }
        return progressCounter > 0
            ? Double(progressCounter) / Double(ticksToComplete) : 0.0
    }

    func startGeneration() {
        status = .generatingNoErrors
        errors.removeAll()
    }

    func completeGeneration() {
        guard !(status == .cancelled) else { return }
        status = hasError ? .completeWithErrors : .completeNoErrors
    }

    func logError(_ error: String) {
        status = .generatingWithErrors
        errors.append(error)
    }

    func cancelledGeneration() {
        status = .cancelled
    }

    var hasError: Bool {
        return !errors.isEmpty
            || galleryStatuses.contains(where: { $0.hasError })
    }

    func handleError(_ context: String, _ error: any Error) async {
        logError("Website generation error (\(context)): \(error)")
    }

    func galleryHasError() {
        status = .generatingWithErrors
    }

    func progressTick() {
        // nothing to do here
    }

    @ViewBuilder
    var view: some View {
        switch status {
        case .pending: Image(systemName: "tray.and.arrow.down")
        case .generatingNoErrors:
            ProgressView(value: percentComplete)
        case .generatingWithErrors:
            HStack {
                Image(systemName: "x.circle.fill")
                    .foregroundStyle(.red)
                ProgressView(value: percentComplete)
            }
        case .completeNoErrors:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .completeWithErrors:
            Image(systemName: "x.circle.fill")
                .foregroundStyle(.red)
        case .cancelled:
            Image(systemName: "circle.slash")
                .foregroundStyle(.red)
        }
    }
}

@Observable @MainActor
class GalleryGenerationStatus: Identifiable,
    ErrorHandler
{
    let TICKS_PER_IMAGE = 3
    let id: UUID = UUID()
    var galleryTitle: String
    var galleryName: String
    let websiteGenerationStatus: WebsiteGenerationStatus
    var status: GenerationStatus = .pending
    var errors = [String]()
    var itemCount: Int = 0
    var progressTarget: Int {
        itemCount * TICKS_PER_IMAGE
    }
    var progressCounter = 0
    var percentComplete: Double {
        Double(progressCounter) / Double(progressTarget)
    }

    init(
        galleryTitle: String, galleryName: String,
        webSiteGenerationStatus: WebsiteGenerationStatus
    ) {
        self.galleryTitle = galleryTitle
        self.galleryName = galleryName
        self.websiteGenerationStatus = webSiteGenerationStatus
        self.websiteGenerationStatus.galleryStatuses.append(self)
    }

    func startGeneration() {
        status = .generatingNoErrors
        errors.removeAll()
    }

    func setItemCount(_ count: Int) {
        itemCount = count
    }

    func progressTick() {
        progressCounter += 1
    }

    func completeGeneration() {
        guard !(status == .cancelled) else { return }
        status = hasError ? .completeWithErrors : .completeNoErrors
    }

    func logError(_ error: String) {
        status = .generatingWithErrors
        errors.append(error)
        websiteGenerationStatus.galleryHasError()
    }
    func cancelledGeneration() {
        status = .cancelled
    }

    var hasError: Bool {
        return !errors.isEmpty
    }

    func handleError(_ context: String, _ error: any Error) async {
        logError("\(galleryName) (\(context)): \(error)")
    }

    @ViewBuilder
    var view: some View {
        let VIEW_WIDTH: CGFloat = 250
        HStack {
            switch status {
            case .pending: Image(systemName: "tray.and.arrow.down")
            case .generatingNoErrors:
                ProgressView(value: percentComplete).frame(width: VIEW_WIDTH)
            case .generatingWithErrors:
                Image(systemName: "x.circle.fill")
                    .foregroundStyle(.red)
                ProgressView(value: percentComplete).frame(
                    width: VIEW_WIDTH - 15)
            case .completeNoErrors:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Spacer()
            case .completeWithErrors:
                Image(systemName: "x.circle.fill")
                    .foregroundStyle(.red)
                Spacer()
            case .cancelled:
                Image(systemName: "circle.slash")
                    .foregroundStyle(.red)
                Spacer()
            }
        }.frame(width: 300)
    }

}

@MainActor
struct ProcessingView: View {
    @State private var rotationAngle: Double = 0

    var body: some View {
        HStack {
            Image(systemName: "progress.indicator")
                .rotationEffect(.degrees(rotationAngle))
                .animation(
                    .linear(duration: 1.5).repeatForever(autoreverses: false),
                    value: rotationAngle)
        }
        .onAppear {
            rotationAngle = 360
        }
    }
}
