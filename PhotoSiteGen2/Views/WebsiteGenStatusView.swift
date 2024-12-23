//
//  WebsiteGenStatusView.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/25/24.
//
import SwiftUI

struct WebsiteGenStatusView: View {
    var wsGenStatus: WebsiteGenerationStatus
    var body: some View {
        List {
            HStack {
                Text("Status: \( wsGenStatus.status.description)")
                wsGenStatus.view
            }
            Section {
                ForEach(
                    wsGenStatus.galleryStatuses
                        .sorted(by: { $0.status.rawValue < $1.status.rawValue }
                        ), id: \.id
                ) { gStatus in
                    HStack {
                        Text(
                            "\(gStatus.galleryName): "
                        ).frame(
                            minWidth: 200,
                            maxWidth: .infinity,
                            alignment: .leading)
                        Spacer()
                        gStatus.view
                    }
                }
            } header: {
                Text("Galleries")
            }
        }
        .frame(minWidth: 500, minHeight: 500)
        if wsGenStatus.status == .generatingWithErrors
            || wsGenStatus.status == .completeWithErrors
        {
            TextEditor(text: .constant(gatherErrors().joined(separator: "\n")))
                .frame(height: 100)
                .padding()
        }
    }

    func gatherErrors() -> [String] {
        var errors: [String] = wsGenStatus.errors
        for gStatus in wsGenStatus.galleryStatuses {
            if gStatus.status == .generatingWithErrors
                || gStatus.status == .completeWithErrors
            {
                errors.append("=== \(gStatus.galleryName) ===")
                errors.append(contentsOf: gStatus.errors)
            }
        }
        return errors
    }

}
