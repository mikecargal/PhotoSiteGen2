//
//  CategoryView.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/10/24.
//

import SwiftUI

struct GalleryEditView: View {
    @Binding var galleryDocument: GalleryDocument
    var webSiteDocument: WebSiteDocument

    var body: some View {
        Form {
            Spacer()
            TitleImageEditView(galleryDocument: $galleryDocument)
            Spacer()
            TextField("Title", text: $galleryDocument.title)
            GallerySourceDirectorySelector(galleryDocument: $galleryDocument)
            Spacer()
        }
        .padding()
    }

}

#Preview {
    GalleryEditView(
        galleryDocument: .constant(GalleryDocument.mock), webSiteDocument: .mock
    )
}
