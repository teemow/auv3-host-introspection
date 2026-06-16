import XCTest
@testable import AUv3HostIntrospection

final class HostDiagnosticsTests: XCTestCase {
    /// Decoder that mirrors the library's `.iso8601` date encoding so the wire
    /// frame round-trips. The wire format carries `capturedAt` as an ISO8601
    /// string (whole-second precision).
    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// The whole envelope round-trips through JSON unchanged — it is the wire
    /// contract for the diagnostics stream and the os_log dump, so encode/decode
    /// must be lossless. `capturedAt` is pinned to a whole second because the
    /// ISO8601 wire format does not carry sub-second precision.
    func testEnvelopeRoundTrips() throws {
        var snapshot = HostDiagnostics(source: "unit-test")
        snapshot.capturedAt = Date(timeIntervalSince1970: 1_700_000_000)
        snapshot.transport.available = true
        snapshot.transport.moving = true
        snapshot.transport.samplePosition = 44_100
        snapshot.musicalContext.available = true
        snapshot.musicalContext.tempo = 128
        snapshot.audioUnit.available = true
        snapshot.audioUnit.componentType = "aumi"
        snapshot.audioUnit.parameterTree.count = 3
        snapshot.coreMIDI.sources = [.init(name: "Probe", uniqueID: 7)]
        snapshot.environment.thermalState = "nominal"

        let data = try XCTUnwrap(snapshot.jsonData())
        let decoded = try decoder().decode(HostDiagnostics.self, from: data)

        XCTAssertEqual(decoded, snapshot)
    }

    /// `prettyJSON` is stable and human-readable (sorted keys, no escaped slashes)
    /// — it backs the on-device "copy the whole snapshot" affordance.
    func testPrettyJSONIsSortedAndDecodable() throws {
        let json = HostDiagnostics(source: "pretty").prettyJSON()
        XCTAssertTrue(json.contains("\"source\" : \"pretty\""))
        XCTAssertFalse(json.contains("\\/"), "slashes should not be escaped")
        let decoded = try decoder().decode(HostDiagnostics.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.source, "pretty")
    }

    /// The environment backdoor is a pure ProcessInfo read, safe to call anywhere
    /// — it must return a populated snapshot (a sanity check that the collector
    /// links and runs).
    func testEnvironmentCollectorReads() {
        let env = HostDiagnosticsCollector.environment()
        XCTAssertGreaterThan(env.processorCount, 0)
        XCTAssertGreaterThan(env.physicalMemory, 0)
        XCTAssertFalse(env.thermalState.isEmpty)
    }

    /// The log subsystem is configurable so a host app can pin a stable string.
    func testLogSubsystemIsConfigurable() {
        let original = HostDiagnostics.logSubsystem
        defer { HostDiagnostics.logSubsystem = original }
        HostDiagnostics.logSubsystem = "com.example.test"
        XCTAssertEqual(HostDiagnostics.logSubsystem, "com.example.test")
    }
}
