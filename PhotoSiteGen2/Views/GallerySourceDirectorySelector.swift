//
//  GallerySourceDirectorySelector.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/18/24.
//

import SwiftUI

struct GallerySourceDirectorySelector: View {
    @Binding var galleryDocument: GalleryDocument

    var body: some View {
        let folderBinding = Binding(
            get: { galleryDocument.gallerySourceUrl },
            set: { url in galleryDocument.setGallerySourceTo(url: url) }
        )
        FolderSelector(
            label: "Source Directory",
            selectedFolder: folderBinding,
            selectedPathIsRelative: true
        )
    }
}

#Preview {
    GallerySourceDirectorySelector(
        galleryDocument: .constant(GalleryDocument.mock))
}
