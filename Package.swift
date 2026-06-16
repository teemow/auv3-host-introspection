// swift-tools-version: 6.0
import PackageDescription

// auv3-host-introspection: a reusable snapshot of everything an AUv3 app
// extension can observe about its host and environment — the AUv3 host blocks
// (transport, musical context, render timestamp), the AUAudioUnit surface
// (identity, capabilities, MIDI-CI negotiation), and the system "backdoors"
// reachable from the appex sandbox (AVAudioSession, CoreMIDI, ProcessInfo).
//
// Apple platforms only (it reads AVFoundation / AudioToolbox / CoreMIDI).
let package = Package(
    name: "auv3-host-introspection",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "AUv3HostIntrospection", targets: ["AUv3HostIntrospection"]),
    ],
    targets: [
        .target(name: "AUv3HostIntrospection"),
        .testTarget(
            name: "AUv3HostIntrospectionTests",
            dependencies: ["AUv3HostIntrospection"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
