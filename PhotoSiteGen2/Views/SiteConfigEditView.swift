//
//  SiteConfigEditView.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/10/24.
//

import SwiftUI

struct SiteConfigEditView: View {
    @Binding var websiteDocument: WebSiteDocument

    var body: some View {
        Form {
            FolderSelector(
                label: "Source Folder",
                selectedFolder: $websiteDocument.sourceFolder,
                defaultFolder: FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent("WebsiteSource")
            )

            FolderSelector(
                label: "Static Source Folder",
                selectedFolder: $websiteDocument.staticSiteFolder,
                defaultFolder: FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent("WebsiteStatic")
            )

            FolderSelector(
                label: "DestinationFolder",
                selectedFolder: $websiteDocument.destinationFolder,
                defaultFolder: FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent("Sites").appendingPathComponent(
                        "MySite")
            )
        }
        .padding()
    }
}

#Preview {
    SiteConfigEditView(websiteDocument: .constant(WebSiteDocument()))
}
