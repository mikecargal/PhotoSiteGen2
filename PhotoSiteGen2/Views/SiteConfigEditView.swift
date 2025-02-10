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
        }
        .padding()
    }
}

#Preview {
    SiteConfigEditView(websiteDocument: .constant(WebSiteDocument()))
}
