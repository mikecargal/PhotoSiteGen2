//
//  CategoryView.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/10/24.
//

import SwiftUI

struct GalleryView: View {
    @Binding var galleryDocument: GalleryDocument

    var body: some View {
        Form {
            Text("Directory: \(galleryDocument.directory)")
            Spacer()
            Section(header: Text("Gallery Details")) {
                TextField("Title", text: $galleryDocument.title)
                TextField(
                    "Title Image Name",
                    text: $galleryDocument.titleImageName)
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    GalleryView(galleryDocument: .constant(GalleryDocument.mock))
}
