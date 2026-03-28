import CoreLocation
import SwiftUI

struct InteractiveGlobeView: View {
    @ObservedObject var viewModel: TimeMapViewModel

    @State private var rotation = GlobeRotation(longitude: -18, latitude: 12)
    @State private var dragStartRotation: GlobeRotation?
    @State private var isDragging = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            GeometryReader { proxy in
                let size = min(proxy.size.width, proxy.size.height)
                let radius = size * 0.40
                let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)

                ZStack {
                    Color.clear

                    GlobeBackdrop()
                        .frame(width: proxy.size.width, height: proxy.size.height)

                    GlobeSelectionHalo(
                        selectedCoordinate: viewModel.selectedMapCoordinate,
                        rotation: rotation,
                        center: center,
                        radius: radius
                    )

                    GlobeSurface(
                        rotation: rotation,
                        center: center,
                        radius: radius,
                        isDragging: isDragging
                    )
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if dragStartRotation == nil {
                                dragStartRotation = rotation
                            }

                            let distance = hypot(value.translation.width, value.translation.height)
                            if distance > 4 {
                                isDragging = true
                            }

                            if let start = dragStartRotation {
                                rotation = start.applying(
                                    translation: value.translation,
                                    in: CGSize(width: radius * 2, height: radius * 2)
                                )
                            }
                        }
                        .onEnded { value in
                            defer {
                                dragStartRotation = nil
                                isDragging = false
                            }

                            let distance = hypot(value.translation.width, value.translation.height)
                            guard distance < 8 else {
                                return
                            }

                            let localPoint = value.location
                            if let coordinate = GlobeProjection.coordinate(
                                for: localPoint,
                                center: center,
                                radius: radius,
                                rotation: rotation
                            ) {
                                viewModel.handleMapTap(at: coordinate)
                            }
                        }
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .timeMapGlass(cornerRadius: 30, tint: TimeMapGradient.aurora)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Explore the globe")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                Text("Drag to rotate, then tap the Earth to choose a nearby city.")
                    .font(.subheadline)
                    .foregroundStyle(TimeMapPalette.mutedCloud)
            }

            Spacer(minLength: 12)

            Label("Interactive", systemImage: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.10))
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                        )
                )
        }
    }
}

private struct GlobeBackdrop: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.18),
                            Color.clear,
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )

            Circle()
                .fill(TimeMapPalette.cyan.opacity(0.18))
                .frame(width: 220, height: 220)
                .blur(radius: 50)
                .offset(x: 78, y: -44)

            Circle()
                .fill(TimeMapPalette.violet.opacity(0.16))
                .frame(width: 190, height: 190)
                .blur(radius: 42)
                .offset(x: -90, y: 68)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct GlobeSurface: View {
    let rotation: GlobeRotation
    let center: CGPoint
    let radius: CGFloat
    let isDragging: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(TimeMapPalette.cyan.opacity(0.18))
                .frame(width: radius * 2.32, height: radius * 2.32)
                .blur(radius: 34)

            Canvas { context, size in
                let rect = CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                let sphere = Path(ellipseIn: rect)

                context.fill(
                    sphere,
                    with: .radialGradient(
                        Gradient(colors: [
                            Color(red: 0.35, green: 0.72, blue: 0.95),
                            Color(red: 0.12, green: 0.38, blue: 0.76),
                            Color(red: 0.04, green: 0.14, blue: 0.34)
                        ]),
                        center: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.minY + rect.height * 0.30),
                        startRadius: 6,
                        endRadius: radius * 1.08
                    )
                )

                context.fill(
                    sphere,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 0.08, green: 0.26, blue: 0.46).opacity(0.22),
                            Color.clear,
                            Color(red: 0.20, green: 0.58, blue: 0.86).opacity(0.18)
                        ]),
                        startPoint: CGPoint(x: rect.minX, y: rect.midY),
                        endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                    )
                )

                context.stroke(
                    sphere,
                    with: .color(Color.white.opacity(0.18)),
                    lineWidth: 1.2
                )

                for latitude in stride(from: -60.0, through: 60.0, by: 20.0) {
                    if let path = GlobeProjection.latitudeLine(
                        latitude: latitude,
                        rotation: rotation,
                        center: center,
                        radius: radius
                    ) {
                        context.stroke(path, with: .color(Color.white.opacity(0.06)), lineWidth: 0.7)
                    }
                }

                for longitude in stride(from: -150.0, through: 150.0, by: 20.0) {
                    if let path = GlobeProjection.longitudeLine(
                        longitude: longitude,
                        rotation: rotation,
                        center: center,
                        radius: radius
                    ) {
                        context.stroke(path, with: .color(Color.white.opacity(0.05)), lineWidth: 0.6)
                    }
                }

                for landmass in GlobeLandmass.allCases {
                    let projected = landmass.projectedPolygons(
                        rotation: rotation,
                        center: center,
                        radius: radius
                    )

                    for polygon in projected {
                        context.fill(
                            polygon,
                            with: .linearGradient(
                                Gradient(colors: landmass.fillColors),
                                startPoint: landmass.gradientStart(in: rect),
                                endPoint: landmass.gradientEnd(in: rect)
                            )
                        )

                        context.stroke(
                            polygon,
                            with: .color(landmass.coastColor),
                            lineWidth: landmass.coastLineWidth
                        )
                    }
                }

                for shelf in GlobeShelfBand.allCases {
                    if let path = shelf.projectedPath(rotation: rotation, center: center, radius: radius) {
                        context.stroke(path, with: .color(shelf.color), lineWidth: shelf.lineWidth)
                    }
                }

                for cloud in GlobeCloudBand.allCases {
                    if let path = cloud.projectedPath(rotation: rotation, center: center, radius: radius) {
                        context.stroke(path, with: .color(Color.white.opacity(cloud.opacity)), lineWidth: cloud.lineWidth)
                    }
                }

                for iceCap in GlobeIceCap.allCases {
                    if let path = iceCap.projectedPath(rotation: rotation, center: center, radius: radius) {
                        context.fill(path, with: .color(Color.white.opacity(iceCap.opacity)))
                    }
                }

                context.addFilter(.shadow(color: Color.black.opacity(0.28), radius: 16, x: 0, y: 10))
                context.fill(
                    sphere,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.white.opacity(0.04),
                            Color.clear,
                            Color.black.opacity(0.28)
                        ]),
                        startPoint: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.18),
                        endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                    )
                )

                let atmosphere = Path(ellipseIn: rect.insetBy(dx: -8, dy: -8))
                context.stroke(
                    atmosphere,
                    with: .color(Color(red: 0.62, green: 0.84, blue: 1.0).opacity(0.12)),
                    lineWidth: 8
                )
            }

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.24), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: radius * 1.42, height: radius * 0.84)
                .offset(x: -radius * 0.18, y: -radius * 0.26)
                .blur(radius: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scaleEffect(isDragging ? 0.992 : 1)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isDragging)
    }
}

private struct GlobeSelectionHalo: View {
    let selectedCoordinate: CLLocationCoordinate2D?
    let rotation: GlobeRotation
    let center: CGPoint
    let radius: CGFloat

    var body: some View {
        if let selectedCoordinate,
           let point = GlobeProjection.project(
                latitude: selectedCoordinate.latitude,
                longitude: selectedCoordinate.longitude,
                rotation: rotation,
                center: center,
                radius: radius
           ) {
            ZStack {
                Circle()
                    .fill(TimeMapPalette.sunrise.opacity(0.22))
                    .frame(width: 30, height: 30)
                    .blur(radius: 10)

                Circle()
                    .fill(TimeMapPalette.sunrise)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.92), lineWidth: 2)
                    )
            }
            .position(point)
        }
    }
}

private struct GlobeRotation {
    var longitude: Double
    var latitude: Double

    func applying(translation: CGSize, in size: CGSize) -> GlobeRotation {
        let longitudeDelta = Double(translation.width / max(size.width, 1)) * 180
        let latitudeDelta = Double(translation.height / max(size.height, 1)) * 120

        return GlobeRotation(
            longitude: longitude - longitudeDelta,
            latitude: (latitude + latitudeDelta).clamped(to: -70...70)
        )
    }
}

private enum GlobeProjection {
    static func project(
        latitude: Double,
        longitude: Double,
        rotation: GlobeRotation,
        center: CGPoint,
        radius: CGFloat
    ) -> CGPoint? {
        let vector = rotatedVector(latitude: latitude, longitude: longitude, rotation: rotation)
        guard vector.z >= 0 else {
            return nil
        }

        return CGPoint(
            x: center.x + CGFloat(vector.x) * radius,
            y: center.y - CGFloat(vector.y) * radius
        )
    }

    static func coordinate(
        for point: CGPoint,
        center: CGPoint,
        radius: CGFloat,
        rotation: GlobeRotation
    ) -> CLLocationCoordinate2D? {
        let normalizedX = Double((point.x - center.x) / radius)
        let normalizedY = Double((center.y - point.y) / radius)
        let distanceSquared = normalizedX * normalizedX + normalizedY * normalizedY

        guard distanceSquared <= 1 else {
            return nil
        }

        let z = sqrt(max(0, 1 - distanceSquared))
        let surface = SIMD3<Double>(normalizedX, normalizedY, z)
        let unrotated = inverseRotate(surface, rotation: rotation)

        let latitude = asin(unrotated.y).degrees
        let longitude = atan2(unrotated.x, unrotated.z).degrees
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static func latitudeLine(
        latitude: Double,
        rotation: GlobeRotation,
        center: CGPoint,
        radius: CGFloat
    ) -> Path? {
        sampledPath(
            values: stride(from: -180.0, through: 180.0, by: 6).map {
                project(latitude: latitude, longitude: $0, rotation: rotation, center: center, radius: radius)
            }
        )
    }

    static func longitudeLine(
        longitude: Double,
        rotation: GlobeRotation,
        center: CGPoint,
        radius: CGFloat
    ) -> Path? {
        sampledPath(
            values: stride(from: -80.0, through: 80.0, by: 4).map {
                project(latitude: $0, longitude: longitude, rotation: rotation, center: center, radius: radius)
            }
        )
    }

    static func sampledPath(values: [CGPoint?]) -> Path? {
        var path = Path()
        var started = false

        for point in values {
            if let point {
                if !started {
                    path.move(to: point)
                    started = true
                } else {
                    path.addLine(to: point)
                }
            } else {
                started = false
            }
        }

        return started ? path : nil
    }

    private static func rotatedVector(latitude: Double, longitude: Double, rotation: GlobeRotation) -> SIMD3<Double> {
        let lat = latitude.radians
        let lon = longitude.radians

        var vector = SIMD3<Double>(
            cos(lat) * sin(lon),
            sin(lat),
            cos(lat) * cos(lon)
        )

        vector = rotateY(vector, angle: -rotation.longitude.radians)
        vector = rotateX(vector, angle: rotation.latitude.radians)
        return vector
    }

    private static func inverseRotate(_ vector: SIMD3<Double>, rotation: GlobeRotation) -> SIMD3<Double> {
        let unpitched = rotateX(vector, angle: -rotation.latitude.radians)
        return rotateY(unpitched, angle: rotation.longitude.radians)
    }

    private static func rotateX(_ vector: SIMD3<Double>, angle: Double) -> SIMD3<Double> {
        let c = cos(angle)
        let s = sin(angle)
        return SIMD3<Double>(
            vector.x,
            vector.y * c - vector.z * s,
            vector.y * s + vector.z * c
        )
    }

    private static func rotateY(_ vector: SIMD3<Double>, angle: Double) -> SIMD3<Double> {
        let c = cos(angle)
        let s = sin(angle)
        return SIMD3<Double>(
            vector.x * c + vector.z * s,
            vector.y,
            -vector.x * s + vector.z * c
        )
    }
}

private enum GlobeLandmass: CaseIterable {
    case northAmerica
    case centralAmerica
    case southAmerica
    case greenland
    case europe
    case africa
    case asia
    case arabiaIndia
    case southeastAsia
    case australia
    case madagascar
    case japan

    var polygons: [[(Double, Double)]] {
        switch self {
        case .northAmerica:
            [[
                (72, -168), (70, -150), (64, -136), (58, -126), (51, -124), (47, -130),
                (40, -124), (33, -117), (26, -112), (23, -102), (27, -96), (30, -90),
                (26, -83), (18, -82), (16, -88), (20, -97), (25, -108), (31, -114),
                (42, -119), (53, -126), (60, -138), (66, -150)
            ]]
        case .centralAmerica:
            [[
                (22, -98), (19, -92), (18, -88), (16, -86), (14, -83), (12, -81),
                (10, -79), (9, -77), (8, -79), (9, -83), (12, -86), (16, -90)
            ]]
        case .southAmerica:
            [[
                (12, -81), (8, -78), (3, -76), (-4, -73), (-12, -71), (-20, -69),
                (-31, -66), (-42, -67), (-53, -72), (-55, -66), (-47, -58), (-35, -54),
                (-20, -52), (-8, -54), (2, -60), (9, -68)
            ]]
        case .greenland:
            [[
                (83, -58), (78, -42), (74, -28), (68, -22), (62, -30), (60, -44), (67, -56)
            ]]
        case .europe:
            [[
                (71, -11), (67, 2), (61, 12), (57, 22), (53, 30), (47, 32),
                (44, 23), (46, 14), (50, 6), (54, 0), (60, -6), (66, -10)
            ]]
        case .africa:
            [[
                (35, -17), (31, -6), (28, 4), (22, 16), (14, 26), (6, 32),
                (-6, 36), (-16, 33), (-25, 26), (-32, 18), (-34, 8), (-31, -2),
                (-23, -10), (-12, -14), (-2, -10), (9, -4), (20, 2), (28, 10)
            ]]
        case .asia:
            [[
                (70, 28), (66, 42), (62, 58), (58, 76), (53, 96), (48, 116),
                (42, 132), (32, 142), (22, 138), (18, 122), (22, 104), (28, 90),
                (34, 76), (40, 62), (44, 50), (50, 38), (58, 32), (65, 30)
            ]]
        case .arabiaIndia:
            [[
                (29, 39), (24, 49), (19, 57), (15, 67), (11, 77), (8, 85),
                (14, 88), (20, 82), (24, 73), (26, 63), (31, 54), (33, 46)
            ]]
        case .southeastAsia:
            [[
                (18, 96), (12, 103), (7, 109), (2, 115), (4, 122), (10, 123),
                (15, 118), (18, 111), (20, 104)
            ]]
        case .australia:
            [[
                (-12, 112), (-16, 121), (-22, 132), (-28, 143), (-37, 151),
                (-43, 145), (-44, 133), (-39, 120), (-31, 113), (-21, 110)
            ]]
        case .madagascar:
            [[
                (-14, 47), (-18, 49), (-22, 50), (-26, 48), (-24, 45), (-18, 44)
            ]]
        case .japan:
            [[
                (44, 141), (39, 143), (35, 139), (31, 136), (33, 132), (38, 136)
            ]]
        }
    }

    var fillColors: [Color] {
        switch self {
        case .northAmerica, .europe:
            return [
                Color(red: 0.56, green: 0.75, blue: 0.41),
                Color(red: 0.36, green: 0.56, blue: 0.28),
                Color(red: 0.26, green: 0.40, blue: 0.21)
            ]
        case .centralAmerica, .southAmerica, .southeastAsia:
            return [
                Color(red: 0.47, green: 0.73, blue: 0.36),
                Color(red: 0.29, green: 0.52, blue: 0.22),
                Color(red: 0.20, green: 0.36, blue: 0.17)
            ]
        case .africa, .arabiaIndia, .australia, .madagascar:
            return [
                Color(red: 0.76, green: 0.66, blue: 0.42),
                Color(red: 0.57, green: 0.48, blue: 0.26),
                Color(red: 0.35, green: 0.31, blue: 0.16)
            ]
        case .asia:
            return [
                Color(red: 0.64, green: 0.72, blue: 0.40),
                Color(red: 0.45, green: 0.52, blue: 0.25),
                Color(red: 0.31, green: 0.37, blue: 0.18)
            ]
        case .greenland, .japan:
            return [
                Color(red: 0.84, green: 0.86, blue: 0.80),
                Color(red: 0.60, green: 0.66, blue: 0.58),
                Color(red: 0.42, green: 0.47, blue: 0.39)
            ]
        }
    }

    var coastColor: Color {
        switch self {
        case .greenland:
            return Color.white.opacity(0.26)
        default:
            return Color(red: 0.90, green: 0.96, blue: 0.82).opacity(0.18)
        }
    }

    var coastLineWidth: CGFloat {
        switch self {
        case .japan, .madagascar:
            return 0.8
        default:
            return 1
        }
    }

    func gradientStart(in rect: CGRect) -> CGPoint {
        switch self {
        case .northAmerica, .greenland, .southAmerica:
            return CGPoint(x: rect.minX, y: rect.minY)
        case .europe, .africa, .asia, .arabiaIndia, .southeastAsia, .japan, .madagascar, .australia:
            return CGPoint(x: rect.midX, y: rect.minY)
        case .centralAmerica:
            return CGPoint(x: rect.minX, y: rect.midY)
        }
    }

    func gradientEnd(in rect: CGRect) -> CGPoint {
        switch self {
        case .northAmerica, .greenland, .southAmerica, .centralAmerica:
            return CGPoint(x: rect.maxX, y: rect.maxY)
        case .europe, .africa:
            return CGPoint(x: rect.midX, y: rect.maxY)
        case .asia, .arabiaIndia, .southeastAsia, .japan, .madagascar, .australia:
            return CGPoint(x: rect.maxX, y: rect.midY)
        }
    }

    func projectedPolygons(rotation: GlobeRotation, center: CGPoint, radius: CGFloat) -> [Path] {
        polygons.compactMap { polygon in
            let points = polygon.compactMap {
                GlobeProjection.project(
                    latitude: $0.0,
                    longitude: $0.1,
                    rotation: rotation,
                    center: center,
                    radius: radius
                )
            }

            guard points.count >= 3 else {
                return nil
            }

            var path = Path()
            path.move(to: points[0])
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.closeSubpath()
            return path
        }
    }
}

private enum GlobeShelfBand: CaseIterable {
    case atlantic
    case indian
    case pacific

    var coordinates: [(Double, Double)] {
        switch self {
        case .atlantic:
            return stride(from: 58.0, through: -56.0, by: -4).map { latitude in
                let longitude = latitude > 0 ? -28 + (58 - latitude) * 0.4 : -10 + abs(latitude) * 0.3
                return (latitude, longitude)
            }
        case .indian:
            return stride(from: 30.0, through: -44.0, by: -4).map { latitude in
                (latitude, 72 - latitude * 0.2)
            }
        case .pacific:
            return stride(from: 48.0, through: -34.0, by: -4).map { latitude in
                (latitude, 162 - latitude * 0.18)
            }
        }
    }

    var color: Color {
        switch self {
        case .atlantic:
            return Color(red: 0.74, green: 0.90, blue: 1.0).opacity(0.08)
        case .indian:
            return Color(red: 0.58, green: 0.83, blue: 0.96).opacity(0.08)
        case .pacific:
            return Color(red: 0.52, green: 0.78, blue: 0.94).opacity(0.06)
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .atlantic:
            return 2.2
        case .indian, .pacific:
            return 1.8
        }
    }

    func projectedPath(rotation: GlobeRotation, center: CGPoint, radius: CGFloat) -> Path? {
        GlobeProjection.sampledPath(
            values: coordinates.map {
                GlobeProjection.project(
                    latitude: $0.0,
                    longitude: $0.1,
                    rotation: rotation,
                    center: center,
                    radius: radius
                )
            }
        )
    }
}

private enum GlobeCloudBand: CaseIterable {
    case northAtlantic
    case equatorial
    case southOcean

    var coordinates: [(Double, Double)] {
        switch self {
        case .northAtlantic:
            return stride(from: -60.0, through: 40.0, by: 4).map { longitude in
                (24 + sin(longitude.radians) * 5, longitude)
            }
        case .equatorial:
            return stride(from: -180.0, through: 180.0, by: 5).map { longitude in
                (3 + cos((longitude * 1.6).radians) * 4, longitude)
            }
        case .southOcean:
            return stride(from: -180.0, through: 180.0, by: 6).map { longitude in
                (-48 + sin((longitude * 1.4).radians) * 3, longitude)
            }
        }
    }

    var opacity: Double {
        switch self {
        case .northAtlantic:
            return 0.10
        case .equatorial:
            return 0.08
        case .southOcean:
            return 0.06
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .northAtlantic:
            return 3.2
        case .equatorial:
            return 2.8
        case .southOcean:
            return 2.6
        }
    }

    func projectedPath(rotation: GlobeRotation, center: CGPoint, radius: CGFloat) -> Path? {
        GlobeProjection.sampledPath(
            values: coordinates.map {
                GlobeProjection.project(
                    latitude: $0.0,
                    longitude: $0.1,
                    rotation: rotation,
                    center: center,
                    radius: radius
                )
            }
        )
    }
}

private enum GlobeIceCap: CaseIterable {
    case north
    case south

    var polygon: [(Double, Double)] {
        switch self {
        case .north:
            return stride(from: -180.0, through: 180.0, by: 12).map { longitude in
                (76 + cos(longitude.radians) * 6, longitude)
            }
        case .south:
            return stride(from: -180.0, through: 180.0, by: 12).map { longitude in
                (-72 + cos(longitude.radians) * 4, longitude)
            }
        }
    }

    var opacity: Double {
        switch self {
        case .north:
            return 0.24
        case .south:
            return 0.18
        }
    }

    func projectedPath(rotation: GlobeRotation, center: CGPoint, radius: CGFloat) -> Path? {
        let points = polygon.compactMap {
            GlobeProjection.project(
                latitude: $0.0,
                longitude: $0.1,
                rotation: rotation,
                center: center,
                radius: radius
            )
        }

        guard points.count >= 3 else {
            return nil
        }

        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

private extension Double {
    var radians: Double { self * .pi / 180 }
    var degrees: Double { self * 180 / .pi }

    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
