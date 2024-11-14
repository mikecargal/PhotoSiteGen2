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
                selectedFolder: websiteDocument.sourceFolder
                ?? FileManager.default.homeDirectoryForCurrentUser
            ) { url in websiteDocument.sourceFolder = url
            }
            
            FolderSelector(
                label: "Static Source Folder",
                selectedFolder: websiteDocument.staticSiteFolder
                ?? FileManager.default.homeDirectoryForCurrentUser
            ) { url in
                websiteDocument.staticSiteFolder = url
            }
            
            FolderSelector(
                label: "DestinationFolder",
                selectedFolder: websiteDocument.destinationFolder
                ?? FileManager.default.homeDirectoryForCurrentUser
            ) { url in
                websiteDocument.destinationFolder = url
            }
        }
        .padding()
    }
}

#Preview {
    SiteConfigEditView(websiteDocument: .constant(WebSiteDocument()))
}
