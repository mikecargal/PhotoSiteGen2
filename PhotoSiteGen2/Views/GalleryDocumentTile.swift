//
//  GalleryDocumentFile.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/21/24.
//

import SwiftUI

struct GalleryDocumentTile: View {
    @Binding var galleryDocument: GalleryDocument
    @Binding var galleries: [GalleryDocument]

    @State private var verifyDelete: Bool = false
    var body: some View {
        VStack {
            HStack {
                TextField("Gallery Title", text: $galleryDocument.title)
                    .textFieldStyle(.plain)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding([.top], 5)
                Button {
                    verifyDelete.toggle()
                } label: {
                    Image(systemName: "trash")
                }
            }
            TitleImageEditView(galleryDocument: $galleryDocument)
            GallerySourceDirectorySelector(galleryDocument: $galleryDocument)
            TextField("categories", text: $galleryDocument.csCategories)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
            Form {
                TextField("Generation ID:", text: $galleryDocument.genName)
                    .textFieldStyle(.plain)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .alert(isPresented: $verifyDelete) {
            Alert(
                title: Text(
                    "Are you sure you want to delete gallery \"\(galleryDocument.title)\"?"
                ),
                message: nil,
                primaryButton: .destructive(
                    Text("Delete"), action: deleteGallery),
                secondaryButton: .cancel())

        }
    }

    func deleteGallery() {
        guard
            let deletionIndex = galleries.firstIndex(
                of: galleryDocument)
        else { return }

        galleries.remove(at: deletionIndex)
    }
}

#Preview {
    GalleryDocumentTile(
        galleryDocument: .constant(GalleryDocument.mock),
        galleries: .constant(WebSiteDocument.mock.galleries))
}
