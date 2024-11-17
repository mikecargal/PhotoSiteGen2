//
//  ListingView.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/10/24.
//

import SwiftUI

struct ListingView: View {
    @Binding var webSiteDocument: WebSiteDocument
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
                    ForEach($webSiteDocument.galleries, editActions: .move) {
                        galleryListLinkView(
                            galleryDocument: $0.wrappedValue,
                            webSiteDocument: webSiteDocument,
                            deleteGallery: deleteGallery)
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
        panel.directoryURL = webSiteDocument.sourceFolder
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true

        if panel.runModal() == .OK {
            for url in panel.urls {
                webSiteDocument.ensureGalleryAt(directory: url)
            }
        }
    }

    func deleteGallery(_ gallery: GalleryDocument) {
        guard
            let deletionIndex = webSiteDocument.galleries.firstIndex(
                of: gallery)
        else { return }

        let newSelectedId = deletionIndex.advanced(
            by: gallery == webSiteDocument.galleries.last ? -1 : 1)
        selection = DetailViewEnum.gallerySelection(
            id: webSiteDocument.galleries[newSelectedId].id
        )

        $webSiteDocument.galleries.wrappedValue.remove(at: deletionIndex)
    }
}

#Preview {
    ListingView(
        webSiteDocument: .constant(WebSiteDocument.mock),
        selection: .constant(nil))
}
