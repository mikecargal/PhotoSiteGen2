struct CropRepresentation: Codable {
    var originalRect: Rect
    var croppedRect: Rect
    let src: String

    func scaled(scale: Double) -> CropRepresentation {
        CropRepresentation(
            originalRect: originalRect.scaled(xScale: scale, yScale: scale),
            croppedRect: croppedRect.scaled(xScale: scale, yScale: scale),
            src: src)
    }

    func scaled(xScale: Double, yScale: Double) -> CropRepresentation {
        CropRepresentation(
            originalRect: originalRect.scaled(xScale: xScale, yScale: yScale),
            croppedRect: croppedRect.scaled(xScale: xScale, yScale: yScale),
            src: src)
    }

    func translated(xOffset: Double, yOffset: Double) -> CropRepresentation {
        CropRepresentation(
            originalRect: originalRect.translated(
                xTranslation: xOffset, yTranslation: yOffset),
            croppedRect: croppedRect.translated(
                xTranslation: xOffset, yTranslation: yOffset),
            src: src)
    }

    func rotated(aroundOrigin origin: Point, byRadians: Double)
        -> CropRepresentation
    {
        CropRepresentation(
            originalRect: originalRect.rotated(
                aroundOrigin: origin, byRadians: byRadians),
            croppedRect: croppedRect.rotated(
                aroundOrigin: origin, byRadians: byRadians),
            src: src)
    }

    func getSVG() -> String {
        func int(_ dbl: Double) -> Int {
            Int(ceil(dbl))
        }
        let doc = Document {
            Svg {
                Polygon([
                    originalRect.tl.x, originalRect.tl.y,
                    originalRect.tr.x, originalRect.tr.y,
                    originalRect.br.x, originalRect.br.y,
                    originalRect.bl.x, originalRect.bl.y,
                ])
                Polygon([
                    croppedRect.tl.x, croppedRect.tl.y,
                    croppedRect.tr.x, croppedRect.tr.y,
                    croppedRect.br.x, croppedRect.br.y,
                    croppedRect.bl.x, croppedRect.bl.y,
                ])
            }.width(int(originalRect.rWidth))
                .height(int(originalRect.rHeight))
                .viewBox(
                    minX: int(originalRect.minX), minY: int(originalRect.minY),
                    width: int(originalRect.rWidth),
                    height: int(originalRect.rHeight)
                )
                .fill("none")
                .stroke("black")
                .strokeWidth(1)
        }
        let renderer = DocumentRenderer(minify: false, indent: 4)

        return renderer.render(doc)
    }

    struct Point: Codable {
        var x, y: Double

        func scaled(xScale: Double, yScale: Double) -> Point {
            Point(x: x * xScale, y: y * yScale)
        }

        func translated(xTranslation: Double, yTranslation: Double) -> Point {
            Point(x: x + xTranslation, y: y + yTranslation)
        }

        func rotated(aroundOrigin origin: Point, byRadians: Double) -> Point {
            // https://stackoverflow.com/questions/35683376/rotating-a-cgpoint-around-another-cgpoint/35683523
            let dx = self.x - origin.x
            let dy = self.y - origin.y
            let radius = sqrt(dx * dx + dy * dy)
            let azimuth = atan2(dy, dx)
            let newAzimuth = azimuth + byRadians
            let x = origin.x + radius * cos(newAzimuth)
            let y = origin.y + radius * sin(newAzimuth)
            return Point(x: x, y: y)
        }
    }

    struct Rect: Codable {
        static let minDoubleValue: Double = -Double.infinity
        static let maxDoubleValue: Double = Double.infinity
        var tl, tr, br, bl: Point

        var center: Point {
            Point(
                x: (tl.x + tr.x + br.x + bl.x) / 4,
                y: (tl.y + tr.y + br.y + bl.y) / 4)
        }

        init(tl: Point, tr: Point, br: Point, bl: Point) {
            self.tl = tl
            self.tr = tr
            self.br = br
            self.bl = bl
        }

        init(tl: Point, br: Point) {
            self.tl = tl
            self.tr = Point(x: br.x, y: tl.y)
            self.br = br
            self.bl = Point(x: tl.x, y: br.y)
        }

        var width: Double { br.x - tl.x }
        var height: Double { br.y - tl.y }
        var minX: Double {
            [tl, tr, br, bl]
                .map(\.x)
                .reduce(Self.maxDoubleValue, Double.minimum)
        }
        var maxX: Double {
            [tl, tr, br, bl]
                .map(\.x)
                .reduce(Self.minDoubleValue, Double.maximum)
        }
        var minY: Double {
            [tl, tr, br, bl]
                .map(\.y)
                .reduce(Self.maxDoubleValue, Double.minimum)
        }
        var maxY: Double {
            [tl, tr, br, bl]
                .map(\.y)
                .reduce(Self.minDoubleValue, Double.maximum)
        }

        var rWidth: Double { maxX - minX }
        var rHeight: Double { maxY - minY }

        func scaled(xScale: Double, yScale: Double) -> Rect {
            Rect(
                tl: tl.scaled(xScale: xScale, yScale: yScale),
                tr: tr.scaled(xScale: xScale, yScale: yScale),
                br: br.scaled(xScale: xScale, yScale: yScale),
                bl: bl.scaled(xScale: xScale, yScale: yScale))
        }

        func translated(xTranslation: Double, yTranslation: Double) -> Rect {
            Rect(
                tl: tl.translated(
                    xTranslation: xTranslation, yTranslation: yTranslation),
                tr: tr.translated(
                    xTranslation: xTranslation, yTranslation: yTranslation),
                br: br.translated(
                    xTranslation: xTranslation, yTranslation: yTranslation),
                bl: bl.translated(
                    xTranslation: xTranslation, yTranslation: yTranslation))
        }

        func rotated(aroundOrigin origin: Point, byRadians: Double) -> Rect {
            Rect(
                tl: tl.rotated(aroundOrigin: origin, byRadians: byRadians),
                tr: tr.rotated(aroundOrigin: origin, byRadians: byRadians),
                br: br.rotated(aroundOrigin: origin, byRadians: byRadians),
                bl: bl.rotated(aroundOrigin: origin, byRadians: byRadians))
        }
    }

}
