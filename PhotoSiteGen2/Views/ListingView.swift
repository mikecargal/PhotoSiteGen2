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
                    ForEach(
                        $websiteDocument.galleries, editActions: .move //,
//                        selection: $selection
                    ) { $galleryDocument in
                        NavigationLink(
                            value: DetailViewEnum.gallerySelection(
                                id: galleryDocument.id)
                        ) {
                            Text(galleryDocument.title)
                                .contextMenu {
                                    Button("Delete") {
                                        deleteGallery(galleryDocument)
                                    }
                                }
                                .padding(.leading, 20)
                        }
                        //                        NavigationLink(
                        //                            destination: DetailViewEnum.gallerySelelection(id: $galleryDocument.id)
                        //                        ) {
                        //                            Text(galleryDocument.title)
                        //                                .contextMenu {
                        //                                    Button("Delete") {
                        //                                        deleteGallery(galleryDocument)
                        //                                    }
                        //                                }
                        //                        }
                    }
//                    .onDelete(perform: deleteGallery)
                   
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
            //        .toolbar {
            //            Button("Add Gallery", systemImage: "plus", action: addGallery)
            //        }
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
        print("deleting gallery with is: \(gallery.id)")
        let deletionIndex = websiteDocument.galleries.firstIndex(of: gallery)
        if gallery == websiteDocument.galleries.last {
            selection = DetailViewEnum.gallerySelection(id: websiteDocument.galleries[deletionIndex!.advanced(by: -1)].id)
        } else {
            selection = DetailViewEnum.gallerySelection(id: websiteDocument.galleries[deletionIndex!.advanced(by: 1)].id)
        }
        $websiteDocument.galleries.wrappedValue.removeAll {
            $0.id == gallery.id
        }
        debugPrint($websiteDocument.galleries)
//        selection = nil
    }
}

#Preview {
    ListingView(websiteDocument: .constant(WebSiteDocument.mock), selection: .constant(nil))
}
