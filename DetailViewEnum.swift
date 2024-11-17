//
//  DetailViewEnum.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/14/24.
//

import SwiftUI

enum DetailViewEnum: Hashable {
    case siteConfiguration
    case gallerySelection(id: UUID)
    
    @ViewBuilder
    func viewForDocument(_ webSiteDocumentBinding: Binding<WebSiteDocument>) -> some View {
        switch self {
        case .gallerySelection(let id):
            GalleryEditView(
                galleryDocument: webSiteDocumentBinding.galleries.first(
                    where: { $0.id == id })!,
                webSiteDocument: webSiteDocumentBinding.wrappedValue)
        default:  // .siteConfiguration:
            SiteConfigEditView(websiteDocument: webSiteDocumentBinding)
        }
    }
}
