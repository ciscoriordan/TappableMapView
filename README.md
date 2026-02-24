# TappableMapView

A SwiftUI component that wraps `MKMapView` to provide **tappable polygon overlays** with proper hit-testing. Includes a GeoJSON parser for converting GeoJSON geometry into MapKit overlays.

## Why not use Apple's SwiftUI Map or pauljohanneskraft/Map?

**Apple's native SwiftUI `Map`** (iOS 17+) supports `MapPolygon` for rendering polygon overlays, but provides no built-in way to detect taps on those polygons. `MapPolygon` doesn't support tap gestures, selection, or any form of user interaction. You can tap annotations, but not shapes. If you need users to tap a polygon and identify which one they tapped, the native SwiftUI Map can't do it.

**[pauljohanneskraft/Map](https://github.com/pauljohanneskraft/Map)** is a SwiftUI wrapper for `MKMapView` that supports overlays via `MKOverlayRenderer`. However, it has the same fundamental limitation: `MKOverlayRenderer` is a **rendering** class, not an interaction class. It draws polygons on the map but doesn't handle touches. The library provides no tap-on-overlay callback, no hit-testing, and no way to determine which polygon the user tapped. You'd need to subclass the internal `MKMapView`, add your own gesture recognizer, and manually convert screen points to map coordinates for hit-testing — at which point you're bypassing the library entirely.

**TappableMapView** solves this by:
1. Wrapping `MKMapView` directly in a `UIViewRepresentable`
2. Adding a `UITapGestureRecognizer` to the map
3. Converting tap points to `MKMapPoint` coordinates
4. Calling `renderer.point(for:)` on each `MKPolygonRenderer` to transform into renderer-local coordinates
5. Testing `renderer.path?.contains(point)` for accurate hit detection
6. Firing an `onPolygonTapped` callback with the identified polygon

This gives you true polygon tap detection that works with complex shapes, multi-polygons, and overlapping regions.

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/TappableMapView", from: "1.0.0"),
]
```

Or add it as a local package in Xcode: File → Add Package Dependencies → Add Local.

## Usage

### Basic Example

```swift
import SwiftUI
import TappableMapView

struct ContentView: View {
    @State private var tappedName: String?

    var body: some View {
        VStack {
            TappableMapView(
                polygons: myPolygons,
                configuration: MapConfiguration(mapType: .standard),
                onPolygonTapped: { polygon in
                    tappedName = polygon.title
                }
            )
            .frame(height: 300)

            if let name = tappedName {
                Text("Tapped: \(name)")
            }
        }
    }
}
```

### Creating Polygons from GeoJSON

```swift
import TappableMapView
import MapKit

// From a GeoJSON geometry dictionary
let geometry: [String: Any] = [
    "type": "Polygon",
    "coordinates": [[[-104.05, 43.0], [-104.05, 45.0], [-96.0, 45.0], [-96.0, 43.0], [-104.05, 43.0]]]
]

let overlays = GeoJSONParser.overlays(from: geometry)
let polygon = TappablePolygon(
    id: 1,
    overlays: overlays,
    fillColor: UIColor.systemBlue.withAlphaComponent(0.3),
    strokeColor: .systemBlue,
    title: "My Region"
)
```

### Parsing a GeoJSON FeatureCollection

```swift
let data: Data = ... // GeoJSON FeatureCollection with features having properties.id and properties.name
let parsed = GeoJSONParser.overlays(fromFeatureCollection: data)

let polygons = parsed.map { item in
    TappablePolygon(
        id: item.id,
        overlays: item.overlays,
        title: item.name
    )
}
```

### Configuration

```swift
let config = MapConfiguration(
    region: MKCoordinateRegion(...),  // nil to auto-fit to overlays
    mapType: .hybrid,
    isScrollEnabled: true,
    isZoomEnabled: true,
    isRotateEnabled: false,
    showsUserLocation: false,
    pointOfInterestFilter: .excludingAll
)
```

When `region` is `nil`, the map automatically zooms to fit all polygon overlays with padding.

## API Reference

### TappableMapView

| Parameter | Type | Description |
|-----------|------|-------------|
| `polygons` | `[TappablePolygon]` | Polygon overlays to render and make tappable |
| `annotations` | `[TappableAnnotation]` | Optional point annotations |
| `configuration` | `MapConfiguration` | Map display settings |
| `onPolygonTapped` | `((TappablePolygon) -> Void)?` | Callback when a polygon is tapped |

### TappablePolygon

| Property | Type | Description |
|----------|------|-------------|
| `id` | `AnyHashable` | Unique identifier |
| `overlays` | `[MKOverlay]` | MapKit polygon overlays |
| `fillColor` | `UIColor` | Interior fill color |
| `strokeColor` | `UIColor` | Border stroke color |
| `lineWidth` | `CGFloat` | Border width in points |
| `title` | `String?` | Display title |

### GeoJSONParser

| Method | Description |
|--------|-------------|
| `overlays(from:)` | Parse a GeoJSON Geometry dict → `[MKOverlay]` |
| `overlays(fromFeatureCollection:)` | Parse FeatureCollection data → `[(id, name, overlays)]` |

## Requirements

- iOS 15+
- Swift 5.9+

## License

MIT
