import Foundation
import MapKit

/// Parses GeoJSON geometry objects into MapKit overlays.
public enum GeoJSONParser {

    // MARK: - Public API

    /// Parse a GeoJSON Geometry dictionary into MKOverlay objects.
    ///
    /// Supports `Polygon` and `MultiPolygon` geometry types.
    ///
    /// - Parameter geometry: A dictionary with `"type"` and `"coordinates"` keys.
    /// - Returns: An array of `MKPolygon` overlays. Returns empty if the geometry type is unsupported.
    public static func overlays(from geometry: [String: Any]) -> [MKOverlay] {
        guard let type = geometry["type"] as? String,
              let coordinates = geometry["coordinates"] else {
            return []
        }

        switch type {
        case "Polygon":
            guard let rings = coordinates as? [[[Double]]] else { return [] }
            return [polygonFromRings(rings)]

        case "MultiPolygon":
            guard let polygons = coordinates as? [[[[Double]]]] else { return [] }
            return polygons.map { polygonFromRings($0) }

        default:
            return []
        }
    }

    /// Parse raw GeoJSON FeatureCollection data into identified overlay groups.
    ///
    /// Each feature must have `properties.id` (Int) and `properties.name` (String).
    ///
    /// - Parameter data: Raw JSON data of a GeoJSON FeatureCollection.
    /// - Returns: Array of tuples with id, name, and MKOverlay objects.
    public static func overlays(fromFeatureCollection data: Data) -> [(id: Int, name: String, overlays: [MKOverlay])] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = json["features"] as? [[String: Any]] else {
            return []
        }

        return features.compactMap { feature in
            guard let properties = feature["properties"] as? [String: Any],
                  let id = properties["id"] as? Int,
                  let name = properties["name"] as? String,
                  let geometry = feature["geometry"] as? [String: Any] else {
                return nil
            }
            let overlays = Self.overlays(from: geometry)
            guard !overlays.isEmpty else { return nil }
            return (id: id, name: name, overlays: overlays)
        }
    }

    // MARK: - Private

    private static func polygonFromRings(_ rings: [[[Double]]]) -> MKPolygon {
        let exterior = rings[0].map {
            CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0])
        }

        if rings.count > 1 {
            let interiors = rings[1...].map { ring -> MKPolygon in
                let coords = ring.map {
                    CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0])
                }
                return MKPolygon(coordinates: coords, count: coords.count)
            }
            return MKPolygon(
                coordinates: exterior,
                count: exterior.count,
                interiorPolygons: interiors
            )
        }

        return MKPolygon(coordinates: exterior, count: exterior.count)
    }
}
