//
//  Photo.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 12/15/23.
//

import AppKit
import Foundation

enum PhotoReadError: Error {
    case ImageSourceUnreachable(url: URL)
    case ImageSourceReadError(url: URL)
}

struct Photo: Identifiable, Comparable, Sendable, Codable {
    let modDate: Date?
    let url: URL

    let aspectRatio: Double
    let metadata: ImageMetaData

    var id: String { url.absoluteString }

    var smallImageURL: URL {
        url.deletingLastPathComponent()
            .appendingPathComponent("w0512")
            .appendingPathComponent(url.lastPathComponent)
    }

    var smallImage: CGImage? {
        guard
            let smallImageSource = CGImageSourceCreateWithURL(
                smallImageURL as CFURL, nil)
        else { return nil }
        return CGImageSourceCreateImageAtIndex(smallImageSource, 0, nil)!
    }

    static func == (lhs: Photo, rhs: Photo) -> Bool {
        return lhs.filteredFileName() == rhs.filteredFileName()
    }

    static func < (lhs: Photo, rhs: Photo) -> Bool {
        let lhStar = lhs.metadata.starRating
        let rhStar = rhs.metadata.starRating
        if lhStar != rhStar {
            return lhStar > rhStar
        }
        let lhDate = lhs.metadata.captureTime ?? ""
        let rhDate = rhs.metadata.captureTime ?? ""
        if lhDate != rhDate {
            return lhDate < rhDate
        }
        return lhs.filteredFileName() < rhs.filteredFileName()
    }

    func filteredFileName() -> String {
        Self.filteredFileName(url)
    }

    func filteredFileNameWithExtension() -> String {
        Self.filteredFileNameWithExtension(url)
    }

    func srcset(genName: String) -> String {
        let imgName = filteredFileNameWithExtension()
        return
            "\(genName)\\w0512\\\(imgName) 512w, \(genName)\\w1024\\\(imgName) 1024w, \(genName)\\w2048\\\(imgName) 2048w, \(genName)\\\(imgName)"
    }

    func smallImageSrc(genName: String) -> String {
        let imgName = filteredFileNameWithExtension()
        return "\(genName)\\w0512\\\(imgName)"
    }

    static func filteredFileName(_ url: URL) -> String {
        let inParts = url.deletingPathExtension().lastPathComponent.split(
            separator: "-")

        var rest = inParts[1..<inParts.endIndex]
            .filter {
                $0.count < 3  // sequence numbers 2 digits at most (other will be date that Dxo puts on it)
                    && CharacterSet.decimalDigits.isSuperset(
                        of: CharacterSet(charactersIn: String($0)))
            }
        rest.insert(inParts.first!, at: 0)

        return rest.joined(separator: "-")
    }

    static func filteredFileNameWithExtension(_ url: URL?) -> String? {
        guard let url else { return nil }
        return filteredFileNameWithExtension(url)
    }

    static func filteredFileNameWithExtension(_ url: URL) -> String {
        return "\(Self.filteredFileName(url)).\(url.pathExtension)"
    }

    func heightOfImage(ofWidth width: Int) -> Int {
        return Int(ceil(Double(width) / aspectRatio))
    }
}

extension Photo {
    init(url: URL, genName: String) throws {
        self.url = url

        do {
            guard try url.checkResourceIsReachable() else {
                throw PhotoReadError.ImageSourceUnreachable(url: url)
            }
        } catch {
            throw PhotoReadError.ImageSourceReadError(url: url)
        }

        modDate =
            try url.resourceValues(forKeys: [.contentModificationDateKey])
            .contentModificationDate as Date?
        metadata = ImageMetaData(
            url: url, imgSrc: "\(genName)\\w0512\\\(Self.filteredFileNameWithExtension(url))")
        aspectRatio = Double(metadata.pixelWidth) / Double(metadata.pixelHeight)

        do {
            let siURL = smallImageURL
            guard try siURL.checkResourceIsReachable() else {
                throw PhotoReadError.ImageSourceUnreachable(url: url)
            }
        } catch {
            throw PhotoReadError.ImageSourceReadError(url: url)
        }

    }
}
