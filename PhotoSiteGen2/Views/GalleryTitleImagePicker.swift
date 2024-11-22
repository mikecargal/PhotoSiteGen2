//
//  GalleryTitleImagePicker.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/18/24.
//

import SwiftUI

struct GalleryTitleImagePicker: View {
    let gallerySourceURL: URL
    @Binding var titleImageName: String
    @State var panelDelegate: PanelDelegate?
    
    var body: some View {
        Button {
            let panel = NSOpenPanel()
            let imageDirectory = gallerySourceURL
            panel.directoryURL = imageDirectory
            panel.allowsMultipleSelection = false
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.canCreateDirectories = false
            panel.allowedContentTypes = [.image]
            panel.isAccessoryViewDisclosed = false
            panel.title = "Select Image"
            panelDelegate = PanelDelegate(imageDirectory.absoluteString)
            panel.delegate = panelDelegate!

            if panel.runModal() == .OK {
                if let url = panel.url {
                    titleImageName = url.lastPathComponent
                }
            }
        } label: {
            Image(systemName: "photo")
                .background(Color.gray.opacity(0.2))
        }
    }
    
    class PanelDelegate: NSObject, NSOpenSavePanelDelegate {
        var galleryImageDirectoryPath: String
        
        init(_ galleryImageDirectoryPath: String) {
            self.galleryImageDirectoryPath = galleryImageDirectoryPath
        }
        
        func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
            return url.hasDirectoryPath
                ? galleryImageDirectoryPath.starts(with: url.absoluteString)
                : url.deletingLastPathComponent().absoluteString
                    == galleryImageDirectoryPath
        }
    }
}

#Preview {
    GalleryTitleImagePicker(
        gallerySourceURL: FileManager.default.homeDirectoryForCurrentUser,
        titleImageName: .constant("titleImageName"))
}
