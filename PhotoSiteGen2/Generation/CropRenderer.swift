struct CropRenderer {
    static let DEBUGGING = false
    private static let logger = Logger(
        subsystem: "com.mikecargal.photositegen2", category: "CropRenderer")

    enum Orientation: Int {
        case orient0 = 0
        case orient90 = 90
        case orient180 = 180
        case orient270 = 270
    }

    var imageW, imageH: Int
    var angle, cropTop, cropBottom, cropLeft, cropRight: Double
    var imageSrc: String
    var orientation: Orientation

    func getCropInfo(maxWH: Double) -> CropRenderInfo {

        let radAngle = deg2rad(angle)

        //  get the top, righ, bottom, and left appropriate
        //    to the rotation directive in the image tags
        //    "#rotate(0,90,180,270)" (or none = rotate 0 degrees)
        let (top, right, bottom, left) =
            switch orientation {
            case .orient0: (cropTop, cropRight, cropBottom, cropLeft)
            case .orient90: (cropRight, cropTop, cropLeft, cropBottom)
            case .orient180: (cropBottom, cropRight, cropTop, cropLeft)
            case .orient270: (cropLeft, cropBottom, cropRight, cropTop)
            }

        // calculate the original (uncropped) width and height
        let (unCroppedW, unCroppedH) = getUncroppedWH(
            top: top, bottom: bottom, left: left, right: right)

        // build representation prior to rotation
        var croppedRepresentation = CropRepresentation(
            originalRect: Rect(
                tl: Point(x: 0, y: 0), br: Point(x: 1, y: 1)),
            croppedRect: Rect(
                tl: Point(x: left, y: top),
                br: Point(x: right, y: bottom)
            ),
            src: imageSrc
        )
        .scaled(xScale: unCroppedW, yScale: unCroppedH)

        if Self.DEBUGGING {
            Self.logger.debug("\(croppedRepresentation.getSVG())")
        }

        // create a version of the cropped rect and rotate it the
        //  opposite direction of the eventual rotation
        //  (This "unrotates" (levels) the cropped Rect)
        croppedRepresentation = croppedRepresentation.rotated(
            aroundOrigin: croppedRepresentation.originalRect.center,
            byRadians: -radAngle)
        if Self.DEBUGGING {
            Self.logger.debug("\(croppedRepresentation.getSVG())")
        }

        // with crop level we can recalutate the tr, and bl
        //   using top-left and bottom-right
        let croppedRect: CropRepresentation.Rect =
            Rect(
                tl: croppedRepresentation.croppedRect.tl,
                br: croppedRepresentation.croppedRect.br)
        // update the croppedRect with the version with correct tr, and bl
        croppedRepresentation.croppedRect = croppedRect
        if Self.DEBUGGING {
            Self.logger.debug("\(croppedRepresentation.getSVG())")
        }

        var origRect = croppedRepresentation.originalRect

        // translate to minX = minY = 0
        //  (no points have a negative x or y)
        let tx = -origRect.minX
        let ty = -origRect.minY
        croppedRepresentation =
            croppedRepresentation
            .translated(xOffset: tx, yOffset: ty)
        if Self.DEBUGGING {
            Self.logger.debug("\(croppedRepresentation.getSVG())")
        }

        // scale to fit in maxWH x maxWH canvas
        let scaleToMaxWH =
            origRect.rWidth > origRect.rHeight
            ? maxWH / origRect.rWidth : maxWH / origRect.rHeight
        croppedRepresentation =
            croppedRepresentation
            .scaled(scale: scaleToMaxWH)
        if Self.DEBUGGING {
            Self.logger.debug(
                "origRect.rWidth: \(origRect.rWidth), origRect.rHeight: \(origRect.rHeight), scaleToMaxWH: \(scaleToMaxWH)"
            )
            Self.logger.debug("\(croppedRepresentation.getSVG())")
        }

        // translate to center vertically and horizontally
        origRect = croppedRepresentation.originalRect
        if origRect.rWidth > origRect.rHeight {
            croppedRepresentation =
                croppedRepresentation
                .translated(
                    xOffset: 0,
                    yOffset: (maxWH - origRect.rHeight) / 2)
        } else {
            croppedRepresentation =
                croppedRepresentation
                .translated(
                    xOffset: (maxWH - origRect.rWidth) / 2,
                    yOffset: 0)
        }
        if Self.DEBUGGING {
            Self.logger.debug("\(croppedRepresentation.getSVG())")
        }
        return CropRenderInfo(croppedRepresentation: croppedRepresentation)
    }

    func getUncroppedWH(
        top: Double,  // location of top as a percentage of the original height
        bottom: Double,  // location of bottom as a percentage of the original height
        left: Double,  // location of left side as a percentage of the original width
        right: Double  // location of right side as a percentage of the original width
    ) -> (w: Double, h: Double) {
        // create a full size version of the cropped Rect
        // and rotate it to "cropAngle"
        let rect = Rect(
            tl: Point(x: 0, y: 0),
            br: Point(x: Double(imageW), y: Double(imageH))
        )
        .rotated(aroundOrigin: Point(x: 0, y: 0), byRadians: deg2rad(angle))

        // NOTE: the top, and left are used to position the top-left vertex
        // and the bottom and right are used to locate the bottom-right vertex
        // depending upon the rotation, the y of top-left could actually be
        // lower than the y of the bottom-right location of these vertices
        // relative to the unrotated original image.  (And these values are plotted
        // against the unrotated original image)
        // This mean that either (or both) of the rotatedCropWidth and rotatedCropHeight
        // may actually be negative.  When this occurs the croppedHeightAsPercentageOfOriginal
        // (or the height), will also be negative (having something be a negative percentage
        // of the whole, seems odd, but once we divide the negative cropWidth by the negative
        // percentage, we get the correct, positive, width of the whole.
        let rotatedCropWidth = rect.br.x - rect.tl.x
        let rotatedCropHeight = rect.br.y - rect.tl.y

        let croppedWidthAsPercentageOfOriginal = right - left
        let croppedHeightAsPercentageOfOriginal = bottom - top

        return (
            w: rotatedCropWidth / croppedWidthAsPercentageOfOriginal,
            h: rotatedCropHeight / croppedHeightAsPercentageOfOriginal
        )
    }

    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }
}
