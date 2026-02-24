// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TappableMapView",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "TappableMapView", targets: ["TappableMapView"]),
    ],
    targets: [
        .target(name: "TappableMapView"),
    ]
)
