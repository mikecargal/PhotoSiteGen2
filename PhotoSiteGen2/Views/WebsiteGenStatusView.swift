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
                    wsGenStatus.status.view
                }
                Section {
                    ForEach(wsGenStatus.galleryStatuses
                        .sorted(by: { $0.status.rawValue < $1.status.rawValue })) { gStatus in
                        HStack {
                            Text(
                                "\(gStatus.galleryName): \(gStatus.status.description)"
                            )
                            gStatus.status.view
                        }
                    }
                } header: {
                    Text("Galleries")
                }
            }
        .frame(minWidth: 300, minHeight: 300)
        if wsGenStatus.status == .generatingWithErrors ||
            wsGenStatus.status == .completeWithErrors{
            TextEditor(text: .constant(gatherErrors().joined(separator: "\n")))
                .frame(height: 100)
                .padding()
        }
    }

    func gatherErrors() -> [String] {
        var errors: [String] = wsGenStatus.errors
        for gStatus in wsGenStatus.galleryStatuses {
            if gStatus.status == .generatingWithErrors ||
                gStatus.status == .completeWithErrors {
                errors.append("=== \(gStatus.galleryName) ===")
                errors.append(contentsOf: gStatus.errors)
            }
        }
        return errors
    }
    
}
