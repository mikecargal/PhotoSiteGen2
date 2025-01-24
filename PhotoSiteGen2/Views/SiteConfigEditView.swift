//
//  SiteConfigEditView.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/10/24.
//

import OSLog
import SwiftUI

struct SiteConfigEditView: View {
    private static let logger = Logger(
        subsystem: "com.mikecargal.photositegen2",
        category: "SiteConfigEditView")

    @Binding var websiteDocument: WebSiteDocument
    var rootURLIsValid: Bool {
        websiteDocument.siteRootURL != nil
    }

    var body: some View {
        Form {
            FolderSelector(
                label: "Source Folder",
                selectedFolder: $websiteDocument.sourceFolder
            )

            FolderSelector(
                label: "Static Source Folder",
                selectedFolder: $websiteDocument.staticSiteFolder
            )

            FolderSelector(
                label: "DestinationFolder",
                selectedFolder: $websiteDocument.destinationFolder
            )

            TextField(
                "Site Root URL",
                text:
                    Binding(
                        get: {
                            websiteDocument.siteRootURL?.absoluteString
                                ?? "https://"
                        },
                        set: { websiteDocument.siteRootURL = URL(string: $0) }
                    )
            )
            if !rootURLIsValid {
                Text("Site Root URL must be a valid URL")
            }
            if let destinationFolder = websiteDocument.destinationFolder,
                let staticSiteFolder = websiteDocument.staticSiteFolder
            {
                Button("Copy static content back to source") {
                    Task {
                        var context = "copying static content back to source"
                        let sLogger = CopyBackErrorHandler()
                        do {
                            context = "copying static css content back to source"
                            try await copyDirectory(
                                from: destinationFolder.appending(path: "css"),
                                to: staticSiteFolder.appending(path: "css"),
                                statusLogger: sLogger,
                                context: context)
                            context = "copying static js content back to source"
                            try await copyDirectory(
                                from: destinationFolder.appending(path: "js"),
                                to: staticSiteFolder.appending(path: "js"),
                                statusLogger: sLogger,
                                context: context)
                            context = "copying static image content back to source"
                            try await copyDirectory(
                                from: destinationFolder.appending(path: "images"),
                                to: staticSiteFolder.appending(path: "images"),
                                statusLogger: sLogger,
                                context: context)
                        } catch {
                            SiteConfigEditView.logger.error("\(error)")
                        }
                        Self.logger.info("Finished copying static content back to source")
                    }
                }
            }

        }
        .padding()
    }

    private struct CopyBackErrorHandler: ErrorHandler {
        func handleError(_ context: String, _ error: any Error) async {
            let _ = await SiteConfigEditView.logger.error(
                "(\(context)):\(error)")
        }
    }
}

#Preview {
    SiteConfigEditView(websiteDocument: .constant(WebSiteDocument()))
}
