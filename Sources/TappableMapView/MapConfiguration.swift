import MapKit

/// Configuration for the map view's appearance and behavior.
public struct MapConfiguration {
    public var region: MKCoordinateRegion?
    public var mapType: MKMapType
    public var isScrollEnabled: Bool
    public var isZoomEnabled: Bool
    public var isRotateEnabled: Bool
    public var showsUserLocation: Bool
    public var pointOfInterestFilter: MKPointOfInterestFilter?

    /// Create a map configuration.
    ///
    /// - Parameters:
    ///   - region: Initial map region. If nil, the map fits to show all overlays.
    ///   - mapType: Map display type (standard, satellite, hybrid, etc.).
    ///   - isScrollEnabled: Whether the user can scroll the map.
    ///   - isZoomEnabled: Whether the user can zoom the map.
    ///   - isRotateEnabled: Whether the user can rotate the map.
    ///   - showsUserLocation: Whether to show the user's location dot.
    ///   - pointOfInterestFilter: Filter for points of interest (pass `.excludingAll` for a clean map).
    public init(
        region: MKCoordinateRegion? = nil,
        mapType: MKMapType = .standard,
        isScrollEnabled: Bool = true,
        isZoomEnabled: Bool = true,
        isRotateEnabled: Bool = true,
        showsUserLocation: Bool = false,
        pointOfInterestFilter: MKPointOfInterestFilter? = .excludingAll
    ) {
        self.region = region
        self.mapType = mapType
        self.isScrollEnabled = isScrollEnabled
        self.isZoomEnabled = isZoomEnabled
        self.isRotateEnabled = isRotateEnabled
        self.showsUserLocation = showsUserLocation
        self.pointOfInterestFilter = pointOfInterestFilter
    }
}
