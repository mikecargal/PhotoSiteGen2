import OSLog
//
//  WebsiteGenStatusView.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/25/24.
//
import SwiftUI

struct DevModeDeactivationView: View {
    private static let logger = Logger(
        subsystem: "com.mikecargal.photositegen2",
        category: "DevModeDeactivationView")

    enum StaticSaveStatus {
        case pending, saving, success, failure
    }

    @Binding var turningOffDevMode: Bool
    var staticURL: URL
    var destURL: URL

    let sLogger = SaveErrorHandler()

    @State var saveStatus: StaticSaveStatus = .pending
    var body: some View {
        VStack {
            Text("Save or Discard changes?")
            HStack {
                Button("Save") {
                    saveStaticResources(
                        staticURL: staticURL,
                        destURL: destURL, errorHandler: sLogger)
                }
                Button("Discard") {
                    turningOffDevMode = false
                }
            }

            HStack {
                switch saveStatus {
                case .saving:
                    Text("Saving...")
                case .success:
                    Text("Saved!")
                case .failure:
                    Text("Save Failed!")
                case .pending:
                    Text("")
                }
            }
            
            if saveStatus == .success || saveStatus == .failure  {
                Button("Dismiss") {
                    turningOffDevMode = false
                }
            }
        }
        .padding()
        if saveStatus == .failure {
            TextEditor(text: .constant(sLogger.errors.joined(separator: "\n")))
                .frame(height: 100)
                .padding()
        }
    }

    func saveStaticResources(
        staticURL: URL, destURL: URL, errorHandler: ErrorHandler
    ) {
        saveStatus = .saving
        Task {
            var context = "copying static content back to source"

            do {
                context = "copying static css content back to source"
                try await copyDirectory(
                    from: destURL.appending(
                        path: "css"),
                    to: staticURL.appending(
                        path: "css"),
                    statusLogger: sLogger,
                    context: context)
                context = "copying static js content back to source"
                try await copyDirectory(
                    from: destURL.appending(
                        path: "js"),
                    to: staticURL.appending(
                        path: "js"),
                    statusLogger: sLogger,
                    context: context)
                context = "copying static image content back to source"
                try await copyDirectory(
                    from: destURL.appending(
                        path: "images"),
                    to: staticURL.appending(
                        path: "images"),
                    statusLogger: sLogger,
                    context: context)
                saveStatus = .success
            } catch {
                saveStatus = .failure
                await sLogger.handleError(context, error)
            }
            Self.logger.info(
                "Finished copying static content back to source")
        }
    }

    @Observable @MainActor
    class SaveErrorHandler: ErrorHandler {

        private(set) var errors: [String]

        init() {
            errors = []
        }

        func handleError(_ context: String, _ error: any Error) async {
            errors.append("\(context): \(error)")
        }
    }
}
