//
//  ListingView.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/10/24.
//

import SwiftUI

struct ListingView: View {
    @Binding var websiteDocument: WebSiteDocument
    @Binding var selection: DetailViewEnum?

    var body: some View {
        NavigationStack {
            List(selection: $selection) {
                NavigationLink(
                    value: DetailViewEnum.siteConfiguration
                ) {
                    Label("Site Configuration", systemImage: "gear")
                }

                Section {
                    ForEach($websiteDocument.galleries, editActions: .move) {
                        $galleryDocument in
                        NavigationLink(
                            value: DetailViewEnum.gallerySelection(
                                id: galleryDocument.id)
                        ) {
                            HStack {
                                Image(systemName: "photo")
                                Text(galleryDocument.title)
                                    .contextMenu {
                                        Button("Delete") {
                                            deleteGallery(galleryDocument)
                                        }
                                    }
                            }
                            .padding(.leading, 20)
                        }
                    }
                } header: {
                    HStack {
                        Label("Galleries", systemImage: "photo.stack")
                            .font(.headline)
                        Button(action: addGallery) {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.accessoryBar)
                    }
                }
            }
        }
    }

    func addGallery() {
        let panel = NSOpenPanel()
        panel.directoryURL = websiteDocument.sourceFolder
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true

        if panel.runModal() == .OK {
            for url in panel.urls {
                if !$websiteDocument.galleries.contains(where: {
                    $0.wrappedValue.directory == url.lastPathComponent
                }) {
                    let gallery = GalleryDocument(
                        title: url.lastPathComponent,
                        directory: url.lastPathComponent)
                    $websiteDocument.galleries.wrappedValue.append(gallery)
                }
            }
        }
    }

    func deleteGallery(offsets: IndexSet) {
        $websiteDocument.galleries.wrappedValue.remove(atOffsets: offsets)
    }

    func deleteGallery(_ gallery: GalleryDocument) {
        guard
            let deletionIndex = websiteDocument.galleries.firstIndex(
                of: gallery)
        else { return }
        
        let newSelectedId =  deletionIndex.advanced(
            by: gallery == websiteDocument.galleries.last ? -1 : 1)
        selection = DetailViewEnum.gallerySelection(
            id: websiteDocument.galleries[newSelectedId].id
        )
        
        $websiteDocument.galleries.wrappedValue.remove(at: deletionIndex)
    }
}

#Preview {
    ListingView(
        websiteDocument: .constant(WebSiteDocument.mock),
        selection: .constant(nil))
}
