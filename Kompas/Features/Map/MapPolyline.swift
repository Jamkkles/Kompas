import SwiftUI
import MapKit

struct MapPolylineOverlay: MapContent {
    let polyline: MKPolyline
    let strokeStyle: StrokeStyle
    let color: Color
    
    init(_ polyline: MKPolyline, strokeStyle: StrokeStyle = StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round), color: Color = .blue) {
        self.polyline = polyline
        self.strokeStyle = strokeStyle
        self.color = color
    }
    
    var body: some MapContent {
        MapPolyline(coordinates: polyline.coordinates)
            .stroke(color, style: strokeStyle)
    }
}

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}