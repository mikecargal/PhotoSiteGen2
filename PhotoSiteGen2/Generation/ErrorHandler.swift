//
//  ErrorHandler.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 1/9/24.
//

protocol ErrorHandler: Sendable {
    func handleError(_ context: String, _ error: Error) async -> Void
}
