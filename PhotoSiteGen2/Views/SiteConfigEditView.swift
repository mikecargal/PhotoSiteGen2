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
        }
        .padding()
    }
}

#Preview {
    SiteConfigEditView(websiteDocument: .constant(WebSiteDocument()))
}
