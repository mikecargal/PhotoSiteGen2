//
//  GalleryListLinkView.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/16/24.
//
import SwiftUI

struct galleryListLinkView: View {
    var galleryDocument: GalleryDocument
    var webSiteDocument: WebSiteDocument
    var deleteGallery: (GalleryDocument) -> Void

    var body: some View {
        NavigationLink(
            value: DetailViewEnum.gallerySelection(
                id: galleryDocument.id)
        ) {
            ZStack {
                let imageUrl = galleryDocument.titleImageUrl
                if let imageUrl {
                    AsyncImage(
                        url: imageUrl
                    ) { image in
                        image.image?.resizable().scaledToFit()
                    }
                    .frame(height: 120)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .frame(width: 120, height: 120)
                }
                Text(galleryDocument.title)
                    .contextMenu {
                        Button("Delete") {
                            deleteGallery(galleryDocument)
                        }
                    }
                    .background(Color.black.opacity(0.4))
            }
            .padding(.leading, 20)
        }
    }
}
