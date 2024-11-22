//
//  GalleryGridView.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/21/24.
//

import SwiftUI

struct GalleryGridView: View {
    @Binding var webSiteDocument: WebSiteDocument
    @State var active: GalleryDocument?

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 300, maximum: .infinity))
            ]) {
                ReorderableForEach($webSiteDocument.galleries, active: $active)
                {
                    $galleryDocument in
                    GalleryDocumentTile(galleryDocument: $galleryDocument,
                                        galleries: $webSiteDocument.galleries)
                } moveAction: { from, to in
                    webSiteDocument.galleries.move(
                        fromOffsets: from, toOffset: to)
                }
            }.padding()
        }
        .scrollContentBackground(.hidden)
        .reorderableForEachContainer(active: $active)
        .toolbar {
            ToolbarItem {
                Button(
                    action: addGallery,
                    label: {
                        Label("Add", systemImage: "plus")
                    })
            }
        }
        .navigationTitle("Galleries")
    }
    //
    //    var shape: some Shape {
    //        RoundedRectangle(cornerRadius: 20)
    //    }
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
}

#Preview {
    GalleryGridView(webSiteDocument: .constant(WebSiteDocument.mock))
}
