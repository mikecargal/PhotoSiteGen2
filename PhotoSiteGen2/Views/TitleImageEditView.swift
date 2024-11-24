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
        VStack {
            HStack(alignment: .bottom) {
                ZStack(alignment: .bottom) {
                    if let imageUrl {
                        AsyncImage(url: imageUrl) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image.resizable()
                                    .scaledToFit()
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                            @unknown default:
                                EmptyView()
                            }
                        }
                        HStack {
                            Button {
                                showTitleImageName.toggle()
                            } label: {
                                Image(systemName: "info.circle")
                            }
                            .background(Color.gray.opacity(0.6))
                            .clipShape(.buttonBorder)
                            Spacer()
                            GalleryTitleImagePicker(
                                gallerySourceURL: galleryDocument
                                    .gallerySourceUrl,
                                titleImageName: $galleryDocument.titleImageName)
                        }
                    } else {
                        HStack {
                            Image(systemName: "photo.badge.exclamationmark")
                                .resizable()
                                .frame(width: 200, height: 200)
                            GalleryTitleImagePicker(
                                gallerySourceURL: galleryDocument
                                    .gallerySourceUrl,
                                titleImageName: $galleryDocument.titleImageName)
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            if showTitleImageName {
                Text(galleryDocument.titleImageName)
            }
        }
    }

}

#Preview {
    TitleImageEditView(galleryDocument: .constant(GalleryDocument.mock))
}
