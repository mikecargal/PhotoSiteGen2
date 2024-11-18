//
//  TitleImageEditView.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/18/24.
//

import SwiftUI

struct TitleImageEditView: View {
    @Binding var galleryDocument: GalleryDocument
    @State var showTitleImageName: Bool = false
    
    var body: some View {
        let imageUrl = galleryDocument.titleImageUrl
        HStack(alignment: .bottom) {
            if let imageUrl {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable()
                                .scaledToFit()
                                .frame(height: 200)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .frame(width: 200, height: 200)
                        @unknown default:
                            EmptyView()
                        }
                    }

                    Button {
                        showTitleImageName.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .frame(width: 200, height: 200)
            }
            GalleryTitleImagePicker(gallerySourceURL: galleryDocument.gallerySourceUrl, titleImageName: $galleryDocument.titleImageName)
        }
        if showTitleImageName {
            Text(galleryDocument.titleImageName)
        }
    }
    
}

#Preview {
    TitleImageEditView(galleryDocument: .constant(GalleryDocument.mock))
}
