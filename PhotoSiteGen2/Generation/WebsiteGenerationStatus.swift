//
//  WebsiteGenerationStatus.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/25/24.
//
import SwiftUI

@Observable @MainActor
class WebsiteGenerationStatus: ErrorHandler {
    @MainActor
    enum Status: Int {
        case generatingWithErrors
        case generatingNoErrors
        case pending
        case completeWithErrors
        case completeNoErrors
        
        @ViewBuilder
        var view: some View {
            switch self {
            case .pending: Image(systemName: "tray.and.arrow.down")
            case .generatingNoErrors:
                ProcessingView()
            case .generatingWithErrors:
                HStack {
                    Image(systemName: "x.circle.fill")
                        .foregroundStyle(.red)
                    ProcessingView()
                 }
            case .completeNoErrors:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .completeWithErrors:
                Image(systemName: "x.circle.fill")
                    .foregroundStyle(.red)
            }
        }

        var description: String {
            switch self {
            case .pending: "Pending"
            case .generatingNoErrors: "Generating"
            case .generatingWithErrors: "Generating with errors"
            case .completeNoErrors: "Complete"
            case .completeWithErrors: "Complete with errors"
            }
        }
    }
    
    var status: Status = .pending
    var errors = [String]()
    var galleryStatuses: [GalleryGenerationStatus] = []

    func startGeneration() {
        status = .generatingNoErrors
        errors.removeAll()
    }

    func completeGeneration() {
        status = hasError ? .completeWithErrors : .completeNoErrors
    }
    
    func logError(_ error: String) {
        status = .generatingWithErrors
        errors.append(error)
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

}

@Observable @MainActor
class GalleryGenerationStatus: Identifiable, ErrorHandler {

    let id: UUID = UUID()
    var galleryTitle: String
    var galleryName: String
    let websiteGenerationStatus: WebsiteGenerationStatus
    var status: WebsiteGenerationStatus.Status = .pending
    var errors = [String]()

    init(galleryTitle: String, galleryName: String,webSiteGenerationStatus: WebsiteGenerationStatus) {
        self.galleryTitle = galleryTitle
        self.galleryName = galleryName
        self.websiteGenerationStatus = webSiteGenerationStatus
        self.websiteGenerationStatus.galleryStatuses.append(self)
    }

    func startGeneration() {
        status = .generatingNoErrors
        errors.removeAll()
    }

    func completeGeneration() {
        status = hasError ? .completeWithErrors : .completeNoErrors
    }

    func logError(_ error: String) {
        status = .generatingWithErrors
        errors.append(error)
        websiteGenerationStatus.galleryHasError()
    }

    var hasError: Bool {
        return !errors.isEmpty
    }

    func handleError(_ context: String, _ error: any Error) async {
        logError("\(galleryName) (\(context)): \(error)")
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
