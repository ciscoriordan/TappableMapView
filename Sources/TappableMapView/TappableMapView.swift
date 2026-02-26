import MapKit
import SwiftUI
import UIKit

/// A SwiftUI view wrapping `MKMapView` with tappable polygon overlays.
///
/// Unlike Apple's native SwiftUI `Map` and third-party wrappers like
/// [pauljohanneskraft/Map](https://github.com/pauljohanneskraft/Map),
/// this view supports **true polygon tap detection** by using a
/// `UITapGestureRecognizer` and hit-testing each `MKPolygonRenderer`.
///
/// ```swift
/// TappableMapView(
///     polygons: myPolygons,
///     configuration: MapConfiguration(mapType: .standard),
///     onPolygonTapped: { polygon in
///         print("Tapped: \(polygon.title ?? "unknown")")
///     }
/// )
/// ```
public struct TappableMapView: UIViewRepresentable {
    public let polygons: [TappablePolygon]
    public let annotations: [TappableAnnotation]
    public let configuration: MapConfiguration
    public let onPolygonTapped: ((TappablePolygon) -> Void)?
    public let onPolygonTappedAt: ((TappablePolygon, CGPoint) -> Void)?

    /// Create a tappable map view.
    ///
    /// - Parameters:
    ///   - polygons: Polygon overlays to display and make tappable.
    ///   - annotations: Optional point annotations.
    ///   - configuration: Map display and interaction settings.
    ///   - onPolygonTapped: Callback fired when the user taps inside a polygon.
    ///   - onPolygonTappedAt: Callback fired with the polygon and tap point in the view's coordinate space.
    public init(
        polygons: [TappablePolygon],
        annotations: [TappableAnnotation] = [],
        configuration: MapConfiguration = MapConfiguration(),
        onPolygonTapped: ((TappablePolygon) -> Void)? = nil,
        onPolygonTappedAt: ((TappablePolygon, CGPoint) -> Void)? = nil
    ) {
        self.polygons = polygons
        self.annotations = annotations
        self.configuration = configuration
        self.onPolygonTapped = onPolygonTapped
        self.onPolygonTappedAt = onPolygonTappedAt
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        // Interaction settings
        mapView.isScrollEnabled = configuration.isScrollEnabled
        mapView.isZoomEnabled = configuration.isZoomEnabled
        mapView.isRotateEnabled = configuration.isRotateEnabled
        mapView.isPitchEnabled = false
        mapView.showsUserLocation = configuration.showsUserLocation
        mapView.mapType = configuration.mapType
        mapView.pointOfInterestFilter = configuration.pointOfInterestFilter

        // Tap gesture for polygon hit-testing
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tap)

        return mapView
    }

    public func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parent = self

        // Update overlays
        mapView.removeOverlays(mapView.overlays)
        for polygon in polygons {
            for overlay in polygon.overlays {
                mapView.addOverlay(overlay)
            }
        }

        // Update annotations
        let existing = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existing)
        for annotation in annotations {
            let pin = MKPointAnnotation()
            pin.coordinate = annotation.coordinate
            pin.title = annotation.title
            mapView.addAnnotation(pin)
        }

        // Fit to overlays if no explicit region
        if configuration.region != nil {
            mapView.setRegion(configuration.region!, animated: false)
        } else if !polygons.isEmpty {
            let rect = polygons
                .flatMap(\.overlays)
                .map(\.boundingMapRect)
                .reduce(MKMapRect.null) { $0.union($1) }

            if !rect.isNull {
                mapView.setVisibleMapRect(
                    rect,
                    edgePadding: UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30),
                    animated: false
                )
            }
        }
    }

    // MARK: - Coordinator

    public class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TappableMapView

        init(parent: TappableMapView) {
            self.parent = parent
        }

        // MARK: Overlay rendering

        public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // Find the TappablePolygon that owns this overlay
            let style = parent.polygons.first { tp in
                tp.overlays.contains { $0 === overlay }
            }

            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = style?.fillColor ?? UIColor.systemTeal.withAlphaComponent(0.25)
                renderer.strokeColor = style?.strokeColor ?? .systemTeal
                renderer.lineWidth = style?.lineWidth ?? 1.5
                return renderer
            }

            if let multi = overlay as? MKMultiPolygon {
                let renderer = MKMultiPolygonRenderer(multiPolygon: multi)
                renderer.fillColor = style?.fillColor ?? UIColor.systemTeal.withAlphaComponent(0.25)
                renderer.strokeColor = style?.strokeColor ?? .systemTeal
                renderer.lineWidth = style?.lineWidth ?? 1.5
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }

        // MARK: Tap handling

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let mapPoint = MKMapPoint(mapView.convert(point, toCoordinateFrom: mapView))

            // Test each polygon's renderer to see if the tap point falls inside
            for tappable in parent.polygons {
                for overlay in tappable.overlays {
                    let renderer = mapView.renderer(for: overlay)

                    if let polygonRenderer = renderer as? MKPolygonRenderer {
                        let rendererPoint = polygonRenderer.point(for: mapPoint)
                        if polygonRenderer.path?.contains(rendererPoint) == true {
                            parent.onPolygonTapped?(tappable)
                            parent.onPolygonTappedAt?(tappable, point)
                            return
                        }
                    }

                    if let multiRenderer = renderer as? MKMultiPolygonRenderer {
                        let rendererPoint = multiRenderer.point(for: mapPoint)
                        if multiRenderer.path?.contains(rendererPoint) == true {
                            parent.onPolygonTapped?(tappable)
                            parent.onPolygonTappedAt?(tappable, point)
                            return
                        }
                    }
                }
            }
        }

        // MARK: Annotation views

        public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }

            let identifier = "TappableAnnotation"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)

            view.annotation = annotation
            view.canShowCallout = true

            // Small colored dot
            let dot = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
            dot.backgroundColor = .systemTeal
            dot.layer.cornerRadius = 4

            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
            view.image = renderer.image { ctx in
                UIColor.systemTeal.setFill()
                ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: 8, height: 8))
            }
            view.centerOffset = .zero

            return view
        }
    }
}
