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

    @Binding var turningOffDevMode: Bool
  var  staticURL: URL
  var  destURL: URL
    let sLogger = SaveErrorHandler()
    enum StaticSaveStatus {
        case saving, success, failure
    }

    var saveStatus: StaticSaveStatus
    var body: some View {
        VStack {
            Text("Save or Discard changes?")
            HStack {
                Button("Save" {
                     saveStaticResources(staticURL: staticURL,
                                         destURL: destURL,errorHandler:  sLogger )
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
            }
        }        }
        .padding()

        .frame(minWidth: 500, minHeight: 500)
        if saveStatus == .failure {
            TextEditor(text: .constant(gatherErrors().joined(separator: "\n")))
                .frame(height: 100)
                .padding()
        }
    }

    func saveStaticResources(staticURL: URL, destURL: URL, errorHandler: ErrorHandler) {
        
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
            } catch {
               await sLogger.handleError(context, error)
            }
            Self.logger.info(
                "Finished copying static content back to source")
        }
    }

    @Observable @MainActor
    class SaveErrorHandler: ErrorHandler {

        private var errors: [String]

        init() {}

        func handleError(_ context: String, _ error: any Error) async {
            errors.append("\(context): \(error)")
        }
    }
}
