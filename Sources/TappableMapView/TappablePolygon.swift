import MapKit
import UIKit

/// A polygon overlay with associated metadata and visual style, supporting tap interaction.
public struct TappablePolygon: Identifiable {
    public let id: AnyHashable
    public let overlays: [MKOverlay]
    public let fillColor: UIColor
    public let strokeColor: UIColor
    public let lineWidth: CGFloat
    public let title: String?

    /// Create a tappable polygon from one or more MKOverlay objects.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for this polygon group.
    ///   - overlays: The `MKPolygon` or `MKMultiPolygon` overlays to render.
    ///   - fillColor: Fill color for the polygon interior.
    ///   - strokeColor: Stroke color for the polygon border.
    ///   - lineWidth: Border line width in points.
    ///   - title: Optional display title.
    public init(
        id: AnyHashable,
        overlays: [MKOverlay],
        fillColor: UIColor = UIColor.systemTeal.withAlphaComponent(0.25),
        strokeColor: UIColor = .systemTeal,
        lineWidth: CGFloat = 1.5,
        title: String? = nil
    ) {
        self.id = id
        self.overlays = overlays
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
        self.title = title
    }
}

/// A simple annotation with a coordinate and optional title.
public struct TappableAnnotation: Identifiable {
    public let id: AnyHashable
    public let coordinate: CLLocationCoordinate2D
    public let title: String?

    public init(id: AnyHashable, coordinate: CLLocationCoordinate2D, title: String? = nil) {
        self.id = id
        self.coordinate = coordinate
        self.title = title
    }
}
